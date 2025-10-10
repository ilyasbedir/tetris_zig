const std = @import("std");
const rl = @import("raylib");
const tetro = @import("tetrominoes.zig");

const ScreenWidth: i32 = 920;
const ScreenHeight: i32 = 880;

const BackgroundColor = rl.Color{ .r = 12, .g = 18, .b = 34, .a = 255 };
const BackdropGlowA = rl.Color{ .r = 96, .g = 58, .b = 128, .a = 180 };
const BackdropGlowB = rl.Color{ .r = 24, .g = 129, .b = 162, .a = 180 };
const BoardShadowColor = rl.Color{ .r = 20, .g = 30, .b = 52, .a = 180 };
const BoardFillColor = rl.Color{ .r = 26, .g = 35, .b = 59, .a = 230 };
const BoardOutlineColor = rl.Color{ .r = 117, .g = 203, .b = 255, .a = 200 };
const GridLineColor = rl.Color{ .r = 89, .g = 120, .b = 150, .a = 90 };
const TileShadowColor = rl.Color{ .r = 0, .g = 5, .b = 20, .a = 120 };
const TileOutlineColor = rl.Color{ .r = 210, .g = 240, .b = 255, .a = 180 };
const PanelFillColor = rl.Color{ .r = 28, .g = 41, .b = 68, .a = 240 };
const PanelOutlineColor = rl.Color{ .r = 117, .g = 203, .b = 255, .a = 140 };
const PanelGlowColor = rl.Color{ .r = 40, .g = 120, .b = 160, .a = 120 };
const TextColor = rl.Color{ .r = 225, .g = 236, .b = 255, .a = 255 };
const AccentLineColor = rl.Color{ .r = 120, .g = 198, .b = 255, .a = 140 };
const OverlayShade = rl.Color{ .r = 6, .g = 12, .b = 22, .a = 210 };
const OverlayTextColor = rl.Color{ .r = 233, .g = 244, .b = 255, .a = 255 };

const Game = struct {
    const Self = @This();

    fn clampComponent(value: i32) u8 {
        const clamped = std.math.clamp(value, @as(i32, 0), @as(i32, 255));
        return @as(u8, @intCast(clamped));
    }

    fn adjustColor(color: rl.Color, delta: i32) rl.Color {
        return rl.Color{
            .r = clampComponent(@as(i32, @intCast(color.r)) + delta),
            .g = clampComponent(@as(i32, @intCast(color.g)) + delta),
            .b = clampComponent(@as(i32, @intCast(color.b)) + delta),
            .a = color.a,
        };
    }

    fn withAlpha(color: rl.Color, alpha: u8) rl.Color {
        return rl.Color{ .r = color.r, .g = color.g, .b = color.b, .a = alpha };
    }

    fn drawGlow(center: rl.Vector2, radius: f32, color: rl.Color) void {
        const steps: usize = 6;
        var i: usize = 0;
        while (i < steps) : (i += 1) {
            const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps));
            const current_radius = radius * (1.0 - t * 0.2);
            const base_alpha = @as(f32, @floatFromInt(color.a));
            const alpha_value = std.math.clamp(base_alpha * (1.0 - t), @as(f32, 0.0), @as(f32, 255.0));
            rl.drawCircleV(center, current_radius, withAlpha(color, @as(u8, @intFromFloat(alpha_value))));
        }
    }

    const boardStartCoordinateX: f32 = 80.0;
    const boardStartCoordinateY: f32 = 40.0;
    const boardWidth: f32 = 400.0;
    const boardHeight: f32 = 800.0;
    const boardRows: usize = 20;
    const boardColumns: usize = 10;
    const previewCount: usize = 4;
    const minFallSpeed: f32 = 0.05;
    const autoRepeatDelay: f32 = 0.16;
    const autoRepeatRate: f32 = 0.05;
    const tileWidth: f32 = boardWidth / @as(f32, @floatFromInt(boardColumns));
    const tileHeight: f32 = boardHeight / @as(f32, @floatFromInt(boardRows));
    const shapeCount = std.meta.fields(tetro.Tetrominoes.ShapeType).len;

    comptime {
        if (tileWidth != tileHeight) {
            @compileError("Tile width and height must match");
        }
    }

    const ActivePiece = struct {
        shape: tetro.Tetrominoes.ShapeType,
        rotation: u8,
        x: i32,
        y: i32,
    };

    const MoveState = struct {
        direction: i32 = 0,
        timer: f32 = 0.0,
    };

    const PieceGenerator = struct {
        rng: std.Random.DefaultPrng,
        bag: [shapeCount]tetro.Tetrominoes.ShapeType,
        index: usize,

        fn init(seed: u64) PieceGenerator {
            var generator = PieceGenerator{
                .rng = std.Random.DefaultPrng.init(seed),
                .bag = undefined,
                .index = 0,
            };
            generator.refillBag();
            return generator;
        }

        fn refillBag(self: *PieceGenerator) void {
            const shapes = std.enums.values(tetro.Tetrominoes.ShapeType);
            for (shapes, 0..) |shape, idx| {
                self.bag[idx] = shape;
            }
            self.shuffleBag();
            self.index = 0;
        }

        fn shuffleBag(self: *PieceGenerator) void {
            if (self.bag.len <= 1) return;
            var i: usize = self.bag.len - 1;
            while (true) {
                const j = self.rng.random().uintLessThan(usize, i + 1);
                const tmp = self.bag[i];
                self.bag[i] = self.bag[j];
                self.bag[j] = tmp;
                if (i == 0) break;
                i -= 1;
            }
        }

        fn next(self: *PieceGenerator) tetro.Tetrominoes.ShapeType {
            if (self.index >= self.bag.len) {
                self.refillBag();
            }
            const shape = self.bag[self.index];
            self.index += 1;
            return shape;
        }
    };

    board: [boardRows][boardColumns]?tetro.Tetrominoes.ShapeType,
    current: ?ActivePiece = null,
    nextQueue: [previewCount]tetro.Tetrominoes.ShapeType,
    generator: PieceGenerator,
    score: u32 = 0,
    level: u8 = 0,
    linesClearedTotal: u32 = 0,
    linesSinceLevelIncrease: u32 = 0,
    gameOver: bool = false,
    gamePaused: bool = false,
    fallSpeed: f32 = 1.0,
    dropAccumulator: f32 = 0.0,
    moveState: MoveState = .{},

    pub fn init(seed: u64) Self {
        var generator = PieceGenerator.init(seed);
        var queue: [previewCount]tetro.Tetrominoes.ShapeType = undefined;
        for (queue[0..]) |*slot| {
            slot.* = generator.next();
        }

        var game = Self{
            .board = [_][boardColumns]?tetro.Tetrominoes.ShapeType{[_]?tetro.Tetrominoes.ShapeType{null} ** boardColumns} ** boardRows,
            .current = null,
            .nextQueue = queue,
            .generator = generator,
            .score = 0,
            .level = 0,
            .linesClearedTotal = 0,
            .linesSinceLevelIncrease = 0,
            .gameOver = false,
            .gamePaused = false,
            .fallSpeed = 1.0,
            .dropAccumulator = 0.0,
            .moveState = .{},
        };
        game.adjustFallSpeed();
        return game;
    }

    pub fn reset(self: *Self) void {
        for (self.board[0..]) |*row| {
            row.* = [_]?tetro.Tetrominoes.ShapeType{null} ** boardColumns;
        }
        self.generator.refillBag();
        for (self.nextQueue[0..]) |*slot| {
            slot.* = self.generator.next();
        }
        self.current = null;
        self.score = 0;
        self.level = 0;
        self.linesClearedTotal = 0;
        self.linesSinceLevelIncrease = 0;
        self.gameOver = false;
        self.gamePaused = false;
        self.fallSpeed = 1.0;
        self.dropAccumulator = 0.0;
        self.moveState = .{};
        self.adjustFallSpeed();
    }

    fn takeNextShape(self: *Self) tetro.Tetrominoes.ShapeType {
        const shape = self.nextQueue[0];
        var idx: usize = 0;
        while (idx + 1 < previewCount) : (idx += 1) {
            self.nextQueue[idx] = self.nextQueue[idx + 1];
        }
        self.nextQueue[previewCount - 1] = self.generator.next();
        return shape;
    }

    fn spawnPosition(shape: tetro.Tetrominoes.ShapeType) struct { x: i32, y: i32 } {
        const center = @as(i32, @intCast(boardColumns / 2));
        return switch (shape) {
            .O => .{ .x = center - 1, .y = -1 },
            .I => .{ .x = center - 2, .y = -2 },
            else => .{ .x = center - 2, .y = -1 },
        };
    }

    pub fn spawnTetrominoe(self: *Self) void {
        if (self.gameOver or self.current != null) return;

        const shape = self.takeNextShape();
        const spawn = spawnPosition(shape);
        const piece = ActivePiece{
            .shape = shape,
            .rotation = 0,
            .x = spawn.x,
            .y = spawn.y,
        };

        if (!self.canPieceFit(piece)) {
            self.gameOver = true;
            self.current = null;
            return;
        }

        self.current = piece;
        self.dropAccumulator = 0.0;
        self.moveState = .{};
    }

    fn forEachPieceCell(
        self: *const Self,
        piece: ActivePiece,
        ctx: anytype,
        comptime func: fn (i32, i32, @TypeOf(ctx)) bool,
    ) bool {
        _ = self;
        const tile = tetro.Tetrominoes.getShape(piece.shape, piece.rotation);
        for (0..4) |row| {
            for (0..4) |col| {
                if (!tile[row][col]) continue;
                const x = piece.x + @as(i32, @intCast(col));
                const y = piece.y + @as(i32, @intCast(row));
                if (!func(x, y, ctx)) return false;
            }
        }
        return true;
    }

    fn canPieceFit(self: *const Self, piece: ActivePiece) bool {
        const maxCols = @as(i32, @intCast(boardColumns));
        const maxRows = @as(i32, @intCast(boardRows));
        const Context = struct {
            maxCols: i32,
            maxRows: i32,
            game: *const Self,

            fn check(x: i32, y: i32, ctx: @This()) bool {
                if (x < 0 or x >= ctx.maxCols) return false;
                if (y >= ctx.maxRows) return false;
                if (y < 0) return true;
                const row = @as(usize, @intCast(y));
                const col = @as(usize, @intCast(x));
                return ctx.game.board[row][col] == null;
            }
        };
        const context = Context{ .maxCols = maxCols, .maxRows = maxRows, .game = self };
        return self.forEachPieceCell(piece, context, Context.check);
    }

    fn tryMove(self: *Self, dx: i32) void {
        if (self.current) |*piece| {
            var candidate = piece.*;
            candidate.x += dx;
            if (self.canPieceFit(candidate)) {
                piece.* = candidate;
            }
        }
    }

    fn kicks(
        a0: [2]i32,
        a1: [2]i32,
        a2: [2]i32,
        a3: [2]i32,
        a4: [2]i32,
    ) [5][2]i32 {
        return .{ a0, a1, a2, a3, a4 };
    }

    const zeroKick = kicks(.{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 });

    const JLSTZ_KICK_TABLE = [4][4][5][2]i32{
        .{
            zeroKick,
            kicks(.{ 0, 0 }, .{ -1, 0 }, .{ -1, 1 }, .{ 0, -2 }, .{ -1, -2 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, -2 }, .{ 1, -2 }),
        },
        .{
            kicks(.{ 0, 0 }, .{ 1, 0 }, .{ 1, -1 }, .{ 0, 2 }, .{ 1, 2 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ 1, 0 }, .{ 1, -1 }, .{ 0, 2 }, .{ 1, 2 }),
            zeroKick,
        },
        .{
            zeroKick,
            kicks(.{ 0, 0 }, .{ -1, 0 }, .{ -1, 1 }, .{ 0, -2 }, .{ -1, -2 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, -2 }, .{ 1, -2 }),
        },
        .{
            kicks(.{ 0, 0 }, .{ -1, 0 }, .{ -1, -1 }, .{ 0, 2 }, .{ -1, 2 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ -1, 0 }, .{ -1, -1 }, .{ 0, 2 }, .{ -1, 2 }),
            zeroKick,
        },
    };

    const I_KICK_TABLE = [4][4][5][2]i32{
        .{
            zeroKick,
            kicks(.{ 0, 0 }, .{ -2, 0 }, .{ 1, 0 }, .{ -2, -1 }, .{ 1, 2 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ -1, 0 }, .{ 2, 0 }, .{ -1, 2 }, .{ 2, -1 }),
        },
        .{
            kicks(.{ 0, 0 }, .{ 2, 0 }, .{ -1, 0 }, .{ 2, 1 }, .{ -1, -2 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ -1, 0 }, .{ 2, 0 }, .{ -1, 2 }, .{ 2, -1 }),
            zeroKick,
        },
        .{
            zeroKick,
            kicks(.{ 0, 0 }, .{ 1, 0 }, .{ -2, 0 }, .{ 1, -2 }, .{ -2, 1 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ 2, 0 }, .{ -1, 0 }, .{ 2, 1 }, .{ -1, -2 }),
        },
        .{
            kicks(.{ 0, 0 }, .{ 1, 0 }, .{ -2, 0 }, .{ 1, -2 }, .{ -2, 1 }),
            zeroKick,
            kicks(.{ 0, 0 }, .{ -2, 0 }, .{ 1, 0 }, .{ -2, -1 }, .{ 1, 2 }),
            zeroKick,
        },
    };

    const O_KICKS = [1][2]i32{.{ 0, 0 }};

    fn getSrsOffsets(shape: tetro.Tetrominoes.ShapeType, from: u8, to: u8) []const [2]i32 {
        const from_idx = @as(usize, @intCast(from % 4));
        const to_idx = @as(usize, @intCast(to % 4));
        return switch (shape) {
            .I => I_KICK_TABLE[from_idx][to_idx][0..],
            .O => O_KICKS[0..],
            else => JLSTZ_KICK_TABLE[from_idx][to_idx][0..],
        };
    }

    fn tryRotate(self: *Self, direction: i32) void {
        if (self.current) |*piece| {
            const from = piece.rotation;
            var to_i32 = @as(i32, @intCast(from));
            to_i32 += if (direction > 0) 1 else -1;
            while (to_i32 < 0) to_i32 += 4;
            to_i32 = @mod(to_i32, @as(i32, 4));
            const to = @as(u8, @intCast(to_i32));

            const offsets = getSrsOffsets(piece.shape, from, to);
            var candidate = piece.*;
            candidate.rotation = to;

            for (offsets) |offset| {
                candidate.x = piece.x + offset[0];
                candidate.y = piece.y + offset[1];
                if (self.canPieceFit(candidate)) {
                    piece.* = candidate;
                    return;
                }
            }
        }
    }

    fn updateHorizontalMovement(self: *Self, direction: i32, triggered: bool, dt: f32) void {
        if (self.current == null) {
            self.moveState = .{};
            return;
        }

        if (direction == 0) {
            self.moveState = .{};
            return;
        }

        if (self.moveState.direction != direction or triggered) {
            self.moveState.direction = direction;
            self.moveState.timer = autoRepeatDelay;
            self.tryMove(direction);
            return;
        }

        if (self.moveState.timer > 0) {
            self.moveState.timer -= dt;
        }

        while (self.moveState.timer <= 0) {
            self.tryMove(direction);
            self.moveState.timer += autoRepeatRate;
        }
    }

    fn hardDrop(self: *Self) void {
        if (self.current) |*piece| {
            var distance: usize = 0;
            while (true) {
                var candidate = piece.*;
                candidate.y += 1;
                if (!self.canPieceFit(candidate)) break;
                piece.* = candidate;
                distance += 1;
            }

            self.lockCurrentPiece();
            const cleared = self.clearCompletedLines();
            self.applyLineClear(cleared);
            self.score += @as(u32, @intCast(distance)) * 2;
        }
    }

    fn lockCurrentPiece(self: *Self) void {
        if (self.current) |piece| {
            const Context = struct {
                game: *Self,
                shape: tetro.Tetrominoes.ShapeType,

                fn place(x: i32, y: i32, ctx: @This()) bool {
                    if (y < 0) {
                        ctx.game.gameOver = true;
                        return true;
                    }
                    const row = @as(usize, @intCast(y));
                    const col = @as(usize, @intCast(x));
                    ctx.game.board[row][col] = ctx.shape;
                    return true;
                }
            };
            const ctx = Context{ .game = self, .shape = piece.shape };
            _ = self.forEachPieceCell(piece, ctx, Context.place);
            self.current = null;
            self.dropAccumulator = 0.0;
            self.moveState = .{};
        }
    }

    fn handleInput(self: *Self, dt: f32) void {
        if (self.current == null) return;

        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            self.hardDrop();
            return;
        }

        const rotateCWPressed = rl.isKeyPressed(rl.KeyboardKey.up) or rl.isKeyPressed(rl.KeyboardKey.w) or rl.isKeyPressed(rl.KeyboardKey.x);
        const rotateCCWPressed = rl.isKeyPressed(rl.KeyboardKey.z) or rl.isKeyPressed(rl.KeyboardKey.q);

        if (rotateCWPressed) {
            self.tryRotate(1);
        }

        if (rotateCCWPressed) {
            self.tryRotate(-1);
        }

        const leftDown = rl.isKeyDown(rl.KeyboardKey.left) or rl.isKeyDown(rl.KeyboardKey.a);
        const rightDown = rl.isKeyDown(rl.KeyboardKey.right) or rl.isKeyDown(rl.KeyboardKey.d);
        const leftPressed = rl.isKeyPressed(rl.KeyboardKey.left) or rl.isKeyPressed(rl.KeyboardKey.a);
        const rightPressed = rl.isKeyPressed(rl.KeyboardKey.right) or rl.isKeyPressed(rl.KeyboardKey.d);

        const direction: i32 = if (leftDown and !rightDown) -1 else if (rightDown and !leftDown) 1 else 0;
        const triggered = switch (direction) {
            -1 => leftPressed,
            1 => rightPressed,
            else => false,
        };
        self.updateHorizontalMovement(direction, triggered, dt);

        const softDropHeld = rl.isKeyDown(rl.KeyboardKey.down) or rl.isKeyDown(rl.KeyboardKey.s);
        if (softDropHeld) {
            if (self.movePieceDown()) {
                self.dropAccumulator = 0.0;
            }
        }
    }

    fn scoreForLines(self: *Self, lines: u32) u32 {
        const base: u32 = switch (lines) {
            0 => 0,
            1 => 100,
            2 => 300,
            3 => 500,
            else => 800,
        };
        return base * (@as(u32, self.level) + 1);
    }

    fn adjustFallSpeed(self: *Self) void {
        const computed = 1.0 - (@as(f32, @floatFromInt(self.level)) * 0.1);
        self.fallSpeed = if (computed < minFallSpeed) minFallSpeed else computed;
    }

    fn applyLineClear(self: *Self, cleared: u32) void {
        if (cleared == 0) return;

        self.score += self.scoreForLines(cleared);
        self.linesClearedTotal += cleared;
        self.linesSinceLevelIncrease += cleared;

        while (self.linesSinceLevelIncrease >= 10) {
            self.linesSinceLevelIncrease -= 10;
            if (self.level < std.math.maxInt(u8)) {
                self.level += 1;
                self.adjustFallSpeed();
            }
        }
    }

    fn clearCompletedLines(self: *Self) u32 {
        var cleared: u32 = 0;
        if (boardRows == 0) return cleared;

        var row: i32 = @as(i32, @intCast(boardRows)) - 1;
        while (row >= 0) {
            const rowIndex: usize = @as(usize, @intCast(row));
            var isFull = true;
            for (0..boardColumns) |column| {
                if (self.board[rowIndex][column] == null) {
                    isFull = false;
                    break;
                }
            }

            if (isFull) {
                var y = row;
                while (y > 0) : (y -= 1) {
                    self.board[@as(usize, @intCast(y))] =
                        self.board[@as(usize, @intCast(y - 1))];
                }
                self.board[0] = [_]?tetro.Tetrominoes.ShapeType{null} ** boardColumns;
                cleared += 1;
                continue;
            }

            row -= 1;
        }

        return cleared;
    }

    pub fn movePieceDown(self: *Self) bool {
        if (self.current) |*piece| {
            var candidate = piece.*;
            candidate.y += 1;
            if (self.canPieceFit(candidate)) {
                piece.* = candidate;
                return true;
            }

            self.lockCurrentPiece();
            const cleared = self.clearCompletedLines();
            self.applyLineClear(cleared);
        }

        return false;
    }

    pub fn update(self: *Self, dt: f32) void {
        if (rl.isKeyPressed(rl.KeyboardKey.r) and self.gameOver) {
            self.reset();
            return;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.p) and !self.gameOver) {
            self.gamePaused = !self.gamePaused;
        }

        if (self.gameOver or self.gamePaused) return;

        self.spawnTetrominoe();

        if (self.current == null) return;

        self.handleInput(dt);

        if (self.current == null) return;

        const speed = if (self.fallSpeed <= 0) minFallSpeed else self.fallSpeed;
        self.dropAccumulator += dt;

        while (self.dropAccumulator >= speed) {
            self.dropAccumulator -= speed;
            if (!self.movePieceDown()) break;
        }
    }

    fn drawBackdrop(self: *const Self) void {
        _ = self;
        const board_center_x = boardStartCoordinateX + boardWidth / 2.0;
        const top_center = rl.Vector2{
            .x = board_center_x - 120.0,
            .y = boardStartCoordinateY - 140.0,
        };
        const bottom_center = rl.Vector2{
            .x = board_center_x + 110.0,
            .y = boardStartCoordinateY + boardHeight + 160.0,
        };

        drawGlow(top_center, 360.0, BackdropGlowA);
        drawGlow(bottom_center, 300.0, BackdropGlowB);

        const side_glow = rl.Rectangle{
            .x = boardStartCoordinateX + boardWidth + 20.0,
            .y = boardStartCoordinateY - 30.0,
            .width = 220.0,
            .height = 560.0,
        };
        rl.drawRectangleRounded(side_glow, 0.18, 8, withAlpha(PanelGlowColor, 80));

        rl.drawRectangle(
            @as(c_int, @intFromFloat(boardStartCoordinateX - 36.0)),
            @as(c_int, @intFromFloat(boardStartCoordinateY + boardHeight + 18.0)),
            @as(c_int, @intFromFloat(boardWidth + 180.0)),
            2,
            AccentLineColor,
        );
    }

    fn drawBoard(self: *const Self) void {
        const boardRect = rl.Rectangle{
            .x = boardStartCoordinateX,
            .y = boardStartCoordinateY,
            .width = boardWidth,
            .height = boardHeight,
        };

        const shadowRect = rl.Rectangle{
            .x = boardRect.x - 12.0,
            .y = boardRect.y - 12.0,
            .width = boardRect.width + 24.0,
            .height = boardRect.height + 24.0,
        };
        rl.drawRectangleRounded(shadowRect, 0.08, 6, withAlpha(BoardShadowColor, 160));

        rl.drawRectangleRounded(boardRect, 0.05, 6, BoardFillColor);
        rl.drawRectangleRoundedLines(boardRect, 0.05, 6, BoardOutlineColor);

        const innerRect = rl.Rectangle{
            .x = boardRect.x + 8.0,
            .y = boardRect.y + 8.0,
            .width = boardRect.width - 16.0,
            .height = boardRect.height - 16.0,
        };
        rl.drawRectangleRoundedLines(innerRect, 0.03, 5, withAlpha(BoardOutlineColor, 120));

        self.drawGrid();
        self.drawLockedTiles();
        self.drawActivePiece();

        if (self.gameOver or self.gamePaused) {
            self.drawStateOverlay();
        }
    }

    fn drawGrid(self: *const Self) void {
        _ = self;
        for (0..boardColumns + 1) |i| {
            const lineX = boardStartCoordinateX + (tileWidth * @as(f32, @floatFromInt(i)));
            rl.drawLineEx(
                rl.Vector2{ .x = lineX, .y = boardStartCoordinateY },
                rl.Vector2{ .x = lineX, .y = boardStartCoordinateY + boardHeight },
                1.0,
                GridLineColor,
            );
        }

        for (0..boardRows + 1) |j| {
            const lineY = boardStartCoordinateY + (tileHeight * @as(f32, @floatFromInt(j)));
            rl.drawLineEx(
                rl.Vector2{ .x = boardStartCoordinateX, .y = lineY },
                rl.Vector2{ .x = boardStartCoordinateX + boardWidth, .y = lineY },
                1.0,
                GridLineColor,
            );
        }
    }

    fn drawStyledCell(rect: rl.Rectangle, color: rl.Color) void {
        const shadowRect = rl.Rectangle{
            .x = rect.x + 3.0,
            .y = rect.y + 3.0,
            .width = rect.width,
            .height = rect.height,
        };
        rl.drawRectangleRounded(shadowRect, 0.45, 8, withAlpha(TileShadowColor, 200));

        const baseColor = adjustColor(color, -35);
        rl.drawRectangleRounded(rect, 0.4, 8, baseColor);

        const innerRect = rl.Rectangle{
            .x = rect.x + 2.5,
            .y = rect.y + 2.5,
            .width = rect.width - 5.0,
            .height = rect.height - 5.0,
        };
        rl.drawRectangleRounded(innerRect, 0.45, 8, adjustColor(color, 10));

        const glintRect = rl.Rectangle{
            .x = rect.x + 4.0,
            .y = rect.y + 4.0,
            .width = rect.width - 8.0,
            .height = (rect.height - 8.0) * 0.45,
        };
        rl.drawRectangleRounded(glintRect, 0.5, 8, withAlpha(adjustColor(color, 40), 150));

        rl.drawRectangleRoundedLines(rect, 0.4, 8, TileOutlineColor);
    }

    fn drawTile(self: *const Self, row: i32, column: i32, color: rl.Color) void {
        _ = self;
        const padding: f32 = 4.0;
        const x = boardStartCoordinateX + (tileWidth * @as(f32, @floatFromInt(column))) + padding;
        const y = boardStartCoordinateY + (tileHeight * @as(f32, @floatFromInt(row))) + padding;
        const rect = rl.Rectangle{
            .x = x,
            .y = y,
            .width = tileWidth - (padding * 2.0),
            .height = tileHeight - (padding * 2.0),
        };
        drawStyledCell(rect, color);
    }

    fn drawLockedTiles(self: *const Self) void {
        for (0..boardRows) |row| {
            for (0..boardColumns) |column| {
                if (self.board[row][column]) |shape| {
                    self.drawTile(
                        @as(i32, @intCast(row)),
                        @as(i32, @intCast(column)),
                        tetro.Tetrominoes.colorForShape(shape),
                    );
                }
            }
        }
    }

    fn drawActivePiece(self: *const Self) void {
        if (self.current) |piece| {
            const tile = tetro.Tetrominoes.getShape(piece.shape, piece.rotation);
            const color = tetro.Tetrominoes.colorForShape(piece.shape);
            for (0..4) |row| {
                for (0..4) |column| {
                    if (!tile[row][column]) continue;
                    const boardRow = piece.y + @as(i32, @intCast(row));
                    const boardColumn = piece.x + @as(i32, @intCast(column));
                    if (boardRow < 0 or boardColumn < 0) continue;
                    if (boardColumn >= @as(i32, @intCast(boardColumns))) continue;
                    if (boardRow >= @as(i32, @intCast(boardRows))) continue;
                    self.drawTile(boardRow, boardColumn, color);
                }
            }
        }
    }

    fn drawStateOverlay(self: *const Self) void {
        const boardRect = rl.Rectangle{
            .x = boardStartCoordinateX,
            .y = boardStartCoordinateY,
            .width = boardWidth,
            .height = boardHeight,
        };
        rl.drawRectangleRounded(boardRect, 0.05, 6, OverlayShade);

        var label_buffer: [32]u8 = undefined;
        const messageText = std.fmt.bufPrintZ(
            &label_buffer,
            "{s}",
            .{if (self.gameOver) "GAME OVER" else "PAUSED"},
        ) catch unreachable;
        const messageWidth = rl.measureText(messageText, 48);
        const centerX = boardStartCoordinateX + boardWidth / 2.0;
        const centerY = boardStartCoordinateY + boardHeight / 2.0;

        rl.drawText(
            messageText,
            @as(c_int, @intFromFloat(centerX - (@as(f32, @floatFromInt(messageWidth)) / 2.0))),
            @as(c_int, @intFromFloat(centerY - 40.0)),
            48,
            OverlayTextColor,
        );

        const subMessage = std.fmt.bufPrintZ(
            &label_buffer,
            "{s}",
            .{if (self.gameOver) "Press R to restart" else "Press P to resume"},
        ) catch unreachable;
        const subWidth = rl.measureText(subMessage, 22);
        rl.drawText(
            subMessage,
            @as(c_int, @intFromFloat(centerX - (@as(f32, @floatFromInt(subWidth)) / 2.0))),
            @as(c_int, @intFromFloat(centerY + 10.0)),
            22,
            OverlayTextColor,
        );
    }

    fn drawMiniPiece(self: *const Self, shape: tetro.Tetrominoes.ShapeType, centerX: f32, baseY: f32) void {
        _ = self;
        const tile = tetro.Tetrominoes.getShape(shape, 0);
        const cellSize: f32 = 18.0;
        var minCol: i32 = 4;
        var maxCol: i32 = -1;
        var minRow: i32 = 4;
        var maxRow: i32 = -1;

        for (0..4) |row| {
            for (0..4) |column| {
                if (!tile[row][column]) continue;
                const c = @as(i32, @intCast(column));
                const r = @as(i32, @intCast(row));
                if (c < minCol) minCol = c;
                if (c > maxCol) maxCol = c;
                if (r < minRow) minRow = r;
                if (r > maxRow) maxRow = r;
            }
        }

        if (maxCol < minCol or maxRow < minRow) return;

        const width = @as(f32, @floatFromInt(maxCol - minCol + 1)) * cellSize;
        const originX = centerX - (width / 2.0);
        const originY = baseY;
        const color = tetro.Tetrominoes.colorForShape(shape);

        for (0..4) |row| {
            for (0..4) |column| {
                if (!tile[row][column]) continue;
                const x = originX + @as(f32, @floatFromInt(@as(i32, @intCast(column)) - minCol)) * cellSize;
                const y = originY + @as(f32, @floatFromInt(@as(i32, @intCast(row)) - minRow)) * cellSize;
                const rect = rl.Rectangle{
                    .x = x,
                    .y = y,
                    .width = cellSize - 1.5,
                    .height = cellSize - 1.5,
                };
                drawStyledCell(rect, color);
            }
        }
    }

    fn drawNextQueue(self: *const Self) void {
        const panelX = boardStartCoordinateX + boardWidth + 40.0;
        const panelY = boardStartCoordinateY;
        const panelWidth: f32 = 180.0;
        const panelHeight: f32 = 260.0;
        const panelRect = rl.Rectangle{
            .x = panelX,
            .y = panelY,
            .width = panelWidth,
            .height = panelHeight,
        };
        rl.drawRectangleRounded(panelRect, 0.08, 6, PanelFillColor);
        rl.drawRectangleRoundedLines(panelRect, 0.08, 6, PanelOutlineColor);

        var label_buffer: [16]u8 = undefined;
        const nextLabel = std.fmt.bufPrintZ(&label_buffer, "NEXT", .{}) catch unreachable;
        rl.drawText(nextLabel, @as(c_int, @intFromFloat(panelX + 20.0)), @as(c_int, @intFromFloat(panelY + 16.0)), 26, TextColor);

        var i: usize = 0;
        while (i < previewCount) : (i += 1) {
            const shape = self.nextQueue[i];
            const offsetY = panelY + 56.0 + @as(f32, @floatFromInt(i)) * 48.0;
            self.drawMiniPiece(shape, panelX + panelWidth / 2.0, offsetY);
        }
    }

    fn drawScorePanel(self: *const Self) void {
        const panelX = boardStartCoordinateX + boardWidth + 40.0;
        const panelY = boardStartCoordinateY + 300.0;
        const panelWidth: f32 = 180.0;
        const panelHeight: f32 = 200.0;
        const panelRect = rl.Rectangle{
            .x = panelX,
            .y = panelY,
            .width = panelWidth,
            .height = panelHeight,
        };
        rl.drawRectangleRounded(panelRect, 0.08, 6, PanelFillColor);
        rl.drawRectangleRoundedLines(panelRect, 0.08, 6, PanelOutlineColor);

        var label_buffer: [16]u8 = undefined;
        const statsLabel = std.fmt.bufPrintZ(&label_buffer, "STATS", .{}) catch unreachable;
        rl.drawText(statsLabel, @as(c_int, @intFromFloat(panelX + 20.0)), @as(c_int, @intFromFloat(panelY + 16.0)), 26, TextColor);

        var buffer: [48]u8 = undefined;
        var yOffset: f32 = panelY + 64.0;

        const scoreText = std.fmt.bufPrintZ(&buffer, "Score: {}", .{self.score}) catch unreachable;
        rl.drawText(
            scoreText,
            @as(c_int, @intFromFloat(panelX + 20.0)),
            @as(c_int, @intFromFloat(yOffset)),
            22,
            TextColor,
        );

        yOffset += 36.0;
        const levelText = std.fmt.bufPrintZ(&buffer, "Level: {}", .{@as(u32, self.level)}) catch unreachable;
        rl.drawText(
            levelText,
            @as(c_int, @intFromFloat(panelX + 20.0)),
            @as(c_int, @intFromFloat(yOffset)),
            22,
            TextColor,
        );

        yOffset += 36.0;
        const linesText = std.fmt.bufPrintZ(&buffer, "Lines: {}", .{self.linesClearedTotal}) catch unreachable;
        rl.drawText(
            linesText,
            @as(c_int, @intFromFloat(panelX + 20.0)),
            @as(c_int, @intFromFloat(yOffset)),
            22,
            TextColor,
        );
    }

    fn drawHud(self: *const Self) void {
        self.drawNextQueue();
        self.drawScorePanel();
    }
};

pub fn main() anyerror!void {
    const timestamp = std.time.microTimestamp();
    const seed = @as(u64, @intCast(if (timestamp < 0) -timestamp else timestamp));
    var tetrisGame = Game.init(seed);

    rl.initWindow(ScreenWidth, ScreenHeight, "Tetris by @ilyasbedir");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        const frameTime = rl.getFrameTime();
        tetrisGame.update(frameTime);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(BackgroundColor);

        tetrisGame.drawBackdrop();
        tetrisGame.drawBoard();
        tetrisGame.drawHud();
    }
}
