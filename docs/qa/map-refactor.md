# QA refactor map — 2026-10-13

Đã triển khai [phạm vi refactor](../features/map/refactor-plan.md) với scene `scenes/maps/industrial_yard.tscn`. Scene là nguồn layout duy nhất; không còn layout procedural, kích thước map hoặc tọa độ base/spawn toàn cục. Hướng dẫn chỉnh map ở [authoring](../features/map/authoring.md), camera/HUD ở [camera](../features/map/camera.md), cấu hình pickup ở [power-ups](../features/power-ups.md).

Kết quả bên dưới ghi nhận refactor ban đầu. Bản cập nhật artwork/object tiếp theo được kiểm tra riêng trong [QA object môi trường](environment-objects.md), gồm tổng checks hiện hành của `make test`.

## Kiểm thử tự động

Máy kiểm tra dùng Godot `4.7.2.stable.official.ed1daf0bf`, macOS Apple M4 Pro và renderer Compatibility. Lệnh `make test` hoàn thành với 0 failures, không có script/runtime error trong log chạy cuối. Các bài có bộ đếm tổng cộng **2324 checks**:

| Suite | Checks |
| --- | ---: |
| Map refactor | 118 |
| Camera/input/map selection | 298 |
| Character selection | 914 |
| Player loadout | 392 |
| Power-ups | 39 |
| Acceptance | 234 |
| Enemy sprites | 305 |
| Map art | 24 |

Player mech integration cũng pass: 56 atlas frames, hướng độc lập, moving fire, va chạm nòng dài, recoil, pause, damage, hồi sinh và chơi lại. Suite này không in số assertion nên không được cộng vào tổng trên.

Map refactor test dùng scene fixture thực, chỉnh TileSet custom data, node marker/object và pack thành PackedScene trước khi tạo simulation. Kiểm tra kích thước khác nhau, fallback player, spawn luân phiên, terrain custom với flags độc lập, footprint nhiều ô/shared HP, trang trí không collision/pathfinding, damage đúng object/underlay, object bullet-transparent không được AI coi là có thể phá, cấu hình sai và kích thước quá lớn, scene root sai, base lệch tâm ô vẫn bị địch tấn công, pickup lifetime/pool/trọng số/giới hạn, random compatibility và explicit incompatible weapon, weapon giữ qua respawn và reset ở trận mới. Settings được clone riêng cho mỗi trận.

Camera test kiểm tra map lớn/nhỏ, clamp/căn giữa, đổi viewport, screen/world mapping đối chiếu transform thực, đa điểm chạm, landscape config và giữ scene map đã chọn khi đổi loadout/chơi lại.

## Native rendering

`make test-visual` chạy đủ 8 suite, tất cả pass. `map_camera_visual.gd` có **82 checks**, tạo 4 screenshot ở `/private/tmp/map-camera-{desktop,mobile,small,portrait}.png`: desktop 1280×720, landscape 844×390 và 568×320, portrait fallback 375×667. Đã xem ảnh landscape và full-map; HUD không theo camera, stats/nút nằm trong viewport và decoration công nghiệp hiện đúng.

Map visual so sánh pixels qua ba mức HP gạch/phá gạch, phá base và chơi lại; 0 failures. [Map toàn cảnh](../images/map-art-in-game.png) và [map hư hại](../images/map-art-damage.png) dùng zoom 0,75 trong fixture để thấy cả map; game bình thường dùng camera theo player. Các suite native còn lại kiểm tra chuẩn bị/character/loadout, power-up, pause/mobile, player và enemy sprite. Ảnh tài liệu liên quan được cập nhật từ renderer mới.

`git diff --check` và kiểm tra đường dẫn Markdown nội bộ pass. Nguồn artwork cũ vẫn được giữ vì atlas TileSet và overlay đang dùng; script tái tạo atlas nằm trong `assets/maps/industrial/source/`.

## Giới hạn còn lại

Đã thử export `Web PWA`; Godot báo thiếu `web_nothreads_debug.zip` và `web_nothreads_release.zip` cho 4.7.2. Không có Web build để xác nhận browser/PWA/offline/touch. Không cài template hoặc thay môi trường máy trong lần refactor.

Handheld đã sửa hướng native từ `1` (portrait) sang `0` (landscape), PWA giữ enum riêng `1` (landscape). Chưa xác nhận orientation lock, safe area/notch hoặc touch trên bản export chạy ở thiết bị thật. Sự kiện touch và resize native chỉ xác nhận code/UI. Chế độ tấn công và streaming/chunk cho vùng đất cực lớn chưa được triển khai.
