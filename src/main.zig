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
    const boardRows: f32 = 20;
    const boardColumn: f32 = 10;
    const tileWidth = boardWidth / boardColumn;
    const tileHeight = boardHeight / boardRows;

    comptime {
        if (tileWidth != tileHeight) {
            @compileError("Tile width and tile height are not equal");
        }
    }

    colorBoard: [boardRows][boardColumn]rl.Color = undefined,
    currentPieceType: ?tetro.Tetrominoes.ShapeType = null,
    nextPieceType: ?tetro.Tetrominoes.ShapeType = null,
    score: u32 = 0,
    level: u8 = 0,
    gameOver: bool = false,
    gamePaused: bool = false,
    fallSpeed: f32 = 1.0,
    rotation: u8 = 0, // TODO: refactor this to use enum instead plain value

    // Empty color (black with alpha 0) indicates no piece
    const EMPTY_COLOR = rl.Color{ .r = 0, .g = 0, .b = 0, .a = 0 };

    pub fn drawBoardGrid(self: *Self) void {
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

    pub fn getRandomTetrominoeType(self: *Self) tetro.Tetrominoes.ShapeType {
        _ = self;
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        var random = prng.random();
        return random.enumValue(tetro.Tetrominoes.ShapeType);
    }

    pub fn getRandomTetrominoeColor(self: *Self) tetro.Tetrominoes.TetrominoeColor {
        _ = self;
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
        return std.Random.enumValue(prng.random(), tetro.Tetrominoes.TetrominoeColor);
    }

    pub fn getRandomRotation(self: *Self) u8 {
        _ = self;
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        var random = prng.random();
        return random.uintLessThan(u8, 4); // Random number between 0 and 3 inclusive
    }

    pub fn addTetrominoeOnBoard(self: *Self) void {
        //
        if (self.currentPieceType) |pieceType| {
            const tile = tetro.Tetrominoes.getShape(pieceType, self.rotation);

            // Define position
            const startX: i32 = 0; // Center of board
            const startY: i32 = 0; // Top of board

            // Generate a random color for this specific piece
            const pieceColor = tetro.Tetrominoes.TetrominoeColor.toColor(self.getRandomTetrominoeColor());

            //
            for (0..4) |row| {
                for (0..4) |column| {
                    if (0 < tile[row][column]) {
                        const tileRow = @as(usize, @intCast(startY + @as(i32, @intCast(row))));
                        const tileColumn = @as(usize, @intCast(startX + @as(i32, @intCast(column))));
                        const bRows = @as(usize, @intFromFloat(boardRows));
                        const bColumns = @as(usize, @intFromFloat(boardColumn));

                        if ((tileRow < bRows) and (tileColumn < bColumns)) {
                            // Just set the color - the presence of color indicates a piece
                            self.colorBoard[tileRow][tileColumn] = pieceColor;
                        }
                    }
                }
            }
        }
    }

    pub fn spawnTetrominoe(self: *Self) void {
        self.currentPieceType = self.nextPieceType;
        self.nextPieceType = self.getRandomTetrominoeType();
        self.rotation = self.getRandomRotation();
        self.addTetrominoeOnBoard();
        self.drawTetrominoe();
    }

    pub fn drawTetrominoe(self: *Self) void {
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
        .colorBoard = [_][Game.boardColumn]rl.Color{[_]rl.Color{Game.EMPTY_COLOR} ** Game.boardColumn} ** Game.boardRows,
        .currentPieceType = null,
        .nextPieceType = null,
        .score = 0,
        .level = 0,
        .gameOver = false,
        .gamePaused = false,
        .fallSpeed = 1.0,
    };
    //
    const screenWidth: i32 = 600;
    const screenHeight: i32 = 900;

    rl.initWindow(screenWidth, screenHeight, "Tetris ZIG develop");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Initialize the next piece
    tetrisGame.nextPieceType = tetrisGame.getRandomTetrominoeType();

    // Main game loop
    while (!rl.windowShouldClose()) {

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        // spawn tetrominoe
        tetrisGame.spawnTetrominoe();
        // draw grid for the debug
        tetrisGame.drawBoardGrid();
        //
        std.time.sleep(1 * std.time.ns_per_s);
        //----------------------------------------------------------------------------------
    }
}
