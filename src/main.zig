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

    board: [boardRows][boardColumn]u8 = undefined,
    tileColor: [boardRows][boardColumn]rl.Color = undefined,
    currentPieceType: tetro.Tetrominoes.ShapeType = tetro.Tetrominoes.ShapeType.NONE,
    nextPieceType: tetro.Tetrominoes.ShapeType = tetro.Tetrominoes.ShapeType.NONE,
    score: u32 = 0,
    level: u8 = 0,
    gameOver: bool = false,
    gamePaused: bool = false,
    fallSpeed: f32 = 1.0,

    pub fn initBoard(self: *Self) void {
        // Initialize entire board to zeros
        @memset(std.mem.asBytes(&self.board), 0);
        @memset(std.mem.asBytes(&self.tileColor), 0);
    }

    pub fn drawBoardGrid(self: *Self) void {
        _ = self;
        // Draw a grid with 10 columns and 20 rows
        const cellSize: f32 = 40.0; // Size of each cell in pixels
        //
        for (0..boardColumn + 1) |i| {
            rl.drawLineEx(
                rl.Vector2{
                    .x = boardStartCoordinateX + (@as(f32, @floatFromInt(i)) * cellSize),
                    .y = boardStartCoordinateY,
                },
                rl.Vector2{
                    .x = boardStartCoordinateX + (@as(f32, @floatFromInt(i)) * cellSize),
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
                    .y = boardStartCoordinateY + (@as(f32, @floatFromInt(j)) * cellSize),
                },
                rl.Vector2{
                    .x = boardStartCoordinateX + boardWidth,
                    .y = boardStartCoordinateY + (@as(f32, @floatFromInt(j)) * cellSize),
                },
                1.0,
                rl.Color.black,
            );
        }
    }

    pub fn drawTetrominoe(self: *Self) void {
        for (0..boardRows) |row| {
            for (0..boardColumn) |column| {
                if (0 < self.board[row][column]) {
                    rl.drawRectangleRec(
                        .{
                            .x = boardStartCoordinateX + (tileWidth * @as(f32, @floatFromInt(row))),
                            .y = boardStartCoordinateY + (tileWidth * @as(f32, @floatFromInt(column))),
                            .width = tileWidth,
                            .height = tileHeight,
                        },
                        self.tileColor[row][column],
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
        //
        tetrisGame.board[1][1] = 1;
        tetrisGame.tileColor[1][1] = rl.Color.green;
        tetrisGame.board[2][2] = 1;
        tetrisGame.tileColor[2][2] = rl.Color.red;
        tetrisGame.board[3][3] = 1;
        tetrisGame.tileColor[3][3] = rl.Color.purple;
        tetrisGame.board[4][4] = 1;
        tetrisGame.tileColor[4][4] = rl.Color.yellow;
        tetrisGame.board[5][5] = 1;
        tetrisGame.tileColor[5][5] = rl.Color.blue;
        tetrisGame.board[6][6] = 1;
        tetrisGame.tileColor[6][6] = rl.Color.magenta;
        // draw tetrominoes
        tetrisGame.drawTetrominoe();

        //rl.drawText("Congrats!", 190, 200, 20, rl.Color.gray);
        //----------------------------------------------------------------------------------
    }
}
