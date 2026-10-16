# Camera, viewport và input

`gd/main.gd` tạo `SubViewportContainer` cho chiến trường và một `Camera2D` trong `SubViewport`. `BattleView` và scene map nằm trong world space. HUD, màn hình chuẩn bị, pause và nút cảm ứng nằm ở Control của màn hình chính.

Desktop thu toàn bộ map vào vùng chiến trường bằng tỷ lệ nhỏ hơn giữa chiều rộng và chiều cao viewport so với `dimensions × 40`, giới hạn phóng lớn 1,25. Zoom được tính lại trong `update_camera()` từ dimensions hiện tại, nên chọn map, đổi loadout, replay và resize luôn dùng đúng kích thước map mà không cần điều kiện theo map ID.

Mobile giữ zoom theo chiều cao vùng chơi, giới hạn 0,55–1,25, để nhân vật vẫn đủ lớn trên landscape. Camera theo player, không smoothing; mỗi trục được clamp trong biên world và căn giữa khi map nhỏ hơn vùng nhìn. Map đường phố cao hơn viewport cuộn dọc theo vị trí player. Di chuyển player vẫn liên tục, không snap vào grid.

`world_to_screen()` và `screen_to_world()` dùng offset vùng chơi, tâm camera, kích thước pixel SubViewport và zoom. Test đối chiếu kết quả với `SubViewport.canvas_transform`, không chỉ kiểm tra hai hàm nghịch đảo. Các nút touch dùng screen space; nhiều ngón giữ di chuyển và bắn độc lập. Bàn phím dùng hướng vừa nhấn sau cùng. Pause, focus loss và thoát app về nền xóa input đang giữ.

Layout dùng viewport hiện tại và safe area của DisplayServer trên Android/iOS. Desktop lớn có sidebar/radar; landscape nhỏ giữ stats/HUD và đặt D-pad/fire ở cạnh dưới. Portrait được hỗ trợ như fallback khi resize cửa sổ native. Project đặt viewport mặc định 1280×720, hướng handheld `0` (`DisplayServer.SCREEN_LANDSCAPE`); giá trị cũ `1` là portrait. PWA dùng enum riêng: `progressive_web_app/orientation=1` là Landscape theo [khai báo export của Godot](https://github.com/godotengine/godot/blob/master/platform/web/export/export_plugin.cpp).

Màn chọn map lấy scenes từ `Main.available_maps`; `map_scene` trên root scene chính là lựa chọn ban đầu. Sau khi xác nhận map, game mở màn chọn character/weapon. Chọn character/weapon hoặc chơi lại vẫn dùng scene đã chọn; simulation mới reset toàn bộ runtime map/pickup/loadout.

## Kiểm tra

`godot_tests/map_camera.gd` kiểm tra nhiều viewport từ 568×320 đến 1920×1080 và portrait fallback, map lớn/nhỏ, desktop fit toàn map, landscape cuộn dọc, camera clamp/căn giữa, transform input, touch độc lập và cấu hình landscape. `godot_tests/map_camera_visual.gd` lưu screenshot native desktop/landscape/portrait dưới `/private/tmp/map-camera-*.png`.

Resize và sự kiện touch mô phỏng không xác nhận khóa landscape, notch/safe area hoặc touch thực trên thiết bị handheld. Các lần kiểm tra đã ghi nhận native Compatibility trên macOS; Web export trước đó bị chặn vì thiếu template 4.7.2, chưa có kết quả browser/PWA trong [QA map](../../qa/maps.md#limitations). Cần kiểm tra bản export trên thiết bị thực trước khi coi các tiêu chí thiết bị đã được xác nhận.

## Local Co-op

Desktop co-op (native và Web/PWA) dùng hai viewport/camera trên cùng World2D; battlefield chia trái/phải khi landscape và trên/dưới khi portrait. Mỗi camera follow player tương ứng với zoom theo chiều cao viewport, giới hạn 0,65–1,25; clamp/căn giữa từng trục theo biên map. Mỗi viewport có HUD HP/mạng/weapon/power-up riêng, còn thông tin chiến dịch dùng chung. Screen/world conversion nhận index player. Kích thước cửa sổ nhỏ không bật touch controls trong co-op. Luật và API ở [Local Co-op](../local-coop.md).
