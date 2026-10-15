# Web PWA

Preset `Web PWA` dùng Compatibility, GDScript, single-thread và không dùng GDExtension. Editor và export templates phải khớp Godot 4.7.2. Cần cả `web_nothreads_debug.zip` và `web_nothreads_release.zip`; có debug chưa đủ để chạy `make build`.

## Build và chạy local

```sh
make build
make serve
```

Mở `http://localhost:8080/index.html`. `make serve` phục vụ thư mục `build/web` ở cổng 8080; Ctrl+C dừng máy chủ. Build output không commit. Export trực tiếp trong Editor chưa chạy bước chuẩn hóa PWA; dùng `make build` hoặc chạy `python3 scripts/prepare_web_pwa.py build/web/index.html` sau export.

## Cache và cập nhật

`scripts/prepare_web_pwa.py` bổ sung `id`, `short_name`, `theme_color` vào manifest. Script chỉnh service worker do Godot export, giữ nguyên cơ chế đăng ký, update và xóa cache cũ. Danh sách precache gồm HTML, JavaScript, WASM, PCK, manifest, audio worklets, splash và icons. Worker chỉ cài thành công sau khi lưu đủ bộ tài nguyên; cache version là SHA-256 của tên/nội dung tài nguyên.

Lưu đủ bộ tránh trộn JavaScript cũ với WASM mới khi đổi build, đồng thời đưa splash/manifest vào cache offline. Điều hướng trong scope đọc entry HTML đã cache, kể cả đường dẫn gốc. Thay template Godot phải kiểm tra lại các mẫu service worker; script báo lỗi nếu không còn khớp. Script chạy lại được trên cùng output.

Người dùng cần tải online lần đầu và đợi service worker cài xong trước khi offline. Bản hiện tại khoảng 51 MiB chưa nén; cần kiểm tra quota và thời gian tải trên điện thoại thật. Trình duyệt có thể xóa cache khi thiếu dung lượng. Phiên bản mới chờ các client cũ đóng theo lifecycle service worker; đóng hết cửa sổ game rồi mở lại để nhận update. Phát hành toàn bộ thư mục build cùng lúc, tránh người chơi tải giữa lúc đang thay file.

## Font

Theme UI giữ font mặc định cho tiếng Việt và thêm Noto Sans Symbols cùng Symbols 2 làm fallback cho mũi tên, vòng tròn và ký hiệu nút. TouchSurface đọc font từ theme thay vì trực tiếp dùng ThemeDB. Nút chơi lại dùng chữ, không cần ký hiệu xoay vòng. Font và giấy phép nằm ở `assets/fonts/`; nguồn là Google Fonts: [Symbols](https://github.com/google/fonts/tree/main/ofl/notosanssymbols), [Symbols 2](https://github.com/google/fonts/tree/main/ofl/notosanssymbols2), giấy phép SIL Open Font License 1.1. Export filter bao gồm các file OFL cùng font.

## Hosting và thiết bị

Phát hành cần HTTPS; localhost là môi trường phát triển. Phục vụ `.wasm` với `application/wasm`, JS với MIME JavaScript và manifest với MIME JSON/manifest. Với tên file cố định hiện tại, cho phép revalidate HTML/service worker và tài nguyên build, không đặt cache immutable dài hạn. Có thể bật gzip/Brotli tại host. Bản single-thread này không yêu cầu bật COOP/COEP.

Chrome desktop đã kiểm tra cài và mở thành cửa sổ ứng dụng; Android/iOS cần xác nhận trên thiết bị thật. Khóa landscape trong manifest là yêu cầu với trình duyệt, không phải bảo đảm cho mọi nền tảng. Cảm ứng đa điểm, safe area, âm thanh và offline sau khi cài trên điện thoại cần kiểm tra riêng. Kết quả và giới hạn ở [QA Web](../qa/web-pwa.md).
