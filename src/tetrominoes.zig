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
            .I => rl.Color.sky_blue,
            .O => rl.Color.yellow,
            .T => rl.Color.purple,
            .L => rl.Color.orange,
            .J => rl.Color.blue,
            .S => rl.Color.green,
            .Z => rl.Color.red,
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
