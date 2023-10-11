const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const init = @import("init.zig");
const util = @import("util.zig");
const defs = @import("defs.zig");

const logical_screen_size = defs.Vec2{ .x = 1000, .y = 1000 };
const physical_screen_size = defs.Vec2{ .x = 1000, .y = 1000 };
var delta_time_ms: u32 = 1;
var fdelta_time_ms: f64 = 1;

const general_mem_size = 30_000;
const walk_speed = 0.001;
const look_speed = 0.002;

pub fn main() !void {
    var window: *c.SDL_Window = undefined;
    var renderer: *c.SDL_Renderer = undefined;
    try init.initSDL(&window, &renderer, .{
        .physical_width = physical_screen_size.x,
        .physical_height = physical_screen_size.y,
        .logical_width = logical_screen_size.x,
        .logical_height = logical_screen_size.y,
        .x = c.SDL_WINDOWPOS_UNDEFINED,
        .y = c.SDL_WINDOWPOS_UNDEFINED,
    });
    defer c.SDL_DestroyWindow(window);
    defer c.SDL_DestroyRenderer(renderer);

    var general_mem = [_]u8{0} ** general_mem_size;
    var general_mem_fba = std.heap.FixedBufferAllocator.init(&general_mem);
    const allocator = general_mem_fba.allocator();

    var pressed_keys_set = std.AutoHashMap(c_int, void).init(allocator);

    var walls = [_]defs.WallType{.None} ** 25;
    const map = defs.Map{
        .walls = &walls,
        .height = 5,
        .width = 5,
    };
    for (map.walls, 0..) |*wall, i| {
        const rem = i % map.width;
        if (rem == 0 or rem == map.width - 1) {
            wall.* = .Basic;
        }
    }

    var player = defs.Player{
        .pos = defs.Vec2{ .x = 2, .y = 5 },
    };

    var running = true;
    var last_frame_time: u32 = 0;
    var this_frame_time: u32 = 1;
    while (running) {
        last_frame_time = this_frame_time;
        this_frame_time = c.SDL_GetTicks();
        delta_time_ms = this_frame_time - last_frame_time;
        fdelta_time_ms = @floatFromInt(delta_time_ms);
        std.debug.print("\ndeltaTime (ms): {d} | FPS: {d}\n", .{ delta_time_ms, 1000.0 / fdelta_time_ms });
        running = try gameLoop(window, renderer, &player, &map, &pressed_keys_set);
    }
    c.SDL_Quit();
}

fn gameLoop(window: *c.SDL_Window, renderer: *c.SDL_Renderer, player: *defs.Player, map: *const defs.Map, pressed_keys_set: *std.AutoHashMap(c_int, void)) !bool {
    _ = window;
    if (try pollInput(pressed_keys_set) == .Quit) {
        return false;
    }
    if (pressed_keys_set.get(c.SDLK_w) != null) {
        player.pos.x += player.dir.x * fdelta_time_ms * walk_speed;
        player.pos.y += player.dir.y * fdelta_time_ms * walk_speed;
    }
    if (pressed_keys_set.get(c.SDLK_s) != null) {
        player.pos.x -= player.dir.x * fdelta_time_ms * walk_speed;
        player.pos.y -= player.dir.y * fdelta_time_ms * walk_speed;
    }
    if (pressed_keys_set.get(c.SDLK_a) != null) {
        player.rotate(1.0 * fdelta_time_ms * look_speed);
    }
    if (pressed_keys_set.get(c.SDLK_d) != null) {
        player.rotate(-1.0 * fdelta_time_ms * look_speed);
    }

    player.debugPrint();
    map.debugPrint();

    try draw(renderer, player, map);
    return true;
}

const SdlEvent = enum { Unspecified, Quit, KeyDown, KeyUp };
fn pollInput(pressed_keys_set: *std.AutoHashMap(c_int, void)) !SdlEvent {
    var event: c.SDL_Event = undefined;
    _ = c.SDL_PollEvent(&event);
    switch (event.type) {
        c.SDL_KEYDOWN => {
            try pressed_keys_set.put(event.key.keysym.sym, {});
        },
        c.SDL_KEYUP => {
            _ = pressed_keys_set.remove(event.key.keysym.sym);
        },
        c.SDL_QUIT => return .Quit,
        else => {},
    }
    return .Unspecified;
}

var t: f64 = 0;
const max_draw_distance: comptime_float = 10;
const max_draw_distance_inverse: comptime_float = 1.0 / max_draw_distance;
fn draw(renderer: *c.SDL_Renderer, player_in: *defs.Player, map: *const defs.Map) !void {
    var player = player_in.*;
    if (c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255) != 0) {
        util.logSdlError();
        return error.SdlError;
    }
    if (c.SDL_RenderClear(renderer) != 0) {
        util.logSdlError();
        return error.SdlError;
    }

    const half_screen_height = logical_screen_size.y * 0.5;
    const rot_step = -player.fov / logical_screen_size.x;
    player.rotate(player.fov * 0.5);
    for (0..@intFromFloat(std.math.round(logical_screen_size.x))) |i| {
        defer player.rotate(rot_step);

        //const prct = (@as(f64, @floatFromInt(i)) / logical_screen_size.x);
        const inverse_distance: f64 = @min((1.0 / util.rayCast(&player, map, max_draw_distance)), 1.0);
        const height: f64 = inverse_distance * half_screen_height;

        const clamped_height = std.math.clamp(height, -1 * half_screen_height, half_screen_height);
        const brightness: u8 = @intFromFloat(@min(inverse_distance, 1.0) * 255);
        if (c.SDL_SetRenderDrawColor(renderer, brightness, brightness / 2, 0, 255) != 0) {
            util.logSdlError();
            return error.SdlError;
        }
        const rect = c.SDL_Rect{ .x = @intCast(i), .y = @as(c_int, @intFromFloat(@round(half_screen_height - clamped_height))), .w = 1, .h = @as(c_int, @intFromFloat(@round(2 * clamped_height))) };

        if (c.SDL_RenderDrawRect(renderer, &rect) != 0) {
            util.logSdlError();
            return error.CantDrawRect;
        }
    }
    c.SDL_RenderPresent(renderer);
}
