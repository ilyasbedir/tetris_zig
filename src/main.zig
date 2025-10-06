const std = @import("std");
const rl = @import("raylib");
const tetro = @import("tetrominoes.zig");

const Game = struct {
    const Self = @This();
    // Game properties here
    const boardStartCoordinateX: f32 = 50;
    const boardStartCoordinateY: f32 = 10;
    const boardWidth: f32 = 400;
    const boardHeight: f32 = 800;
    const boardRows: usize = 20;
    const boardColumn: usize = 10;
    const tileWidth = boardWidth / @as(f32, @floatFromInt(boardColumn));
    const tileHeight = boardHeight / @as(f32, @floatFromInt(boardRows));

    comptime {
        if (tileWidth != tileHeight) {
            @compileError("Tile width and tile height are not equal");
        }
    }

    colorBoard: [boardRows][boardColumn]rl.Color = undefined,
    currentPieceType: ?tetro.Tetrominoes.ShapeType = null,
    nextPieceType: ?tetro.Tetrominoes.ShapeType = null,
    currentPieceColor: rl.Color = rl.Color.blank,
    score: u32 = 0,
    level: u8 = 0,
    linesClearedTotal: u32 = 0,
    linesSinceLevelIncrease: u32 = 0,
    gameOver: bool = false,
    gamePaused: bool = false,
    fallSpeed: f32 = 1.0,
    rotation: u8 = 0, // TODO: refactor this to use enum instead plain value
    currentPieceY: i32 = 0,
    currentPieceX: i32 = 0,
    rng: std.Random.DefaultPrng = undefined,
    dropAccumulator: f32 = 0.0,

    pub fn init(seed: u64) Self {
        const prng = std.Random.DefaultPrng.init(seed);
        return .{
            .colorBoard = [_][boardColumn]rl.Color{[_]rl.Color{rl.Color.blank} ** boardColumn} ** boardRows,
            .currentPieceType = null,
            .nextPieceType = null,
            .currentPieceColor = rl.Color.blank,
            .score = 0,
            .level = 0,
            .linesClearedTotal = 0,
            .linesSinceLevelIncrease = 0,
            .gameOver = false,
            .gamePaused = false,
            .fallSpeed = 1.0,
            .rotation = 0,
            .currentPieceY = 0,
            .currentPieceX = 0,
            .rng = prng,
            .dropAccumulator = 0.0,
        };
    }

    fn drawBoardGrid(self: *Self) void {
        _ = self;
        //
        for (0..boardColumn + 1) |i| {
            rl.drawLineEx(
                rl.Vector2{
                    .x = boardStartCoordinateX + (@as(f32, @floatFromInt(i)) * tileWidth),
                    .y = boardStartCoordinateY,
                },
                rl.Vector2{
                    .x = boardStartCoordinateX + (@as(f32, @floatFromInt(i)) * tileWidth),
                    .y = boardStartCoordinateY + boardHeight,
                },
                1.0,
                rl.Color.black,
            );
        }
        for (0..boardRows + 1) |j| {
            rl.drawLineEx(
                rl.Vector2{
                    .x = boardStartCoordinateX,
                    .y = boardStartCoordinateY + (@as(f32, @floatFromInt(j)) * tileHeight),
                },
                rl.Vector2{
                    .x = boardStartCoordinateX + boardWidth,
                    .y = boardStartCoordinateY + (@as(f32, @floatFromInt(j)) * tileHeight),
                },
                1.0,
                rl.Color.black,
            );
        }
    }

    fn getRandomTetrominoeType(self: *Self) tetro.Tetrominoes.ShapeType {
        return self.rng.random().enumValue(tetro.Tetrominoes.ShapeType);
    }

    fn getRandomTetrominoeColor(self: *Self) tetro.Tetrominoes.TetrominoeColor {
        return std.Random.enumValue(self.rng.random(), tetro.Tetrominoes.TetrominoeColor);
    }

    fn getRandomRotation(self: *Self) u8 {
        return self.rng.random().uintLessThan(u8, 4); // Random number between 0 and 3 inclusive
    }

    fn addTetrominoeOnBoard(self: *Self) void {
        if (self.currentPieceType) |pieceType| {
            const tile = tetro.Tetrominoes.getShape(pieceType, self.rotation);
            const maxRows: i32 = @as(i32, @intCast(boardRows));
            const maxCols: i32 = @as(i32, @intCast(boardColumn));

            for (0..4) |row| {
                for (0..4) |column| {
                    if (tile[row][column] == 0) continue;

                    const targetRow = self.currentPieceY + @as(i32, @intCast(row));
                    const targetCol = self.currentPieceX + @as(i32, @intCast(column));

                    if (targetRow < 0 or targetCol < 0) continue;
                    if (targetRow >= maxRows or targetCol >= maxCols) continue;

                    const boardRow: usize = @as(usize, @intCast(targetRow));
                    const boardCol: usize = @as(usize, @intCast(targetCol));
                    self.colorBoard[boardRow][boardCol] = self.currentPieceColor;
                }
            }
        }
    }

    fn canMoveTo(self: *Self, targetX: i32, targetY: i32) bool {
        if (self.currentPieceType) |pieceType| {
            const tile = tetro.Tetrominoes.getShape(pieceType, self.rotation);
            const maxRows: i32 = @as(i32, @intCast(boardRows));
            const maxCols: i32 = @as(i32, @intCast(boardColumn));

            for (0..4) |row| {
                for (0..4) |column| {
                    if (tile[row][column] == 0) continue;

                    const cellX = targetX + @as(i32, @intCast(column));
                    const cellY = targetY + @as(i32, @intCast(row));

                    if (cellX < 0 or cellX >= maxCols) return false;
                    if (cellY >= maxRows) return false;
                    if (cellY < 0) continue;

                    const boardRow: usize = @as(usize, @intCast(cellY));
                    const boardCol: usize = @as(usize, @intCast(cellX));

                    if (self.colorBoard[boardRow][boardCol].a > 0) {
                        return false;
                    }
                }
            }

            return true;
        }

        return false;
    }

    fn drawTetrominoe(self: *Self) void {
        for (0..boardRows) |row| {
            for (0..boardColumn) |column| {
                const pieceValue = self.colorBoard[row][column];
                if (pieceValue.a > 0) {
                    rl.drawRectangleRec(
                        .{
                            .x = boardStartCoordinateX + (tileWidth * @as(f32, @floatFromInt(column))),
                            .y = boardStartCoordinateY + (tileHeight * @as(f32, @floatFromInt(row))),
                            .width = tileWidth,
                            .height = tileHeight,
                        },
                        pieceValue,
                    );
                }
            }
        }
    }

    pub fn spawnTetrominoe(self: *Self) void {
        if (self.gameOver or self.currentPieceType != null) return;

        const nextType = self.nextPieceType orelse self.getRandomTetrominoeType();
        self.currentPieceType = nextType;
        self.nextPieceType = self.getRandomTetrominoeType();
        self.rotation = self.getRandomRotation();
        self.currentPieceColor = tetro.Tetrominoes.TetrominoeColor.toColor(self.getRandomTetrominoeColor());
        const halfColumns: i32 = @as(i32, @intCast(boardColumn / 2));
        const spawnX: i32 = if (halfColumns > 2) halfColumns - 2 else 0;
        self.currentPieceX = spawnX;
        self.currentPieceY = 0;

        if (!self.canMoveTo(self.currentPieceX, self.currentPieceY)) {
            self.gameOver = true;
            self.currentPieceType = null;
            self.currentPieceColor = rl.Color.blank;
            return;
        }

        self.addTetrominoeOnBoard();
        self.dropAccumulator = 0.0;
    }

    fn lockCurrentPiece(self: *Self) void {
        self.currentPieceType = null;
        self.currentPieceColor = rl.Color.blank;
        self.rotation = 0;
        self.currentPieceX = 0;
        self.currentPieceY = 0;
        self.dropAccumulator = 0.0;
    }

    fn clearCurrentPiece(self: *Self) void {
        if (self.currentPieceType) |pieceType| {
            const tile = tetro.Tetrominoes.getShape(pieceType, self.rotation);
            const maxRows: i32 = @as(i32, @intCast(boardRows));
            const maxCols: i32 = @as(i32, @intCast(boardColumn));

            for (0..4) |row| {
                for (0..4) |column| {
                    if (tile[row][column] == 0) continue;

                    const targetRow = self.currentPieceY + @as(i32, @intCast(row));
                    const targetCol = self.currentPieceX + @as(i32, @intCast(column));

                    if (targetRow < 0 or targetCol < 0) continue;
                    if (targetRow >= maxRows or targetCol >= maxCols) continue;

                    const boardRow: usize = @as(usize, @intCast(targetRow));
                    const boardCol: usize = @as(usize, @intCast(targetCol));
                    self.colorBoard[boardRow][boardCol] = rl.Color.blank;
                }
            }
        }
    }

    fn tryMove(self: *Self, dx: i32) void {
        if (self.currentPieceType == null) return;

        const nextX = self.currentPieceX + dx;
        self.clearCurrentPiece();

        if (self.canMoveTo(nextX, self.currentPieceY)) {
            self.currentPieceX = nextX;
        }

        self.addTetrominoeOnBoard();
    }

    fn tryRotate(self: *Self, direction: i32) void {
        if (self.currentPieceType == null) return;

        const originalRotation = self.rotation;
        const originalX = self.currentPieceX;
        const originalY = self.currentPieceY;

        self.clearCurrentPiece();

        var rotated = @as(i32, self.rotation) + direction;
        while (rotated < 0) rotated += 4;
        rotated = @mod(rotated, 4);
        self.rotation = @as(u8, @intCast(rotated));

        const offsets = [_][2]i32{
            .{ 0, 0 },
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
        };

        var applied = false;
        for (offsets) |offset| {
            const testX = originalX + offset[0];
            const testY = originalY + offset[1];

            if (self.canMoveTo(testX, testY)) {
                self.currentPieceX = testX;
                self.currentPieceY = testY;
                applied = true;
                break;
            }
        }

        if (!applied) {
            self.rotation = originalRotation;
            self.currentPieceX = originalX;
            self.currentPieceY = originalY;
        }

        self.addTetrominoeOnBoard();
    }

    fn hardDrop(self: *Self) void {
        if (self.currentPieceType == null) return;

        while (self.movePieceDown()) {}
        self.dropAccumulator = 0.0;
    }

    fn clearCompletedLines(self: *Self) u32 {
        var cleared: u32 = 0;
        if (boardRows == 0) return cleared;

        var row: i32 = @as(i32, @intCast(boardRows)) - 1;
        while (row >= 0) {
            var isFull = true;
            const rowIndex: usize = @as(usize, @intCast(row));
            for (0..boardColumn) |column| {
                if (self.colorBoard[rowIndex][column].a == 0) {
                    isFull = false;
                    break;
                }
            }

            if (isFull) {
                var y = row;
                while (y > 0) : (y -= 1) {
                    self.colorBoard[@as(usize, @intCast(y))] =
                        self.colorBoard[@as(usize, @intCast(y - 1))];
                }
                self.colorBoard[0] = [_]rl.Color{rl.Color.blank} ** boardColumn;
                cleared += 1;
                continue;
            }

            row -= 1;
        }

        return cleared;
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
        const min_speed: f32 = 0.05;
        const computed = 1.0 - (@as(f32, @floatFromInt(self.level)) * 0.1);
        self.fallSpeed = if (computed < min_speed) min_speed else computed;
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

    fn handleInput(self: *Self) void {
        if (self.currentPieceType == null) return;

        const leftPressed = rl.isKeyPressed(rl.KeyboardKey.left) or rl.isKeyPressed(rl.KeyboardKey.a);
        const rightPressed = rl.isKeyPressed(rl.KeyboardKey.right) or rl.isKeyPressed(rl.KeyboardKey.d);
        const rotateCWPressed = rl.isKeyPressed(rl.KeyboardKey.up) or rl.isKeyPressed(rl.KeyboardKey.w) or rl.isKeyPressed(rl.KeyboardKey.x);
        const rotateCCWPressed = rl.isKeyPressed(rl.KeyboardKey.z) or rl.isKeyPressed(rl.KeyboardKey.q);
        const hardDropPressed = rl.isKeyPressed(rl.KeyboardKey.space);
        const softDropHeld = rl.isKeyDown(rl.KeyboardKey.down) or rl.isKeyDown(rl.KeyboardKey.s);

        if (hardDropPressed) {
            self.hardDrop();
            return;
        }

        if (leftPressed and !rightPressed) {
            self.tryMove(-1);
        } else if (rightPressed and !leftPressed) {
            self.tryMove(1);
        }

        if (rotateCWPressed) {
            self.tryRotate(1);
        }

        if (rotateCCWPressed) {
            self.tryRotate(-1);
        }

        if (softDropHeld) {
            if (self.movePieceDown()) {
                self.dropAccumulator = 0.0;
            }
        }
    }

    pub fn movePieceDown(self: *Self) bool {
        if (self.currentPieceType == null) return false;

        self.clearCurrentPiece();
        const canMove = self.canMoveTo(self.currentPieceX, self.currentPieceY + 1);

        if (canMove) {
            self.currentPieceY += 1;
            self.addTetrominoeOnBoard();
            return true;
        } else {
            self.addTetrominoeOnBoard();
            self.lockCurrentPiece();
            const cleared = self.clearCompletedLines();
            self.applyLineClear(cleared);
            return false;
        }
    }

    pub fn update(self: *Self, dt: f32) void {
        if (rl.isKeyPressed(rl.KeyboardKey.p)) {
            self.gamePaused = !self.gamePaused;
        }

        if (self.gameOver or self.gamePaused) return;

        self.spawnTetrominoe();

        if (self.currentPieceType == null) return;

        self.handleInput();

        if (self.currentPieceType == null) return;

        const speed = if (self.fallSpeed <= 0) 0.05 else self.fallSpeed;
        self.dropAccumulator += dt;

        while (self.dropAccumulator >= speed) {
            self.dropAccumulator -= speed;
            if (!self.movePieceDown()) break;
        }
    }
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    const timestamp = std.time.microTimestamp();
    const seed = @as(u64, @intCast(if (timestamp < 0) -timestamp else timestamp));
    var tetrisGame = Game.init(seed);

    const screenWidth: i32 = 600;
    const screenHeight: i32 = 900;

    rl.initWindow(screenWidth, screenHeight, "Tetris by @ilyasbedir");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) {
        const frameTime = rl.getFrameTime();
        tetrisGame.update(frameTime);

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        tetrisGame.drawBoardGrid();
        tetrisGame.drawTetrominoe();
        //----------------------------------------------------------------------------------
    }
}
