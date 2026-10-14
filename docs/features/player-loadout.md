# Resource Body, Weapon và Loadout

Gameplay hiện hành tạo loadout từ `config/player_characters.json`, với hai nhân vật, Body sạch và bảy cấu hình vũ khí. Thông số và luồng chọn trước trận ở [Chọn nhân vật](character-selection.md); artwork ở [Artwork nhân vật](../assets/characters.md).

## Trách nhiệm và geometry

- `gd/player_skin.gd`: SpriteFrames, hướng, anchor, scale và socket của Body. `gd/character_art.gd` mở rộng resource này cho atlas tách lớp hiện hành.
- `gd/player_weapon.gd`: artwork vũ khí, tọa độ nòng, damage, tốc độ đạn, thời lượng recoil, thời gian nghỉ và schedule `{time, barrels}`.
- `gd/player_loadout.gd`: liên kết Body/Weapon/socket, HP, tốc độ di chuyển và collider; cung cấp geometry trước khi simulation khởi tạo.
- `gd/character_catalog.gd`: đọc/kiểm tra config và chuyển metadata artwork thành các resource.
- `gd/simulation.gd`: sở hữu cooldown, hàng đợi bắn, khóa di chuyển, va chạm và sát thương. Simulation độc lập dùng cùng config mặc định; view không cấp geometry player.
- `gd/battle_view.gd`: nhận Body từ `sim.loadout`, ghép vũ khí tại socket và vẽ hiệu ứng. Preview chọn nhân vật dùng cùng renderer.

Socket lưu theo pixel ảnh gốc và được đổi thành world offset bằng `(socket - body_anchor) * body_scale`. Với config hiện hành, tọa độ nòng là world units từ tâm actor; catalog trừ socket để tạo `weapon.explicit_muzzles`. Loadout cộng lại socket khi cung cấp geometry cho simulation. Mỗi nòng có tọa độ riêng ở đủ bốn hướng; anchor/scale artwork vũ khí độc lập với Body.

Resource không có `explicit_muzzles` dùng `body.socket_for(...) + weapon.muzzle_offsets[direction] + lateral * barrel_offset`. `lateral` vuông góc hướng bắn. Override `player_muzzle_distances` chỉ dịch chiều dài chung, giữ offset tương đối giữa các nòng. Collider không phụ thuộc alpha hoặc vùng artwork.

Mỗi viên được trace riêng từ trục collider tới đầu nòng rồi qua đường bay. Một nòng bị chặn không hủy nòng còn lại. Các viên xử lý tuần tự: viên sau kiểm tra trạng thái tường/địch đã cập nhật từ viên trước; score chỉ tính một lần cho mỗi địch.

## Fixture atlas player-mech

`assets/loadouts/{standard,twin}.tres` và `assets/weapons/{standard,twin}.tres` còn được các test và preview load trực tiếp. Cả hai dùng [atlas player-mech](../assets/player-mech.md), đồng thời atlas này là reference cho artwork nhân vật hiện hành. Đây là resource fixture đang dùng, không phải hai lựa chọn mặc định trên màn hình chính.

| Fixture | Viên cơ bản | Thời gian nghỉ | Damage/viên | Tốc độ đạn |
| --- | --- | --- | --- | --- |
| `standard.tres` | 1 | 0,4 giây | 1 | 410 units/giây |
| `twin.tres` | 2 đồng thời, lệch ngang ±4 units | 0,6 giây | 1 | 410 units/giây |

Các fixture này tách Body và nòng theo vùng atlas: `weapon_cutouts` loại hình súng khỏi thân, `cutouts` lấy hình súng, và `mount_rects` vẽ giáp tại socket. `gd/sprite_regions.gd` trừ các vùng để không cắt hoặc nhân đôi giáp giữa nòng và flash. Cả hai lớp giữ 56 frame (bốn hướng × idle/walk/attack). Gameplay hiện hành dùng Body hoàn chỉnh và `weapon.layered_art`, bỏ qua nhánh cắt vùng/giáp bù này.

Thời lượng animation attack mặc định của `PlayerWeapon` là 0,23 giây, độc lập thời gian nghỉ. Double Shot của fixture lặp loạt sau 0,08 giây; Rapid Fire chia đôi thời gian nghỉ. Các invariant về pause, chết/hồi sinh và khóa loạt dùng chung simulation với loadout hiện hành.

## Kiểm tra

`godot_tests/player_loadout.gd` kiểm tra fixture, bốn hướng, frame, geometry, một nòng bị chặn, sát thương, power-up, pause và hồi sinh. `godot_tests/character_selection.gd` kiểm tra bảy loadout từ config và luồng chính. Cả hai chạy trong `make test`.

`godot_tests/player_loadout_visual.gd` chụp màn hình chuẩn bị của game hiện hành và board fixture 24 ô. Các ảnh dưới có phạm vi khác nhau; chúng được cập nhật bởi `make test-visual`.

![Màn hình chuẩn bị hiện hành](../images/character-selection-desktop.png)

![Board hai resource fixture](../images/player-loadout-directions.png)

Khi thêm Body/vũ khí, giữ hợp đồng socket/geometry và bổ sung cấu hình, artwork, validation cùng QA cho các hướng mới. Projectile hiện bay thẳng; hành vi khác cần được triển khai và kiểm tra trong simulation.
