# Skin và animation robot

Bộ player hiện hành dùng thân sạch/vũ khí riêng: [Artwork nhân vật](../../assets/characters.md) và [Chọn nhân vật](../character-selection.md). Atlas player-mech mô tả bên dưới được giữ làm reference và QA lịch sử.

Skin chứa artwork, frame, điểm neo, scale và khoảng cách nòng. Simulation sở hữu hướng bắn và các clock animation; renderer chọn frame từ dữ liệu mô phỏng. Pause dừng clock, còn chơi lại hoặc hồi sinh khởi tạo trạng thái animation tương ứng.

## Player

Player ghép thân và súng theo [loadout](../player-loadout.md); socket thân và anchor súng có geometry riêng. Các lớp dùng chung frame index, hướng, clock và tint; hai nòng được vẽ ở offset ngang riêng.

`gd/player_skin.gd` dùng `frames` cho DOWN và `directional_frames` cho các hướng còn lại. Với bộ directional hiện tại, `rotation_for()` trả 0: mỗi hướng có hình vẽ riêng. Skin không có `directional_frames` vẫn hỗ trợ cơ chế xoay từ hướng `forward`.

Khi actor đang di chuyển, animation `walk` được ưu tiên ngay cả lúc bắn. Chớp/giật tại nòng dùng effect của simulation trong `BattleView`; không chuyển toàn bộ robot sang attack và làm dừng chu kỳ chân. Đứng yên mới chọn `attack` nếu `shot_clock` còn thời gian, nếu không thì `idle`. Frame attack dùng `actor.shot_duration` (player mặc định 0,23 giây), độc lập với cooldown và hệ số Rapid Fire.

Clock đi chỉ tăng khi vị trí thay đổi. Đứng tì vào tường phải trở về idle thay vì tiếp tục animation đi. `godot_tests/player_mech_asset.gd` kiểm tra điều này bằng tình huống player gặp tường thép.

Enemy giữ hướng và đứng yên trong shot clock tấn công; chỉ tiếp tục walk khi attack kết thúc. Xem [hướng bắn enemy](../combat.md).

## Enemy và thay riêng một hướng

`gd/enemy_skin.gd` ánh xạ từng hướng tới resource `gd/enemy_direction.gd`, không tự xoay hoặc mirror để thay góc còn thiếu. Mỗi direction chứa `SpriteFrames`, anchor, scale và muzzle distance riêng; frame có thể tham chiếu nhiều PNG.

Thay entry LEFT chỉ thay hình học và frame LEFT, giữ các hướng khác. `godot_tests/enemy_sprite_asset.gd` kiểm tra thay hướng độc lập này, gồm geometry riêng. Khi thiếu frame/resource, `frame_for()` trả null và BattleView có thể dùng nhánh vẽ fallback theo loại actor.

`scripts/install_enemy_direction.py` cài một hướng từ composed manifest, lấy chính xác vùng atlas và metadata animation, không viết lại các direction resource khác. Script chỉ dùng Python standard library.

## Thứ tự lớp vẽ

Terrain và Nhà chính nằm sau robot. BattleView vẽ actors, sau đó foliage, rồi đạn/effects và thanh HP enemy. Cây che robot nhưng đạn và hiệu ứng vẫn nhìn thấy. Chi tiết cache terrain và visual rect Nhà chính nằm trong [tính năng hình ảnh map](../map/art.md).

Khoảng cách nòng cần được kiểm tra cùng [va chạm đạn](../combat.md) khi thay artwork.

## Tạo, thay asset và kiểm tra

Quy trình asset được giữ ở [Quy trình sprite](../../workflows/sprites.md) và [Quy trình enemy sprite](../../workflows/enemy-sprites.md). Chạy `make test` để kiểm tra resource và integration; `make test-visual` để kiểm tra bằng renderer native.
