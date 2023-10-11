const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const init = @import("init.zig");
const util = @import("util.zig");
const defs = @import("defs.zig");

const logical_screen_size = defs.Vec2{ .x = 100, .y = 100 };
const physical_screen_size = defs.Vec2{ .x = 1000, .y = 1000 };
var delta_time_ms: u32 = 1;

const general_mem_size = 30_000;

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
        t += @floatFromInt(delta_time_ms);

        player.pos.x += player.dir.x;
        player.pos.y += player.dir.y;
    }
    if (pressed_keys_set.get(c.SDLK_s) != null) {
        t -= @floatFromInt(delta_time_ms);

        player.pos.x -= player.dir.x;
        player.pos.y -= player.dir.y;
    }
    if (pressed_keys_set.get(c.SDLK_a) != null) {
        player.rotate(0.1);
    }
    if (pressed_keys_set.get(c.SDLK_d) != null) {
        player.rotate(-0.1);
    }

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
fn draw(renderer: *c.SDL_Renderer, player: *const defs.Player, map: *const defs.Map) !void {
    _ = map;
    _ = player;

    if (c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255) != 0) {
        util.logSdlError();
        return error.SdlError;
    }
    if (c.SDL_RenderClear(renderer) != 0) {
        util.logSdlError();
        return error.SdlError;
    }
    if (c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255) != 0) {
        util.logSdlError();
        return error.SdlError;
    }

    for (0..@intFromFloat(std.math.round(logical_screen_size.x))) |i| {
        const height: f64 = std.math.sin((t * 0.01) + (@as(f64, @floatFromInt(i)) / logical_screen_size.x)) * (0.5 * logical_screen_size.y);
        const clamped_height = std.math.clamp(height, -0.5 * logical_screen_size.y, 0.5 * logical_screen_size.y);
        const rect = c.SDL_Rect{ .x = @intCast(i), .y = @as(c_int, @intFromFloat(@round(0.5 * logical_screen_size.y - clamped_height))), .w = 1, .h = @as(c_int, @intFromFloat(@round(clamped_height))) };
        if (c.SDL_RenderDrawRect(renderer, &rect) != 0) {
            util.logSdlError();

            return error.CantDrawRect;
        }
    }
    c.SDL_RenderPresent(renderer);
}
