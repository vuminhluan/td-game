# Camera, viewport và input

`gd/main.gd` tạo `SubViewportContainer` cho chiến trường và một `Camera2D` trong `SubViewport`. `BattleView` và scene map nằm trong world space. HUD, màn hình chuẩn bị, pause và nút cảm ứng nằm ở Control của màn hình chính.

Camera theo player, không smoothing. Mỗi trục được clamp trong biên `dimensions × 40`; khi map nhỏ hơn vùng nhìn, trục đó được căn giữa. Zoom dựa trên chiều cao vùng chơi, giới hạn 0,55–1,25; map lớn cuộn theo player thay vì thu toàn map vào màn hình. Di chuyển player vẫn liên tục, không snap vào grid.

`world_to_screen()` và `screen_to_world()` dùng offset vùng chơi, tâm camera, kích thước pixel SubViewport và zoom. Test đối chiếu kết quả với `SubViewport.canvas_transform`, không chỉ kiểm tra hai hàm nghịch đảo. Các nút touch dùng screen space; nhiều ngón giữ di chuyển và bắn độc lập. Bàn phím dùng hướng vừa nhấn sau cùng. Pause, focus loss và thoát app về nền xóa input đang giữ.

Layout dùng viewport hiện tại và safe area của DisplayServer trên Android/iOS. Desktop lớn có sidebar/radar; landscape nhỏ giữ stats/HUD và đặt D-pad/fire ở cạnh dưới. Portrait được hỗ trợ như fallback khi resize cửa sổ native. Project đặt viewport mặc định 1280×720, hướng handheld `0` (`DisplayServer.SCREEN_LANDSCAPE`); giá trị cũ `1` là portrait. PWA dùng enum riêng: `progressive_web_app/orientation=1` là Landscape theo [khai báo export của Godot](https://github.com/godotengine/godot/blob/master/platform/web/export/export_plugin.cpp).

Map muốn chạy được chọn ở `map_scene` trên root scene chính trong Inspector. Chọn character/weapon hoặc chơi lại vẫn dùng scene đã chọn; simulation mới reset toàn bộ runtime map/pickup/loadout.

## Kiểm tra

`godot_tests/map_camera.gd` kiểm tra nhiều viewport từ 568×320 đến 1920×1080 và portrait fallback, map lớn/nhỏ, camera clamp/căn giữa, transform input, touch độc lập và cấu hình landscape. `godot_tests/map_camera_visual.gd` lưu screenshot native desktop/landscape/portrait dưới `/private/tmp/map-camera-*.png`.

Resize và sự kiện touch mô phỏng không xác nhận khóa landscape, notch/safe area hoặc touch thực trên thiết bị handheld. Lần refactor này đã kiểm tra native Compatibility trên macOS; Web export chưa chạy được vì thiếu template 4.7.2. Cần kiểm tra bản export trên thiết bị thực trước khi coi các tiêu chí thiết bị đã được xác nhận.
