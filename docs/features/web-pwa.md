# Web PWA

Preset `Web PWA` dùng Compatibility, GDScript, single-thread và không dùng GDExtension. Editor và export templates phải khớp Godot 4.7.2. Cần cả `web_nothreads_debug.zip` và `web_nothreads_release.zip`; có debug chưa đủ để chạy `make build`.

## Build và chạy local

```sh
make build
make serve
make test-web
```

Mở `http://localhost:8080/index.html`. `make serve` phục vụ thư mục `build/web` ở cổng 8080; Ctrl+C dừng máy chủ. Build output không commit. Export trực tiếp trong Editor chưa chạy bước chuẩn hóa PWA; dùng `make build` hoặc chạy `python3 scripts/prepare_web_pwa.py build/web/index.html` sau export. `make test-web` cần Godot, Python 3 và Node.js; kiểm tra layout/input mobile và co-op desktop, 19 profile thiết bị, đóng gói và lifecycle cache bằng các fixture độc lập.

## Giao diện điện thoại

Custom shell ở `web/shell.html`, `web/pwa.css`, `web/pwa.js` quản lý vùng canvas, loading, safe area, fullscreen và thông báo cập nhật. Touch được nhận diện bằng khả năng cảm ứng/pointer/UA của trình duyệt; Godot còn nhận `web_android` và `web_ios`. Chỉ kiểm tra feature `mobile` là không đủ cho Web.

Canvas render theo device pixel ratio có giới hạn, nhưng layout Godot dùng kích thước CSS logic. Vì vậy màn hình điện thoại có mật độ điểm ảnh cao vẫn hiện D-pad và nút bắn khi vào trận. Bộ điều khiển ẩn trong màn chọn map/nhân vật và khi pause.

Khi điện thoại/tablet ở chiều dọc, shell hiện hướng dẫn xoay ngang và chặn input game; trận đang chơi tự pause, xóa nút đang giữ. Xoay lại ngang rồi bấm tiếp tục. Nút Toàn màn hình yêu cầu fullscreen và thử khóa landscape sau thao tác người dùng. Nếu trình duyệt không hỗ trợ hoặc từ chối, trang hướng dẫn bật tự động xoay và xoay máy thủ công. Orientation trong manifest không bảo đảm tự xoay trong tab trình duyệt.

## Local Co-op trên desktop/laptop

Web/PWA cho phép [Local Co-op](local-coop.md) trên desktop/laptop. `web/pwa.js` gửi `localCoop` cùng metrics kích thước và touch tới Godot. Capability này độc lập với `touch`: Windows laptop cảm ứng vẫn dùng co-op nếu primary pointer là chuột/trackpad; thu nhỏ cửa sổ hoặc xoay dọc cửa sổ desktop không khóa chế độ hay hiện overlay xoay điện thoại.

Policy yêu cầu UA desktop được nhận diện (Windows/macOS/Linux/ChromeOS), không có UA/client hint mobile/tablet và không có primary pointer coarse. iPad mở desktop website dùng UA Macintosh được loại bằng multi-touch và platform, kể cả khi gắn chuột/keyboard. Android tablet không cần token Mobile vẫn bị chặn. Thiết bị chưa nhận diện và Web shell thiếu `localCoop` mặc định không được vào co-op. Native mobile cùng feature `web_android`/`web_ios` vẫn bị chặn trong Godot. Cả nút menu và callback triển khai đều dùng cùng kiểm tra.

Đây là policy nhận diện từ thông tin trình duyệt, không phải kiểm chứng phần cứng. Trình duyệt sửa/ẩn hoàn toàn UA và capability có thể không phân biệt được tablet với laptop; không có override bằng kích thước màn hình hoặc việc cắm bàn phím. Cơ sở: [WebKit về desktop browsing trên iPad](https://webkit.org/blog/9674/new-webkit-features-in-safari-13/), [maxTouchPoints](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/maxTouchPoints) và [giới hạn UA detection](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Browser_detection_using_the_user_agent).

## Cache và cập nhật

`scripts/prepare_web_pwa.py` bổ sung manifest và tạo bundle theo hash nội dung. JavaScript, WASM, PCK, CSS, audio worklets, splash và icons có tên riêng cho từng bản; HTML, manifest, worker và bản ghi `index.build.json` giữ tên ổn định. Việc này tránh trộn JavaScript cũ với WASM mới. Chạy lại script trên output đã chuẩn hóa sẽ kiểm tra checksum; nếu file đổi thì phải export lại.

`web/service-worker.js` chỉ kích hoạt khi tải đủ bundle và entry HTML khớp phiên bản. Điều hướng thử lấy HTML online với `no-store`, timeout 4 giây rồi dùng cache nếu mất mạng. Tài nguyên có hash đọc cache trước. Worker giữ hai cache phiên bản gần nhất để trang đang mở tiếp tục dùng tài nguyên cũ; cache Godot cũ được giữ cho quá trình chuyển đổi.

Trang kiểm tra cập nhật lúc mở, khi quay lại tab, khi có mạng và mỗi 60 giây khi đang hiển thị. Sau khi worker mới tải đủ bundle, trang hiện **Cập nhật**. Người chơi xác nhận rồi trang reload; trận hiện tại bắt đầu lại. Trang mới online dùng HTML mới ngay khi điều hướng. Lần chuyển từ shell Godot cũ chưa có giao thức cập nhật có thể reload một lần để chuyển sang shell mới; những lần sau không tự ngắt trận. Push source chưa thay đổi website: cần build/deploy thành công thì điện thoại mới nhận bản mới.

Người dùng cần tải online lần đầu và đợi worker cài xong trước khi offline. Bản hiện tại khoảng 51 MiB chưa nén; trình duyệt có thể xóa cache khi thiếu dung lượng. Phát hành toàn bộ thư mục build cùng lúc, tránh tải giữa lúc đang thay file. Nếu một bản mới tải thiếu, worker cũ tiếp tục hoạt động và lần kiểm tra sau thử lại.

## Font

Theme UI giữ font mặc định cho tiếng Việt và thêm Noto Sans Symbols cùng Symbols 2 làm fallback cho mũi tên, vòng tròn và ký hiệu nút. TouchSurface đọc font từ theme thay vì trực tiếp dùng ThemeDB. Nút chơi lại dùng chữ. Font và giấy phép nằm ở `assets/fonts/`; nguồn: [Symbols](https://github.com/google/fonts/tree/main/ofl/notosanssymbols), [Symbols 2](https://github.com/google/fonts/tree/main/ofl/notosanssymbols2), giấy phép SIL Open Font License 1.1. Export filter bao gồm các file OFL cùng font.

## Hosting và thiết bị

Workflow `.github/workflows/deploy-pages.yml` chỉ chạy khi chọn `Actions → Deploy Web PWA → Run workflow`; push source không tự phát hành. Chọn `Settings → Pages → Build and deployment → Source: GitHub Actions` một lần. Workflow tải Godot 4.7.2 Linux và template release chính thức, cache công cụ, chạy import/test/test-web/build rồi upload riêng `build/web` và deploy. Quyền ghi Pages và OIDC chỉ cấp cho job deploy.

URL của repo là [Robot Defense](https://vuminhluan.github.io/td-game/). Mở bằng Chrome Android/Safari iPhone, chơi online, cài từ menu trình duyệt/Share → Add to Home Screen, chờ cache cài xong rồi thử offline. Sau mỗi bản deploy, mở lại link khi online hoặc chờ nút Cập nhật nếu đang mở game.

Phát hành cần HTTPS; localhost là môi trường phát triển. Phục vụ WASM với `application/wasm`, JS với MIME JavaScript và manifest với MIME JSON/manifest. HTML, manifest, worker và `index.build.json` cần revalidate; chỉ các file có hash mới phù hợp cache immutable. Có thể bật gzip/Brotli. Bản single-thread không yêu cầu COOP/COEP.

Chrome desktop đã kiểm tra cài và mở thành cửa sổ ứng dụng; Android/iOS cần xác nhận trên thiết bị thật. Cảm ứng đa điểm, safe area, âm thanh và offline sau khi cài trên điện thoại cần kiểm tra riêng. Kết quả và giới hạn ở [QA Web](../qa/web-pwa.md).
