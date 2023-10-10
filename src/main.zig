const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn initSDL(sdl_window: ?*c.SDL_Window, sdl_renderer: ?*c.SDL_Renderer, hints: struct { physical_width: u32 = 400, physical_height: u32 = 400, logical_width: u32 = 400, logical_height: u32 = 400, x: u32 = c.SDL_WINDOWPOS_UNDEFINED, y: u32 = c.SDL_WINDOWPOS_UNDEFINED }) !void {
    const renderer_flags: c_int = c.SDL_RENDERER_ACCELERATED;
    const window_flags: c_int = 0;

    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_TIMER) < 0) {
        std.log.err("Couldn't init SDL: {s}", .{c.SDL_GetError()});
        return error.SdlInitFailed;
    }

    sdl_window = c.SDL_CreateWindow("zig_stein", hints.x, hints.y, hints.physical_width, hints.physical_height, window_flags);
    if (sdl_window == null) {
        std.log.err("Failed to Create {d}x{d} Window: {s}", .{ hints.physical_width, hints.physical_height, c.SDL_GetError() });
        return error.CreateWindowFailed;
    }

    _ = c.SDL_SetHint(c.SDL_HINT_RENDER_SCALE_QUALITY, "linear");

    sdl_renderer = c.SDL_CreateRenderer(sdl_window, -1, renderer_flags);
    if (sdl_renderer == null) {
        std.log.err("Failed to Create Renderer: {s}", .{c.SDL_GetError()});
        return error.CreateWindowFailed;
    }

    if (!c.SDL_RenderSetLogicalSize(sdl_renderer, hints.logical_width, hints.logical_height)) {
        std.log.err("Failed to set logical size: {s}", .{c.SDL_GetError()});
        return error.SetLogicalSizeFailed;
    }
}

const WallType = enum(u8) {
    None = 0,
    Basic,
};

const Map = struct {
    walls: []WallType,
    height: usize,
    width: usize,
};

const vec2 = struct {
    x: f64,
    y: f64,
};

const vec3 = struct {
    x: f64,
    y: f64,
    z: f64,
};

const Player = struct {
    pos: vec3,
    rot: vec2
};

pub fn main() !void {
    const window: *c.SDL_Window = null;
    const renderer: *c.SDL_Renderer = null;
    initSDL(window, renderer, .{
        .physical_width = 400,
        .physical_height = 400,
        .logical_width = 400,
        .logical_height = 400,
        .x = c.SDL_WINDOWPOS_UNDEFINED,
        .y = c.SDL_WINDOWPOS_UNDEFINED,
    });

    const map = Map{
        .walls = [_]WallType{.None} ** 25,
        .height = 5,
        .widht = 5,
    };
    _ = map;


}
