# Leaf-Browser

Browser tập trung vào hiệu năng tối đa, độ trễ thấp nhất và tiêu thụ tài nguyên ít nhất.

## Định hướng kỹ thuật

Leaf Browser sẽ được xây dựng bằng **Zig** trên Windows, tận dụng **Microsoft Edge WebView2 Runtime** có sẵn để giảm kích thước binary, thời gian phát triển và chi phí bảo trì engine render.

Xem kế hoạch triển khai chi tiết tại [`docs/zig-webview2-browser-plan.md`](docs/zig-webview2-browser-plan.md).
