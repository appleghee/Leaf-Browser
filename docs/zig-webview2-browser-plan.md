# Kế hoạch xây dựng Leaf Browser bằng Zig và Microsoft Edge WebView2

## 1. Mục tiêu sản phẩm

Leaf Browser là trình duyệt Windows tối giản, ưu tiên:

- **Độ trễ thấp**: khởi động nhanh, phản hồi UI mượt, thao tác điều hướng tức thời.
- **Tài nguyên thấp**: dùng WebView2 Runtime có sẵn trên Windows thay vì tự nhúng Chromium đầy đủ.
- **Kích thước nhỏ**: binary Zig gọn, ít phụ thuộc ngoài.
- **Tích hợp Windows tốt**: dùng Win32 API trực tiếp, WebView2, clipboard, theme, shortcut hệ thống.
- **Dễ mở rộng**: kiến trúc module rõ để bổ sung tab, bookmark, download, history, extension-like features.

## 2. Phạm vi phiên bản đầu tiên

### Có trong MVP

- Cửa sổ Win32 chính.
- Nhúng Edge WebView2 trong vùng nội dung.
- Thanh địa chỉ đơn giản.
- Nút Back, Forward, Reload, Stop.
- Điều hướng URL và tìm kiếm mặc định khi nhập không phải URL.
- Hiển thị tiêu đề trang trên title bar.
- Cập nhật trạng thái tải trang.
- Lưu cấu hình tối thiểu vào thư mục dữ liệu người dùng.
- Build bằng Zig trên Windows x64.

### Chưa có trong MVP

- Multi-tab hoàn chỉnh.
- Extension API.
- Đồng bộ tài khoản.
- DevTools UI tùy biến.
- Trình quản lý download nâng cao.
- Profile/multi-user phức tạp.
- Chặn quảng cáo tích hợp sâu.

## 3. Kiến trúc tổng quan

```text
Leaf Browser
├── App bootstrap
│   ├── parse CLI args
│   ├── init COM apartment
│   ├── load config
│   └── create main window
├── Platform layer
│   ├── Win32 window procedure
│   ├── DPI awareness
│   ├── message loop
│   └── native controls
├── WebView layer
│   ├── WebView2 environment
│   ├── controller lifecycle
│   ├── navigation APIs
│   └── WebView2 event handlers
├── Browser state
│   ├── current URL
│   ├── canGoBack / canGoForward
│   ├── loading state
│   └── page title
├── UI layer
│   ├── toolbar
│   ├── address bar
│   └── status/progress indicator
└── Persistence
    ├── settings
    ├── history
    └── session restore
```

## 4. Công nghệ chính

- **Zig**: ngôn ngữ chính, build system chính.
- **Win32 API**: tạo cửa sổ, toolbar, message loop, DPI, menu, accelerator.
- **COM**: gọi WebView2 qua COM interfaces.
- **Microsoft Edge WebView2 Runtime**: engine render web có sẵn trên nhiều bản Windows hiện đại.
- **WebView2 SDK headers/interfaces**: cần binding Zig cho các interface COM quan trọng.

## 5. Chiến lược binding WebView2 trong Zig

Có 2 hướng triển khai:

### Hướng A: Binding thủ công tối thiểu cho MVP

Tạo các struct Zig mô tả vtable COM cần dùng:

- `ICoreWebView2Environment`
- `ICoreWebView2Controller`
- `ICoreWebView2`
- `ICoreWebView2Settings`
- completion handlers cho tạo environment/controller
- event handlers cho navigation/title/source changed

Ưu điểm:

- Kiểm soát tốt kích thước code.
- Dễ tối ưu cho MVP.
- Không phụ thuộc generator phức tạp.

Nhược điểm:

- Dễ sai ABI nếu khai báo interface không khớp.
- Cần kiểm tra kỹ calling convention, GUID và lifetime COM.

### Hướng B: Generate binding từ WebView2 IDL/C headers

Dùng tooling để sinh phần lớn COM declarations, sau đó chỉ viết wrapper Zig cấp cao.

Ưu điểm:

- Bao phủ API rộng hơn.
- Ít lỗi thiếu method khi mở rộng.

Nhược điểm:

- Tốn thời gian dựng generator.
- Binding sinh ra có thể lớn và khó đọc.

### Khuyến nghị

Bắt đầu bằng **Hướng A** cho MVP, nhưng tổ chức file để có thể thay bằng generator sau này.

## 6. Cấu trúc thư mục đề xuất

```text
src/
├── main.zig
├── app.zig
├── platform/
│   ├── win32.zig
│   ├── window.zig
│   └── dpi.zig
├── webview2/
│   ├── bindings.zig
│   ├── environment.zig
│   ├── controller.zig
│   └── events.zig
├── browser/
│   ├── state.zig
│   ├── navigation.zig
│   └── url.zig
├── ui/
│   ├── toolbar.zig
│   ├── address_bar.zig
│   └── layout.zig
└── storage/
    ├── config.zig
    ├── history.zig
    └── paths.zig
```

## 7. Các mốc triển khai

### Milestone 0: Khởi tạo nền tảng Zig

- Tạo `build.zig`.
- Tạo `src/main.zig` chạy được trên Windows x64.
- Bật subsystem Windows khi build release, giữ console ở debug nếu cần log.
- Thiết lập formatter/linter cơ bản.

Kết quả mong đợi: chạy app rỗng và thoát sạch.

### Milestone 1: Cửa sổ Win32

- Đăng ký window class.
- Tạo main window.
- Thiết lập DPI awareness.
- Viết message loop.
- Xử lý resize, close, destroy.

Kết quả mong đợi: mở cửa sổ native ổn định.

### Milestone 2: Nhúng WebView2

- Khởi tạo COM bằng `CoInitializeEx`.
- Gọi `CreateCoreWebView2EnvironmentWithOptions`.
- Tạo `CoreWebView2Controller` gắn với HWND chính.
- Resize controller theo client area.
- Điều hướng tới trang mặc định.

Kết quả mong đợi: hiển thị được trang web trong cửa sổ.

### Milestone 3: Thanh điều hướng tối thiểu

- Tạo toolbar native phía trên.
- Thêm edit control làm address bar.
- Xử lý Enter để navigate.
- Chuẩn hóa input: URL hợp lệ hoặc query tìm kiếm.
- Thêm Back, Forward, Reload, Stop.

Kết quả mong đợi: dùng được như browser một tab cơ bản.

### Milestone 4: Đồng bộ trạng thái trang

- Lắng nghe navigation starting/completed.
- Lắng nghe source changed để cập nhật address bar.
- Lắng nghe document title changed để cập nhật title bar.
- Cập nhật enabled/disabled cho Back và Forward.

Kết quả mong đợi: UI phản ánh đúng trạng thái WebView.

### Milestone 5: Cấu hình và dữ liệu người dùng

- Xác định thư mục dữ liệu: `%LOCALAPPDATA%\LeafBrowser`.
- Lưu homepage, search engine, window size.
- Tách thư mục WebView2 user data theo profile mặc định.
- Chuẩn bị storage cho history/bookmark.

Kết quả mong đợi: app nhớ cấu hình qua lần chạy sau.

### Milestone 6: Đóng gói và phân phối

- Build release x64.
- Kiểm tra máy có WebView2 Runtime.
- Nếu thiếu runtime, hiển thị hướng dẫn cài đặt rõ ràng.
- Chuẩn bị script tạo archive hoặc installer.

Kết quả mong đợi: bản phát hành chạy được trên Windows sạch có WebView2 Runtime.

## 8. Rủi ro kỹ thuật và cách giảm thiểu

| Rủi ro | Tác động | Giảm thiểu |
| --- | --- | --- |
| Sai khai báo COM ABI | Crash hoặc hành vi không ổn định | Viết binding tối thiểu, test từng interface, đối chiếu WebView2 headers |
| WebView2 Runtime không tồn tại | Không mở được trình duyệt | Kiểm tra runtime lúc khởi động và báo lỗi thân thiện |
| Event handler lifetime sai | Use-after-free hoặc leak | Quản lý ref count rõ ràng, gom handler vào allocator/lifecycle của app |
| UI native khó mở rộng | Toolbar/tab khó tùy biến | Tách UI layer sớm, cân nhắc custom-draw sau MVP |
| Zig Windows bindings thay đổi | Build lỗi khi nâng Zig | Pin phiên bản Zig trong tài liệu và CI |

## 9. Nguyên tắc hiệu năng

- Không tạo WebView mới khi không cần thiết.
- Tránh allocation trong hot path của message loop.
- Cache chuỗi UTF-16 thường dùng cho Win32/WebView2.
- Chỉ cập nhật UI khi state thay đổi.
- Đo thời gian khởi động từ `main` tới `NavigationCompleted` đầu tiên.
- Theo dõi memory bằng Windows Performance Analyzer hoặc Task Manager trong các mốc release.

## 10. Kiểm thử đề xuất

- Unit test cho parser URL/query.
- Smoke test build debug/release trên Windows x64.
- Manual test navigation: URL HTTP, HTTPS, localhost, query search.
- Manual test lifecycle: mở, resize, minimize, close.
- Manual test thiếu WebView2 Runtime nếu có môi trường phù hợp.
- Regression checklist trước release: back/forward, reload/stop, title, address bar, session config.

## 11. Lộ trình sau MVP

- Multi-tab với mỗi tab là một WebView2 controller riêng hoặc pool controller.
- Bookmark manager.
- History search.
- Download shelf đơn giản.
- Private window với user data folder tạm thời.
- Basic content blocking bằng WebView2 request interception.
- Command palette.
- Crash recovery/session restore.
