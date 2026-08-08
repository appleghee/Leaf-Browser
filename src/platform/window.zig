const std = @import("std");
const webview2 = @import("../webview2/runtime.zig");

const windows = std.os.windows;
const WINAPI = windows.WINAPI;
const HINSTANCE = windows.HINSTANCE;
const HWND = windows.HWND;
const HBRUSH = windows.HBRUSH;
const HMENU = windows.HMENU;
const HICON = windows.HICON;
const HCURSOR = windows.HCURSOR;
const LPARAM = windows.LPARAM;
const LRESULT = windows.LRESULT;
const UINT = windows.UINT;
const WPARAM = windows.WPARAM;

pub const WindowOptions = struct {
    title: []const u8,
    width: i32,
    height: i32,
};

const WindowState = struct {
    webview_runtime_available: bool,
};

const WNDCLASS_NAME = std.unicode.utf8ToUtf16LeStringLiteral("LeafBrowserWindow");
const DEFAULT_FONT = std.unicode.utf8ToUtf16LeStringLiteral("Segoe UI");

const WM_CREATE: UINT = 0x0001;
const WM_DESTROY: UINT = 0x0002;
const WM_PAINT: UINT = 0x000F;
const WM_SIZE: UINT = 0x0005;
const CS_HREDRAW: UINT = 0x0002;
const CS_VREDRAW: UINT = 0x0001;
const CW_USEDEFAULT: i32 = -2147483648;
const WS_OVERLAPPEDWINDOW: u32 = 0x00CF0000;
const WS_VISIBLE: u32 = 0x10000000;
const COLOR_WINDOW: usize = 5;
const SW_SHOW: i32 = 5;
const DT_LEFT: u32 = 0x00000000;
const DT_TOP: u32 = 0x00000000;
const DT_WORDBREAK: u32 = 0x00000010;

const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

const POINT = extern struct {
    x: i32,
    y: i32,
};

const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: u32,
    pt: POINT,
};

const PAINTSTRUCT = extern struct {
    hdc: ?*anyopaque,
    fErase: i32,
    rcPaint: RECT,
    fRestore: i32,
    fIncUpdate: i32,
    rgbReserved: [32]u8,
};

const WNDCLASSEXW = extern struct {
    cbSize: UINT,
    style: UINT,
    lpfnWndProc: *const fn (HWND, UINT, WPARAM, LPARAM) callconv(WINAPI) LRESULT,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: HINSTANCE,
    hIcon: HICON,
    hCursor: HCURSOR,
    hbrBackground: HBRUSH,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: [*:0]const u16,
    hIconSm: HICON,
};

extern "user32" fn RegisterClassExW(*const WNDCLASSEXW) callconv(WINAPI) u16;
extern "user32" fn CreateWindowExW(u32, [*:0]const u16, [*:0]const u16, u32, i32, i32, i32, i32, HWND, HMENU, HINSTANCE, ?*anyopaque) callconv(WINAPI) HWND;
extern "user32" fn DefWindowProcW(HWND, UINT, WPARAM, LPARAM) callconv(WINAPI) LRESULT;
extern "user32" fn DispatchMessageW(*const MSG) callconv(WINAPI) LRESULT;
extern "user32" fn GetClientRect(HWND, *RECT) callconv(WINAPI) i32;
extern "user32" fn GetMessageW(*MSG, HWND, UINT, UINT) callconv(WINAPI) i32;
extern "user32" fn GetModuleHandleW(?[*:0]const u16) callconv(WINAPI) HINSTANCE;
extern "user32" fn PostQuitMessage(i32) callconv(WINAPI) void;
extern "user32" fn ShowWindow(HWND, i32) callconv(WINAPI) i32;
extern "user32" fn TranslateMessage(*const MSG) callconv(WINAPI) i32;
extern "user32" fn UpdateWindow(HWND) callconv(WINAPI) i32;
extern "user32" fn BeginPaint(HWND, *PAINTSTRUCT) callconv(WINAPI) ?*anyopaque;
extern "user32" fn EndPaint(HWND, *const PAINTSTRUCT) callconv(WINAPI) i32;
extern "user32" fn DrawTextW(?*anyopaque, [*:0]const u16, i32, *RECT, u32) callconv(WINAPI) i32;
extern "user32" fn SetWindowLongPtrW(HWND, i32, isize) callconv(WINAPI) isize;
extern "user32" fn GetWindowLongPtrW(HWND, i32) callconv(WINAPI) isize;

const GWLP_USERDATA: i32 = -21;

pub fn run(options: WindowOptions) !void {
    const instance = GetModuleHandleW(null);
    const class = WNDCLASSEXW{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = CS_HREDRAW | CS_VREDRAW,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = instance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = @ptrFromInt(COLOR_WINDOW + 1),
        .lpszMenuName = null,
        .lpszClassName = WNDCLASS_NAME,
        .hIconSm = null,
    };

    if (RegisterClassExW(&class) == 0) return error.RegisterClassFailed;

    var title_buf: [256]u16 = undefined;
    const title = try std.unicode.utf8ToUtf16Le(&title_buf, options.title);
    title_buf[title.len] = 0;

    var state = WindowState{
        .webview_runtime_available = webview2.isRuntimeAvailable(),
    };

    const hwnd = CreateWindowExW(
        0,
        WNDCLASS_NAME,
        @ptrCast(title.ptr),
        WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        options.width,
        options.height,
        null,
        null,
        instance,
        &state,
    );

    if (hwnd == null) return error.CreateWindowFailed;

    _ = ShowWindow(hwnd, SW_SHOW);
    _ = UpdateWindow(hwnd);

    var msg: MSG = undefined;
    while (GetMessageW(&msg, null, 0, 0) > 0) {
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
}

fn windowProc(hwnd: HWND, message: UINT, wparam: WPARAM, lparam: LPARAM) callconv(WINAPI) LRESULT {
    switch (message) {
        WM_CREATE => {
            const create_struct: *const CREATESTRUCTW = @ptrFromInt(@as(usize, @bitCast(lparam)));
            _ = SetWindowLongPtrW(hwnd, GWLP_USERDATA, @intCast(@intFromPtr(create_struct.lpCreateParams)));
            return 0;
        },
        WM_PAINT => {
            paintWelcome(hwnd);
            return 0;
        },
        WM_SIZE => {
            return 0;
        },
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcW(hwnd, message, wparam, lparam),
    }
}

const CREATESTRUCTW = extern struct {
    lpCreateParams: ?*anyopaque,
    hInstance: HINSTANCE,
    hMenu: HMENU,
    hwndParent: HWND,
    cy: i32,
    cx: i32,
    y: i32,
    x: i32,
    style: i32,
    lpszName: ?[*:0]const u16,
    lpszClass: ?[*:0]const u16,
    dwExStyle: u32,
};

fn paintWelcome(hwnd: HWND) void {
    var ps: PAINTSTRUCT = undefined;
    const hdc = BeginPaint(hwnd, &ps);
    if (hdc == null) return;
    defer _ = EndPaint(hwnd, &ps);

    var rect: RECT = undefined;
    _ = GetClientRect(hwnd, &rect);

    const state_ptr: ?*WindowState = @ptrFromInt(@as(usize, @bitCast(GetWindowLongPtrW(hwnd, GWLP_USERDATA))));
    const runtime_message = if (state_ptr != null and state_ptr.?.webview_runtime_available)
        "WebView2 Runtime detected. Next step: create environment and controller."
    else
        "WebView2 Runtime was not detected. Install Microsoft Edge WebView2 Runtime before embedding pages.";

    var utf8_buf: [512]u8 = undefined;
    const text = std.fmt.bufPrint(
        &utf8_buf,
        "Leaf Browser\n\nZig + Win32 scaffold is running.\n{s}\n\nMVP tiếp theo: gắn CoreWebView2Controller vào cửa sổ này.",
        .{runtime_message},
    ) catch return;
    var utf16_buf: [512]u16 = undefined;
    const text16 = std.unicode.utf8ToUtf16Le(&utf16_buf, text) catch return;
    utf16_buf[text16.len] = 0;

    _ = DEFAULT_FONT;
    _ = DrawTextW(hdc, @ptrCast(utf16_buf[0..text16.len :0].ptr), -1, &rect, DT_LEFT | DT_TOP | DT_WORDBREAK);
}
