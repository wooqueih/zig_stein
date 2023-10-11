const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const defs = @import("defs.zig");

pub fn logSdlError() void {
    std.log.err("SDL ERROR: {s}", .{c.SDL_GetError()});
}


pub fn rayCast(pos: defs.Vec2, dir: defs.Vec2, map: *const defs.Map, max_distance: f64) f64 {
    _ = map;
    var distance: f64 = 0;
    const ratio = dir.x / dir.y;
    _ = ratio;
    var delta_to_next_wall = defs.Vec2 {
        .x = blk: {
            if (dir.x > 0) {
                break :blk 1 - (pos.x - std.math.floor(pos.x));
            }
            if (dir.x < 0) {
                break :blk pos.x - std.math.floor(pos.x);
            }
        }
    };
    _ = delta_to_next_wall;
    while (distance < max_distance) {
    }
}
