const std = @import("std");
const windows = std.os.windows;
const WINAPI = windows.WINAPI;

const HMODULE = windows.HMODULE;
const HKEY = windows.HKEY;

const HKEY_CURRENT_USER: HKEY = @ptrFromInt(0x80000001);
const HKEY_LOCAL_MACHINE: HKEY = @ptrFromInt(0x80000002);
const KEY_READ: u32 = 0x20019;

const WEBVIEW2_CLIENT_DLL = std.unicode.utf8ToUtf16LeStringLiteral("WebView2Loader.dll");
const WEBVIEW2_RUNTIME_CLIENT_KEY = std.unicode.utf8ToUtf16LeStringLiteral("Software\\Microsoft\\EdgeUpdate\\Clients\\{F1A8DE63-421F-4D03-9D99-5E5E6D93580A}");

extern "kernel32" fn LoadLibraryW([*:0]const u16) callconv(WINAPI) ?HMODULE;
extern "kernel32" fn FreeLibrary(HMODULE) callconv(WINAPI) i32;
extern "advapi32" fn RegOpenKeyExW(HKEY, [*:0]const u16, u32, u32, *HKEY) callconv(WINAPI) i32;
extern "advapi32" fn RegCloseKey(HKEY) callconv(WINAPI) i32;

pub fn isRuntimeAvailable() bool {
    if (canLoadWebView2Loader()) return true;
    return hasRuntimeRegistration(HKEY_CURRENT_USER) or hasRuntimeRegistration(HKEY_LOCAL_MACHINE);
}

fn canLoadWebView2Loader() bool {
    const module = LoadLibraryW(WEBVIEW2_CLIENT_DLL) orelse return false;
    _ = FreeLibrary(module);
    return true;
}

fn hasRuntimeRegistration(root: HKEY) bool {
    var key: HKEY = undefined;
    if (RegOpenKeyExW(root, WEBVIEW2_RUNTIME_CLIENT_KEY, 0, KEY_READ, &key) != 0) return false;
    _ = RegCloseKey(key);
    return true;
}
