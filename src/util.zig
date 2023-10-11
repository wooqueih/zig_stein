const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const defs = @import("defs.zig");

pub fn logSdlError() void {
    std.log.err("SDL ERROR: {s}", .{c.SDL_GetError()});
}

pub fn rayCast(player: *defs.Player, map: *const defs.Map, max_distance: f64) f64 {
    var distance: f64 = 0;

    const secant = @fabs(1.0 / player.dir.y);
    const cosecant = @fabs(1.0 / player.dir.x);

    //const x_over_y = player.dir.x / player.dir.y;
    //const y_over_x = player.dir.y / player.dir.x;
    const sign = defs.Vec2{
        .x = std.math.sign(player.dir.x),
        .y = std.math.sign(player.dir.y),
    };
    var deltas = defs.Vec2{ .x = blk: {
        const x_fract = player.pos.x - std.math.floor(player.pos.x);
        break :blk ((0.5 + 0.5 * sign.x) - x_fract * sign.x) * cosecant;
    }, .y = blk: {
        const y_fract = player.pos.y - std.math.floor(player.pos.y);
        break :blk ((0.5 + 0.5 * sign.y) - y_fract * sign.y) * secant;
    } };

    var ray_pos = player.pos;
    var hit = false;
    while (!hit and distance < max_distance) {
        if (deltas.x < deltas.y) {
            ray_pos.x += sign.x;

            deltas.y -= deltas.x;
            distance += @fabs(deltas.x);

            deltas.x = cosecant;
        } else if (deltas.y < deltas.x) {
            ray_pos.y += sign.y;

            deltas.x -= deltas.y;
            distance += @fabs(deltas.y);

            deltas.y = secant;
        } else {
            ray_pos.x += sign.x;
            ray_pos.y += sign.y;
            distance += @fabs(deltas.x);

            deltas.y = secant;
            deltas.x = cosecant;
        }

        if (map.isWallAtPosition(&ray_pos)) {
            hit = true;
        }
    }
    return @min(distance, max_distance);
}
