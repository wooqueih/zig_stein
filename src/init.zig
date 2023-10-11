const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn initSDL(window: **c.SDL_Window, renderer: **c.SDL_Renderer, hints: struct { physical_width: u32 = 400, physical_height: u32 = 400, logical_width: u32 = 400, logical_height: u32 = 400, x: u32 = c.SDL_WINDOWPOS_UNDEFINED, y: u32 = c.SDL_WINDOWPOS_UNDEFINED }) !void {
    const renderer_flags: c_int = c.SDL_RENDERER_ACCELERATED;
    const window_flags: c_int = 0;

    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_TIMER) < 0) {
        std.log.err("Couldn't init SDL: {s}", .{c.SDL_GetError()});
        return error.SdlInitFailed;
    }

    var sdl_window = c.SDL_CreateWindow("zig_stein", @intCast(hints.x), @intCast(hints.y), @intCast(hints.physical_width), @intCast(hints.physical_height), window_flags);
    if (sdl_window == null) {
        std.log.err("Failed to Create {d}x{d} Window: {s}", .{ hints.physical_width, hints.physical_height, c.SDL_GetError() });
        return error.CreateWindowFailed;
    }
    window.* = sdl_window.?;

    _ = c.SDL_SetHint(c.SDL_HINT_RENDER_SCALE_QUALITY, "linear");

    var sdl_renderer = c.SDL_CreateRenderer(sdl_window, -1, renderer_flags);
    if (sdl_renderer == null) {
        std.log.err("Failed to Create Renderer: {s}", .{c.SDL_GetError()});
        return error.CreateWindowFailed;
    }
    renderer.* = sdl_renderer.?;

    if (c.SDL_RenderSetLogicalSize(sdl_renderer, @intCast(hints.logical_width), @intCast(hints.logical_height)) != 0) {
        std.log.err("Failed to set logical size: {s}", .{c.SDL_GetError()});
        return error.SetLogicalSizeFailed;
    }
}
