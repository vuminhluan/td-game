# Ghép hình và animation nhân vật

Simulation sở hữu hướng, `move_clock`, `shot_clock`, `hurt_clock` và thời lượng attack. Renderer chọn hình từ các clock này. Pause đóng băng clock; hồi sinh và chơi lại tạo trạng thái actor mới. Gameplay và resource loadout ở [Chọn nhân vật](../character-selection.md) và [Body/Weapon/Loadout](../player-loadout.md).

## Player hiện hành

`CharacterCatalog` dựng `CharacterArt` từ `assets/sprites/characters/manifest.json`. Hai Body và bảy bộ vũ khí dùng bốn pose riêng theo hướng, không xoay/mirror ảnh. Mỗi pose được lặp bốn frame trong SpriteFrames cho từng trạng thái; idle giữ hình tĩnh, walk được renderer tạo bằng chuyển động nhỏ ở phần chân/xích, torso và socket giữ cố định.

`BattleView` lấy Body từ `sim.loadout.body`, ghép `weapon.layered_art` tại socket và áp dụng cùng tint. Góc nhìn ngang của tên lửa vẽ vùng sau thân trước Body, rồi phần vũ khí còn lại phía trước. Recoil dùng `shot_clock` và `recoil_distance`; flash/phóng dùng event projectile của simulation tại từng nòng.

Player di chuyển thật mới tăng move clock. Walk được ưu tiên khi đang di chuyển, kể cả lúc bắn; đứng tì vào tường trở về idle. Đứng yên chọn attack khi shot clock còn thời gian. `PlayerWeapon.shot_duration` mặc định 0,23 giây và không bị kéo dài bởi cooldown hoặc Rapid Fire. Loạt Gatling/tên lửa và Double Shot khóa di chuyển đến event cuối theo schedule, độc lập animation.

Atlas player-mech còn là fixture/reference. `PlayerSkin` dùng `frames` cho DOWN và `directional_frames` cho các hướng khác. Bộ fixture có bốn góc vẽ riêng nên `rotation_for()` trả 0. Resource khác không có directional frames vẫn có fallback xoay theo `forward`. Nhánh renderer fixture ghép vùng thân/nòng và giáp socket như [hợp đồng loadout](../player-loadout.md).

## Enemy

`EnemySkin` map bốn hướng sang `EnemyDirection`, mỗi resource có SpriteFrames, anchor, scale và muzzle distance riêng. Không tự xoay/mirror để bù hướng còn thiếu. Thiếu resource/frame thì BattleView dùng hình fallback theo loại actor.

Enemy giữ hướng và vị trí trong shot clock 1/3 giây; sau đó mới tiếp tục đi, dù cooldown bắn còn 1,3 giây với tank hoặc 1,7 giây với robot. Clock walk chỉ tăng khi vị trí đổi. Frame attack là one-shot độc lập cooldown. Xem [Combat](../combat.md).

BattleView bind geometry nòng enemy theo skin khi gán simulation; geometry player đã có trong loadout. Thay một hướng enemy chỉ cần thay đúng direction resource. [Quy trình sprite](../../workflows/sprites.md) mô tả installer và cách giữ geometry đã hiệu chỉnh.

## Thứ tự vẽ và kiểm chứng

`MapTerrain` gắn map scene phía sau BattleView. Terrain, base, vật thể và foliage dùng layer/z-index của map; foliage có thể che actor, projectile hoặc thanh HP khi vùng ảnh trùng nhau. BattleView vẽ actor, pickups, đạn/effects, sau cùng là HP enemy. Collider và đường đạn độc lập alpha của artwork. Xem [Kiến trúc map và hình ảnh](../map/authoring.md) và [Combat](../combat.md).

`make test` kiểm tra resource, clock, pause, hướng, geometry và va chạm; `make test-visual` chụp renderer native. Các board preview không chứng nhận motion/seam hoặc bản Web. Nguồn và giới hạn QA ở [Artwork nhân vật](../../assets/characters.md), [Player fixture](../../assets/player-mech.md) và [Enemy sprites](../../assets/enemy-sprites.md).
