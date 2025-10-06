const std = @import("std");
const rl = @import("raylib");
//const rg = @import("raygui");
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
    gameOver: bool = false,
    gamePaused: bool = false,
    fallSpeed: f32 = 1.0,
    rotation: u8 = 0, // TODO: refactor this to use enum instead plain value
    currentPieceY: i32 = 0,
    currentPieceX: i32 = 0,

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
        _ = self;
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        var random = prng.random();
        return random.enumValue(tetro.Tetrominoes.ShapeType);
    }

    fn getRandomTetrominoeColor(self: *Self) tetro.Tetrominoes.TetrominoeColor {
        _ = self;
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
        return std.Random.enumValue(prng.random(), tetro.Tetrominoes.TetrominoeColor);
    }

    fn getRandomRotation(self: *Self) u8 {
        _ = self;
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        var random = prng.random();
        return random.uintLessThan(u8, 4); // Random number between 0 and 3 inclusive
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
    }

    fn lockCurrentPiece(self: *Self) void {
        self.currentPieceType = null;
        self.currentPieceColor = rl.Color.blank;
        self.rotation = 0;
        self.currentPieceX = 0;
        self.currentPieceY = 0;
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
            return false;
        }
    }
};

fn dynamicWindow() void {
    const screenWidth = 800;
    const screenHeight = 450;
    rl.initWindow(screenWidth, screenHeight, "Tetris ZIG develop");
    const monitor: i32 = rl.getCurrentMonitor();
    const monitorWidth: i32 = rl.getMonitorWidth(monitor);
    const monitorHeight: i32 = rl.getMonitorHeight(monitor);
    const otnosheniye: f32 = @as(f32, @floatFromInt(monitorWidth)) / @as(f32, @floatFromInt(monitorHeight));

    // Set a fixed width and calculate height based on aspect ratio
    const targetWidth: i32 = @intFromFloat(@as(f32, @floatFromInt(monitorHeight)) / otnosheniye);
    const targetHeight: i32 = @intFromFloat(@as(f32, @floatFromInt(monitorWidth)) / 2);

    std.debug.print("\ntest {}, {}, ratio: {}\n\n", .{ targetWidth, targetHeight, otnosheniye });
    rl.closeWindow(); // Close window and OpenGL context
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------

    //
    var tetrisGame: Game = .{
        .colorBoard = [_][Game.boardColumn]rl.Color{[_]rl.Color{rl.Color.blank} ** Game.boardColumn} ** Game.boardRows,
        .currentPieceType = null,
        .nextPieceType = null,
        .currentPieceColor = rl.Color.blank,
        .score = 0,
        .level = 0,
        .gameOver = false,
        .gamePaused = false,
        .fallSpeed = 1.0,
    };
    var fallTimer: f32 = 0.0;
    //
    const screenWidth: i32 = 600;
    const screenHeight: i32 = 900;

    rl.initWindow(screenWidth, screenHeight, "Tetris by @ilyasbedir");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Initialize the next piece
    tetrisGame.nextPieceType = tetrisGame.getRandomTetrominoeType();
    tetrisGame.spawnTetrominoe();

    // Main game loop
    while (!rl.windowShouldClose()) {
        const frameTime = rl.getFrameTime();
        fallTimer += frameTime;

        if (!tetrisGame.gameOver) {
            tetrisGame.spawnTetrominoe();

            if (tetrisGame.currentPieceType != null) {
                while (fallTimer >= tetrisGame.fallSpeed) {
                    fallTimer -= tetrisGame.fallSpeed;
                    _ = tetrisGame.movePieceDown();
                    if (tetrisGame.currentPieceType == null) break;
                }
            }
        }

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
