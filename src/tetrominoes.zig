const std = @import("std");
const rl = @import("raylib");

pub const Tetrominoes = struct {
    pub const ShapeType = enum(u8) {
        I,
        O,
        T,
        L,
        J,
        S,
        Z,
    };

    pub fn colorForShape(shape: ShapeType) rl.Color {
        return switch (shape) {
            .I => rl.Color{ .r = 107, .g = 232, .b = 255, .a = 255 },
            .O => rl.Color{ .r = 255, .g = 198, .b = 107, .a = 255 },
            .T => rl.Color{ .r = 197, .g = 153, .b = 255, .a = 255 },
            .L => rl.Color{ .r = 255, .g = 142, .b = 110, .a = 255 },
            .J => rl.Color{ .r = 115, .g = 149, .b = 255, .a = 255 },
            .S => rl.Color{ .r = 113, .g = 247, .b = 200, .a = 255 },
            .Z => rl.Color{ .r = 255, .g = 109, .b = 179, .a = 255 },
        };
    }

    fn parseRow(comptime row: []const u8) [4]bool {
        if (row.len != 4) {
            @compileError("Tetromino row patterns must be 4 characters long");
        }

        return .{
            row[0] == '#',
            row[1] == '#',
            row[2] == '#',
            row[3] == '#',
        };
    }

    fn pattern(
        comptime r0: []const u8,
        comptime r1: []const u8,
        comptime r2: []const u8,
        comptime r3: []const u8,
    ) [4][4]bool {
        return .{
            parseRow(r0),
            parseRow(r1),
            parseRow(r2),
            parseRow(r3),
        };
    }

    pub const shapeData = [_][4][4][4]bool{
        .{
            pattern("....", "####", "....", "...."),
            pattern("..#.", "..#.", "..#.", "..#."),
            pattern("....", "....", "####", "...."),
            pattern(".#..", ".#..", ".#..", ".#.."),
        },
        .{
            pattern("....", ".##.", ".##.", "...."),
            pattern("....", ".##.", ".##.", "...."),
            pattern("....", ".##.", ".##.", "...."),
            pattern("....", ".##.", ".##.", "...."),
        },
        .{
            pattern("....", ".#..", "###.", "...."),
            pattern("....", ".#..", ".##.", ".#.."),
            pattern("....", "....", "###.", ".#.."),
            pattern("....", ".#..", "##..", ".#.."),
        },
        .{
            pattern("....", "..#.", "###.", "...."),
            pattern("....", ".#..", ".#..", ".##."),
            pattern("....", "....", "###.", "#..."),
            pattern("....", "##..", ".#..", ".#.."),
        },
        .{
            pattern("....", "#...", "###.", "...."),
            pattern("....", ".##.", ".#..", ".#.."),
            pattern("....", "....", "###.", "..#."),
            pattern("....", ".#..", ".#..", "##.."),
        },
        .{
            pattern("....", ".##.", "##..", "...."),
            pattern("....", ".#..", ".##.", "..#."),
            pattern("....", "....", ".##.", "##.."),
            pattern("....", "#...", "##..", ".#.."),
        },
        .{
            pattern("....", "##..", ".##.", "...."),
            pattern("....", "..#.", ".##.", ".#.."),
            pattern("....", "....", "##..", ".##."),
            pattern("....", ".#..", "##..", "#..."),
        },
    };

    pub fn getShape(shape_type: ShapeType, rotation: u8) *const [4][4]bool {
        return &shapeData[@intFromEnum(shape_type)][rotation % 4];
    }
};
