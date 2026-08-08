# Leaf-Browser

Browser tập trung vào hiệu năng tối đa, độ trễ thấp nhất và tiêu thụ tài nguyên ít nhất.

## Định hướng kỹ thuật

Leaf Browser được xây dựng bằng **Zig** trên Windows, tận dụng **Microsoft Edge WebView2 Runtime** có sẵn để giảm kích thước binary, thời gian phát triển và chi phí bảo trì engine render.

Xem kế hoạch triển khai chi tiết tại [`docs/zig-webview2-browser-plan.md`](docs/zig-webview2-browser-plan.md).

## Trạng thái hiện tại

Repository đã có scaffold Zig ban đầu:

- `build.zig` định nghĩa executable `leaf-browser`, lệnh `zig build run` và `zig build test`.
- `src/main.zig` là entrypoint, hiện chỉ chạy app trên Windows vì engine mục tiêu là Edge WebView2.
- `src/platform/window.zig` tạo cửa sổ Win32 native và hiển thị trạng thái phát hiện WebView2 Runtime.
- `src/webview2/runtime.zig` kiểm tra WebView2 Runtime bằng `WebView2Loader.dll` và registry EdgeUpdate.
- `src/browser/url.zig` chuẩn hóa input thanh địa chỉ thành URL hoặc query tìm kiếm.

## Build và chạy

Yêu cầu:

- Windows x64.
- Zig đã được cài và có trong `PATH`.
- Microsoft Edge WebView2 Runtime.

Lệnh thường dùng:

```powershell
zig build
zig build run
zig build test
```

> Lưu ý: môi trường Linux/macOS hiện chỉ có thể đọc mã nguồn; app GUI cần Windows để build/chạy đúng với Win32 và WebView2.
