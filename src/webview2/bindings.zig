const std = @import("std");
const windows = std.os.windows;

pub const HRESULT = windows.HRESULT;
pub const HWND = windows.HWND;
pub const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

pub const COREWEBVIEW2_COLOR = extern struct {
    A: u8,
    R: u8,
    G: u8,
    B: u8,
};

pub const IUnknownVTable = extern struct {
    QueryInterface: *const fn (*anyopaque, *const windows.GUID, *?*anyopaque) callconv(windows.WINAPI) HRESULT,
    AddRef: *const fn (*anyopaque) callconv(windows.WINAPI) u32,
    Release: *const fn (*anyopaque) callconv(windows.WINAPI) u32,
};

pub const ICoreWebView2Environment = opaque {};
pub const ICoreWebView2Controller = opaque {};
pub const ICoreWebView2 = opaque {};

pub const ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler = opaque {};
pub const ICoreWebView2CreateCoreWebView2ControllerCompletedHandler = opaque {};

pub extern "WebView2Loader" fn CreateCoreWebView2EnvironmentWithOptions(
    browserExecutableFolder: ?[*:0]const u16,
    userDataFolder: ?[*:0]const u16,
    environmentOptions: ?*anyopaque,
    environmentCreatedHandler: *ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler,
) callconv(windows.WINAPI) HRESULT;
