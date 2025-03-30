const std = @import("std");
const rl = @import("raylib");
//const rg = @import("raygui");
const tetro = @import("tetrominoes.zig");

const Game = struct {
    const Self = @This();
    // Game properties here
    const boardStartCoordinateX = 50;
    const boardStartCoordinateY = 10;
    const boardWidth = 400;
    const boardHeight = 800;
    const boardRows = 20;
    const boardColumn = 10;
    board: [boardRows][boardColumn]u8 = undefined,
    currentPieceType: tetro.TetrominoesType = tetro.TetrominoesType.NO_SHAPE,
    nextPieceType: tetro.TetrominoesType = tetro.TetrominoesType.NO_SHAPE,
    score: u32 = 0,
    level: u8 = 0,
    gameOver: bool = false,
    gamePaused: bool = false,
    fallSpeed: f32 = 1.0,

    pub fn initBoard(self: *Self) void {
        // Initialize entire board to zeros
        @memset(std.mem.asBytes(&self.board), 0);
    }

    pub fn drawBoardGrid(self: *Self) void {
        _ = self;
        // Draw a grid with 10 columns and 20 rows
        const cellSize: f32 = 40.0; // Size of each cell in pixels
        // const offsetX: i32 = 100; // X position offset
        // const offsetY: i32 = 50; // Y position offset
        //
        for (0..boardColumn + 1) |i| {
            rl.drawLineEx(
                rl.Vector2{
                    .x = @as(f32, @floatFromInt(boardStartCoordinateX)) + @as(f32, @floatFromInt(i)) * cellSize,
                    .y = boardStartCoordinateY,
                },
                rl.Vector2{
                    .x = @as(f32, @floatFromInt(boardStartCoordinateX)) + @as(f32, @floatFromInt(i)) * cellSize,
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
                    .y = @as(f32, @floatFromInt(boardStartCoordinateY)) + @as(f32, @floatFromInt(j)) * cellSize,
                },
                rl.Vector2{
                    .x = boardStartCoordinateX + boardWidth,
                    .y = @as(f32, @floatFromInt(boardStartCoordinateY)) + @as(f32, @floatFromInt(j)) * cellSize,
                },
                1.0,
                rl.Color.black,
            );
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
    var tetrisGame: Game = undefined;
    //
    const screenWidth: i32 = 600;
    const screenHeight: i32 = 900;

    rl.initWindow(screenWidth, screenHeight, "Tetris ZIG develop");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Initialize board
    tetrisGame.initBoard();

    // Main game loop
    while (!rl.windowShouldClose()) {

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        // draw grid for the debug
        tetrisGame.drawBoardGrid();

        //rl.drawText("Congrats!", 190, 200, 20, rl.Color.gray);
        //----------------------------------------------------------------------------------
    }
}
