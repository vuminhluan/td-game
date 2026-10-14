# Pickup và power-up

Pickup được đặt trong scene map, sinh định kỳ hoặc rơi khi phá terrain/object. `gd/pickup_settings.gd` định nghĩa Resource dùng chung tại `assets/maps/default_pickups.tres`; scene có thể dùng Resource riêng, object phá được có thể gán `drop_settings` riêng. Xem [biên soạn map](map/authoring.md).

## Mặc định và cấu hình

| Quy tắc | Giá trị |
| --- | --- |
| Rơi khi phá vật cản | Bật; 40% mỗi lần phá |
| Danh mục khi rơi ngẫu nhiên | 70% weapon, 30% power-up |
| Sinh định kỳ | Chỉ power-up; mỗi 5 giây thử sinh 1–2 món |
| Giới hạn power-up đang nằm trên map | 10, gồm đặt sẵn, sinh và rơi |
| Giới hạn weapon | Không giới hạn |
| Lifetime pickup | 20 giây từ khi xuất hiện |
| Trọng số không khai báo | 1 cho mỗi ID hợp lệ |

`power_up_pool`, `weapon_pool` và các dictionary trọng số điều khiển chọn loại. `weapon_pool` rỗng nghĩa là dùng tất cả weapon tương thích với character hiện tại; pool được lọc theo khả năng của character trước khi chọn. Pool không có weapon tương thích bỏ lần rơi weapon đó. Trọng số 0 loại một món khỏi lựa chọn; tổng trọng số của pool phải dương. `lifetime_overrides` ghi thời gian riêng theo ID power-up hoặc weapon. Các xác suất, khoảng sinh, giới hạn, pool và lifetime sai cấu hình được báo lỗi validation và ngăn bắt đầu trận.

Object có `pickup_id` cụ thể giữ nguyên món đó, kể cả weapon không tương thích; xác suất rơi vẫn áp dụng. Tắt `drop_enabled` trên cấu hình của object để ngăn rơi. Object nhiều ô có một HP chung và chỉ thử rơi một lần khi bị phá.

Sinh định kỳ chọn ô player đi tới được bằng flood fill, tránh căn cứ, actor và pickup khác; khoảng cách tối thiểu là 120 world units. Nếu hết ô hợp lệ hoặc đạt giới hạn thì bỏ lần sinh. Pickup rơi đặt tại tâm ô bị phá nếu vị trí đi được và không chồng pickup/căn cứ. Khi có chỗ trống, nhịp định kỳ sau có thể sinh trở lại.

## Nhặt và weapon

Player nhặt power-up trong bán kính 25 units; enemy chạm power-up làm món biến mất mà không được hiệu ứng. Enemy không nhặt weapon. Weapon không tương thích giữ trên map đến khi hết lifetime. Weapon tương thích thay weapon hiện tại ngay, cập nhật schedule, damage, muzzle và hình ảnh; hủy loạt chưa bắn của weapon cũ. Weapon mới giữ qua hồi sinh. Trận mới tạo simulation với loadout được chọn ở màn hình chuẩn bị.

Simulation giữ `power_ups`, `weapon_pickups` và `active_power_ups` riêng. Chỉ hai collection pickup tính lifetime; hiệu ứng giữ thời gian riêng. Pause dừng tất cả đồng hồ. Renderer đọc cùng runtime; HUD nằm trên màn hình và không di chuyển cùng camera.

## Hiệu ứng

| ID | Tác dụng trong 5 giây |
| --- | --- |
| `shield` | Chặn sát thương lên player |
| `base_shield` | Chặn sát thương lên căn cứ |
| `rapid_fire` | Giảm một nửa thời gian nghỉ sau loạt |
| `double_shot` | Nhân đôi số viên theo schedule của weapon |
| `speed_boost` | Tốc độ di chuyển ×1,5 |

Các hiệu ứng khác loại cùng hoạt động. Nhặt lại cùng loại làm mới về 5 giây; không cộng dồn hệ số. Hồi sinh giữ thời gian còn lại. Rapid Fire không đổi thời lượng loạt; Double Shot giữ lịch Gatling và cặp tên lửa theo [config nhân vật](character-selection.md). Mỗi viên va chạm độc lập. Config weapon vẫn nằm trong `config/player_characters.json`; hiệu ứng và khoảng nhặt/an toàn nằm trong `gd/rules.gd`.

HUD dùng icon và vòng countdown ở `gd/power_up_hud.gd`, hình vector ở `gd/power_up_icons.gd`. Weapon pickup dùng đúng sprite súng từ atlas nhân vật, thêm bóng và vòng sáng nhẹ; HUD cho biết weapon đang dùng. [Artwork pickup/object](map/environment-objects.md) mô tả cache và nguồn hình.

## Kiểm thử

`make test` chạy `godot_tests/power_ups.gd` cho hiệu ứng, pause, hồi sinh, loạt bắn và sinh vật phẩm; `godot_tests/map_refactor.gd` kiểm tra scene layout, validation, object nhiều ô, luật rơi, weapon compatibility, lifetime và giới hạn chung. `godot_tests/map_camera.gd` kiểm tra camera và UI nhiều tỉ lệ. Native rendering được kiểm tra bằng `make test-visual`; ảnh kiểm tra không thay thế kiểm thử trên thiết bị thật/Web export.
