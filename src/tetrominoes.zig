const rl = @import("raylib");

pub const Tetrominoes = struct {
    const Self = @This();

    // Piece types enum
    pub const ShapeType = enum(u8) {
        I_SHAPE = 0,
        O_SHAPE = 1,
        T_SHAPE = 2,
        L_SHAPE = 3,
        J_SHAPE = 4,
        S_SHAPE = 5,
        Z_SHAPE = 6,
    };

    pub const TetrominoeColor = enum {
        YELLOW,
        GOLD,
        ORANGE,
        PINK,
        RED,
        MAROON,
        GREEN,
        LIME,
        DARK_GREEN,
        SKY_BLUE,
        BLUE,
        DARK_BLUE,
        PURPLE,
        VIOLET,
        DARK_PURPLE,
        BEIGE,
        BROWN,
        DARK_BROWN,
        MAGENTA,

        pub fn toColor(self: TetrominoeColor) rl.Color {
            return switch (self) {
                .YELLOW => rl.Color.yellow,
                .GOLD => rl.Color.gold,
                .ORANGE => rl.Color.orange,
                .PINK => rl.Color.pink,
                .RED => rl.Color.red,
                .MAROON => rl.Color.maroon,
                .GREEN => rl.Color.green,
                .LIME => rl.Color.lime,
                .DARK_GREEN => rl.Color.dark_green,
                .SKY_BLUE => rl.Color.sky_blue,
                .BLUE => rl.Color.blue,
                .DARK_BLUE => rl.Color.dark_blue,
                .PURPLE => rl.Color.purple,
                .VIOLET => rl.Color.violet,
                .DARK_PURPLE => rl.Color.dark_purple,
                .BEIGE => rl.Color.beige,
                .BROWN => rl.Color.brown,
                .DARK_BROWN => rl.Color.dark_brown,
                .MAGENTA => rl.Color.magenta,
            };
        }
    };

    // All pieces data: [shape][rotation][row][column]
    // 7 shapes, 4 rotations each, 4x4 grid for each rotation
    pub const shapeData = [_][4][4][4]u8{
        // I shape
        [_][4][4]u8{
            // 0 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 1, 1, 1, 1 },
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            // 90 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 1, 0 },
                [_]u8{ 0, 0, 1, 0 },
                [_]u8{ 0, 0, 1, 0 },
                [_]u8{ 0, 0, 1, 0 },
            },
            // 180 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 1, 1, 1, 1 },
                [_]u8{ 0, 0, 0, 0 },
            },
            // 270 degrees
            [_][4]u8{
                [_]u8{ 0, 1, 0, 0 },
                [_]u8{ 0, 1, 0, 0 },
                [_]u8{ 0, 1, 0, 0 },
                [_]u8{ 0, 1, 0, 0 },
            },
        },
        // O shape
        [_][4][4]u8{
            // All rotations are the same for O
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 2, 2, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
        },
        // T shape
        [_][4][4]u8{
            // 0 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 3, 0, 0 },
                [_]u8{ 3, 3, 3, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            // 90 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 3, 0, 0 },
                [_]u8{ 0, 3, 3, 0 },
                [_]u8{ 0, 3, 0, 0 },
            },
            // 180 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 3, 3, 3, 0 },
                [_]u8{ 0, 3, 0, 0 },
            },
            // 270 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 3, 0, 0 },
                [_]u8{ 3, 3, 0, 0 },
                [_]u8{ 0, 3, 0, 0 },
            },
        },
        // L shape
        [_][4][4]u8{
            // 0 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 4, 0 },
                [_]u8{ 4, 4, 4, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            // 90 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 4, 0, 0 },
                [_]u8{ 0, 4, 0, 0 },
                [_]u8{ 0, 4, 4, 0 },
            },
            // 180 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 4, 4, 4, 0 },
                [_]u8{ 4, 0, 0, 0 },
            },
            // 270 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 4, 4, 0, 0 },
                [_]u8{ 0, 4, 0, 0 },
                [_]u8{ 0, 4, 0, 0 },
            },
        },
        // J shape
        [_][4][4]u8{
            // 0 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 5, 0, 0, 0 },
                [_]u8{ 5, 5, 5, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            // 90 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 5, 5, 0 },
                [_]u8{ 0, 5, 0, 0 },
                [_]u8{ 0, 5, 0, 0 },
            },
            // 180 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 5, 5, 5, 0 },
                [_]u8{ 0, 0, 5, 0 },
            },
            // 270 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 5, 0, 0 },
                [_]u8{ 0, 5, 0, 0 },
                [_]u8{ 5, 5, 0, 0 },
            },
        },
        // S shape
        [_][4][4]u8{
            // 0 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 6, 6, 0 },
                [_]u8{ 6, 6, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            // 90 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 6, 0, 0 },
                [_]u8{ 0, 6, 6, 0 },
                [_]u8{ 0, 0, 6, 0 },
            },
            // 180 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 6, 6, 0 },
                [_]u8{ 6, 6, 0, 0 },
            },
            // 270 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 6, 0, 0, 0 },
                [_]u8{ 6, 6, 0, 0 },
                [_]u8{ 0, 6, 0, 0 },
            },
        },
        // Z shape
        [_][4][4]u8{
            // 0 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 7, 7, 0, 0 },
                [_]u8{ 0, 7, 7, 0 },
                [_]u8{ 0, 0, 0, 0 },
            },
            // 90 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 7, 0 },
                [_]u8{ 0, 7, 7, 0 },
                [_]u8{ 0, 7, 0, 0 },
            },
            // 180 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 7, 7, 0, 0 },
                [_]u8{ 0, 7, 7, 0 },
            },
            // 270 degrees
            [_][4]u8{
                [_]u8{ 0, 0, 0, 0 },
                [_]u8{ 0, 7, 0, 0 },
                [_]u8{ 7, 7, 0, 0 },
                [_]u8{ 7, 0, 0, 0 },
            },
        },
    };

    // Helper functions can be added here
    pub fn getShape(shape_type: ShapeType, rotation: u8) *const [4][4]u8 {
        return &shapeData[@intFromEnum(shape_type)][rotation % 4];
    }
};
