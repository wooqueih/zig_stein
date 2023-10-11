const std = @import("std");

pub const WallType = enum(u8) {
    None = 0,
    Basic,
};

pub const Map = struct {
    walls: []WallType,
    height: usize,
    width: usize,

    pub fn isWallAtPosition(self: *const Map, pos: *const Vec2) bool {
        if (pos.x < 0 or pos.x >= @as(f64, @floatFromInt(self.width)) or pos.y < 0 or pos.y >= @as(f64, @floatFromInt(self.height))) {
            return false;
        }
        const idx: usize = @as(usize, @intFromFloat(pos.x)) + (@as(usize, @intFromFloat(pos.y)) * self.width);
        return switch (self.walls[idx]) {
            .None => false,
            .Basic => true,
        };
    }

    pub fn debugPrint(self: *const Map) void {
        std.debug.print("// MAP", .{});
        var row: usize = 0;
        for (self.walls, 0..) |wall, i| {
            if (i % self.width == 0) {
                std.debug.print("\n{d}: ", .{row});
                row += 1;
            }
            std.debug.print("{d}", .{@as(u8, @intFromEnum(wall))});
        }
        std.debug.print("\n", .{});
    }
};

pub const Vec2 = struct {
    x: f64 = 0,
    y: f64 = 0,
};

pub const Vec3 = struct {
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,
};

pub const Player = struct {
    pos: Vec2,
    dir: Vec2 = Vec2{ .x = 1, .y = 0 },
    rot: f64 = 0,
    fov: f64 = std.math.degreesToRadians(f64, 100),

    fn updateDirection(self: *Player) void {
        self.dir.x = std.math.cos(self.rot);
        self.dir.y = std.math.sin(self.rot);
    }

    pub fn rotate(self: *Player, rad: f64) void {
        self.rot = @mod(self.rot + rad, std.math.pi * 2);
        self.updateDirection();
    }

    pub fn debugPrint(self: *const Player) void {
        std.debug.print("player: x{d} - y{d} | dir: x{d} - y{d}\n", .{ self.pos.x, self.pos.y, self.dir.x, self.dir.y });
    }
};
