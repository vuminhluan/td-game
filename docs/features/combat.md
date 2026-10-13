# Bắn và va chạm đạn

`gd/simulation.gd` sở hữu cooldown, tạo đạn, va chạm và sát thương. Loadout player cung cấp geometry và cấu hình súng; skin enemy cung cấp geometry nòng; luật sát thương không phụ thuộc alpha của sprite.

## Nòng súng theo hướng

Constructor simulation hợp nhất socket thân và offset nòng của weapon từ loadout, kể cả khi chạy độc lập. `BattleView.sim` cấp khoảng cách nòng của từng loại enemy; enemy không có skin dùng 20 world units. Player có thể override chiều dài qua `player_muzzle_distances`, giữ offset ngang riêng cho từng nòng. Chi tiết ở [Loadout người chơi](player-loadout.md).

Với player, `emit_projectile()` kiểm tra từ trục tâm collider theo offset ngang từng nòng tới đầu nòng. Enemy giữ baseline 20 units, quét phần nòng dài hơn baseline. Bước quét tối đa 2 world units, gồm điểm cuối. Điểm sinh đạn luôn được kiểm tra, kể cả khi nòng không dài hơn baseline. Đạn bị chặn ngay nếu đoạn này gặp vật cản hoặc mục tiêu hợp lệ. Điều này tránh trường hợp đầu nòng nằm trong hoặc vượt qua tường khiến viên đạn sinh ra phía bên kia và bỏ qua tường; tương tự với mục tiêu đứng sát.

## Di chuyển đạn

Mỗi lần update, quãng đường đạn được chia thành `ceil(bullet.speed * dt / 5)` bước, ít nhất một bước. Mỗi bước dài tối đa 5 world units và kiểm tra va chạm ngay sau khi di chuyển, tránh xuyên qua tile hoặc actor giữa hai frame.

## Kiểm tra khi thay skin hoặc sửa collision

- `godot_tests/player_mech_asset.gd`: nòng dài gặp gạch/thép hoặc enemy đứng sát phải va chạm trước khi tạo đạn vượt qua mục tiêu.
- `godot_tests/enemy_sprite_asset.gd`: kiểm tra tương tự với nòng enemy theo từng hướng, gồm player đứng sát.
- `godot_tests/acceptance.gd`: score và giáp được kiểm tra thông qua va chạm đạn thực tế, không chỉ sửa trực tiếp giá trị để giả lập kết quả.

Chạy các bài kiểm tra hiện có bằng `make test`.

## Nhịp bắn và vật phẩm

Nhịp bắn lấy từ `config/player_characters.json`; xem bảng và rule trong [Chọn nhân vật](character-selection.md). Cooldown bắt đầu sau viên cuối; loạt đang chờ khóa di chuyển và hướng. Rapid Fire giảm một nửa thời gian nghỉ, Double Shot biến đổi schedule riêng cho từng vũ khí. Attack clock 0,23 giây chỉ dùng cho hình ảnh và không kéo dài khóa. Power-up được chốt tại lúc kích hoạt; chết hủy hàng đợi, pause đóng băng hàng đợi.

## Hướng tấn công của enemy — sửa ngày 13/10/2026

Enemy dùng chung hướng cho thân và nòng, không có turret quay độc lập. Khi nhắm player và bắn, enemy dừng di chuyển, giữ hướng tới hết shot clock (4/12 giây), rồi tiếp tục đường đi. Trong attack, không chạy lại nhánh chọn hướng tới target. Trước đây cùng một update có thể đổi hướng bắn vào player, tạo đạn, rồi đổi thân trở lại hướng đi; vì vậy đạn và sprite mâu thuẫn ngay lúc khai hỏa. Test regression bao phủ cả robot/tank, bốn hướng nhắm khi route vẫn đi DOWN, giữ hướng trong recoil và đi tiếp sau attack. Đạn đã bay giữ hướng ban đầu khi enemy đổi hướng về sau.
