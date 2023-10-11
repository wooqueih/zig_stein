const std = @import("std");

pub const WallType = enum(u8) {
    None = 0,
    Basic,
};

pub const Map = struct {
    walls: []WallType,
    height: usize,
    width: usize,

    fn isWallAtPosition(self: *Map, pos: *const Vec2) bool {
        if (pos.x < 0 or pos.x >= self.width or pos.y < 0 or pos.y >= self.height) {
            return false;
        }
        const idx: usize = @as(usize, @intFromFloat(pos.x)) + (@as(usize, @intFromFloat(pos.y)) * self.width);
        return switch (self.walls[idx]) {
            .None => false,
            .Basic => true,
        };
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
    camera_plane_width: f64 = 2,

    fn updateDirection(self: *Player) void {
        self.dir.x = std.math.cos(self.rot);
        self.dir.y = std.math.sin(self.rot);
    }

    pub fn rotate(self: *Player, rad: f64) void {
        self.rot = @mod(self.rot + rad, std.math.pi);
        self.updateDirection();
    }
};
