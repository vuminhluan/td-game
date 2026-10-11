# Bắn và va chạm đạn

`gd/simulation.gd` sở hữu cooldown, tạo đạn, va chạm và sát thương. Skin chỉ cung cấp thông số hình học nòng súng; luật sát thương không phụ thuộc alpha của sprite.

## Nòng súng theo hướng

`BattleView.sim` cấp `player_skin.muzzle_distances` và khoảng cách nòng của từng loại enemy cho simulation. Khi chơi lại, binding này được áp dụng cho simulation mới. Simulation chạy độc lập vẫn dùng mặc định: `Rules.PLAYER_MUZZLE_DISTANCE` cho player, 20 world units cho enemy.

Nếu nòng của skin dài hơn khoảng cách mặc định, `fire()` kiểm tra va chạm từ khoảng cách mặc định tới đầu nòng theo bước tối đa 2 world units, gồm điểm cuối. Đạn bị chặn ngay nếu đoạn này gặp vật cản hoặc mục tiêu hợp lệ. Điều này tránh trường hợp đầu nòng nằm trong hoặc vượt qua tường khiến viên đạn sinh ra phía bên kia và bỏ qua tường; tương tự với mục tiêu đứng sát.

## Di chuyển đạn

Mỗi lần update, quãng đường đạn được chia thành `ceil(BULLET_SPEED * dt / 5)` bước, ít nhất một bước. Mỗi bước dài tối đa 5 world units và kiểm tra va chạm ngay sau khi di chuyển, tránh xuyên qua tile hoặc actor giữa hai frame.

## Kiểm tra khi thay skin hoặc sửa collision

- `godot_tests/player_mech_asset.gd`: nòng dài gặp gạch/thép hoặc enemy đứng sát phải va chạm trước khi tạo đạn vượt qua mục tiêu.
- `godot_tests/enemy_sprite_asset.gd`: kiểm tra tương tự với nòng enemy theo từng hướng, gồm player đứng sát.
- `godot_tests/acceptance.gd`: score và giáp được kiểm tra thông qua va chạm đạn thực tế, không chỉ sửa trực tiếp giá trị để giả lập kết quả.

Chạy các bài kiểm tra hiện có bằng `make test`.
