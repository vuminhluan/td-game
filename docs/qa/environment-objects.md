# QA object môi trường và weapon pickup — 2026-10-13

Phạm vi và quyết định đã chốt nằm ở [object môi trường](../features/map/environment-objects.md). Đã thay SVG placeholder bằng bốn artwork PNG alpha dùng ImageGen tích hợp: machinery, pipes, robot wreck, drink can. Không tạo sprite weapon mới: pickup lấy trực tiếp sprite súng trong atlas character hiện hành.

Kết quả bên dưới ghi nhận lần thêm catalog/artwork ban đầu. Thiết kế layout tiếp theo giảm mật độ và bỏ grass khỏi scene, có kết quả mới trong [QA bố cục nhà máy](industrial-layout.md).

## Kiểm thử

Godot 4.7.2, renderer Compatibility, macOS Apple M4 Pro. Import cuối hoàn thành không có script/resource error. `make test` pass tất cả suite với **2417 checks có bộ đếm**, cùng player mech integration và 56 atlas frames. `make test-visual` pass cả **9 suite**; native environment có **13 checks**, camera có **82 checks**, các kiểm tra rendering còn lại không có failures.

`godot_tests/environment_objects.gd` thêm 93 checks:

- Catalog tham chiếu cùng Resource canonical mà scene instance sử dụng; texture có alpha, source region hợp lệ, giữ aspect ratio.
- Object công nghiệp được pack vào scene có ID `city_prototype`, khởi tạo và chơi hợp lệ; không có kiểm tra hay giới hạn theo theme.
- Lon không có footprint gameplay và không chặn di chuyển/đạn. Ống chặn di chuyển nhưng cho đạn đi qua. Máy và robot chặn cả hai.
- Damage 1000 và damage được phép phá thép không phá các object cố định; HP/flags của Resource shared không bị runtime sửa.
- Map mẫu có 8 vật cản dọc hai biên và 6 lon, player spawn hợp lệ và ba enemy spawn vẫn có đường tới base.
- Pickup của cả 7 binding character/weapon dùng cùng atlas và pixels chính xác với sprite súng trang bị. Texture được cache; weapon không tương thích vẫn hiển thị art của character hỗ trợ nó.

`godot_tests/environment_objects_visual.gd` chụp game thật, so sánh vùng ảnh khi ẩn từng loại object và bỏ weapon pickup; xác nhận các sprite thực sự được compositing lên terrain. Ảnh lưu ở [industrial-objects-in-game.png](../images/industrial-objects-in-game.png). Fixture dùng zoom 0,75 để thấy toàn map và cả hai biên.

Đã xem screenshot full-map và landscape 844×390. Machinery/pipes/wreck có chi tiết vật liệu đồng bộ với terrain cũ, lon nhỏ phân biệt với pickup, weapon có silhouette đúng atlas. HUD và nút cảm ứng giữ vị trí màn hình. Camera giữ behavior cuộn/căn giữa của refactor trước.

Đã kiểm tra riêng installer với Resource máy có footprint/visual rect/flags tùy chỉnh và một entry catalog gắn tag `city`: tái xuất giữ cả chỉnh sửa designer và entry chủ đề khác. Các file fixture đã được xóa và artifact gốc khôi phục sau kiểm tra.

## Nguồn, fingerprint và dọn placeholder

Manifest ở `assets/map_objects/industrial/manifest.json` ghi runtime texture, Resource, raw source, prompt và SHA-256. Runtime PNG khớp byte với nguồn generation giữ dưới `assets/generated/map/industrial/objects/`. PNG gốc/alpha không bị xử lý lại; AtlasTexture chỉ chọn vùng hiển thị. Prompts và request.json ghi tool built-in, references và yêu cầu transparent.

Đã kiểm tra tham chiếu code/scene/resource/script/docs trước khi xóa `assets/maps/industrial/{machinery,pipes,crates}.svg` và các `.import` của placeholder. Bộ terrain PNG/atlas và nguồn generation cũ vẫn được giữ vì runtime đang dùng. `git diff --check` và kiểm tra link Markdown nội bộ pass.

## Giới hạn

Các kiểm tra này xác nhận gameplay và native rendering. Không kiểm tra lại browser/PWA hoặc handheld thật; các giới hạn export/device của [QA refactor map](map-refactor.md) vẫn áp dụng. Geometry gameplay là footprint khai báo, không suy ra từ alpha; designer có thể điều chỉnh Resource cho artwork khác hoặc vị trí khác.
