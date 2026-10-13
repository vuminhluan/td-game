# Tài liệu Robot Defense

Nếu mới vào dự án, đọc [phát triển dự án](development.md) để chạy game và test, sau đó chọn tính năng cần sửa bên dưới. Mỗi tài liệu có một vai trò: tính năng giải thích hành vi, workflow hướng dẫn thao tác, asset mô tả bộ đang dùng, QA lưu bằng chứng và giới hạn.

## Tính năng

| Tài liệu | Nội dung |
| --- | --- |
| [Bắn và va chạm đạn](features/combat.md) | Cooldown, nòng dài, chống xuyên vật cản |
| [Power-up](features/power-ups.md) | 5 hiệu ứng đã triển khai, sinh/rơi vật phẩm, countdown, tuning và gameplay QA |
| [Map: terrain và đường đi](features/map/navigation.md) | Grid, collision, Dijkstra, phá tường |
| [Map: camera và input](features/map/camera.md) | Camera cuộn/clamp, HUD màn hình, landscape, safe area và screen/world conversion |
| [Map: hình ảnh](features/map/art.md) | Skin, cache terrain, lớp vẽ, bờ nước, Nhà chính |
| [Object môi trường và weapon pickup](features/map/environment-objects.md) | Bộ artwork nhà máy cũ, reusable Resource/scene, flags độc lập và catalog không giới hạn theme |
| [Biên soạn map](features/map/authoring.md) | Scene map, TileSet custom data, object, marker và validation |
| [Refactor map](features/map/refactor-plan.md) | Phạm vi triển khai và tiêu chí hoàn thành |
| [Robot: skin và animation](features/robot-sprites/rendering.md) | Hướng, clock, moving fire, thay geometry |
| [Tùy biến thân robot và súng](features/player-loadout.md) | Chọn súng trước trận, socket, ghép lớp thân/súng, đạn hai nòng và QA |
| [Chọn và tùy biến nhân vật trước trận](features/character-selection.md) | Đã triển khai Robot/Xe tăng, Body sạch, 7 loadout, lịch bắn, khóa di chuyển và config chung |

## Quy trình

- [Tạo hoặc thay sprite robot](workflows/sprites.md): generation, extraction, composition, tích hợp và kiểm tra player/enemy.
- [Thay từng hướng enemy](workflows/enemy-sprites.md): dùng installer, giữ geometry đúng và cập nhật binding.
- [Bảo trì tài liệu và dọn asset](maintenance.md): nơi đặt file, nguồn hiện hành, cách xác định bản cũ có thể xóa.

Khi thay artwork: đọc tài liệu tính năng → asset đang dùng → workflow tương ứng → QA. Khi sửa gameplay: đọc tính năng → code simulation → chạy `make test`. Các lệnh chạy từ thư mục gốc repository.

## Asset

| Bộ | Hợp đồng runtime | Nguồn hiện hành |
| --- | --- | --- |
| Nhân vật và vũ khí tách lớp | [Characters](assets/characters.md) | `assets/generated/sprites/characters/body-weapons/` |
| Player mech tham chiếu | [Player](assets/player-mech.md) | `assets/generated/sprites/player_mech/down/`, `player_mech/directions/` |
| Enemy mech | [Mech](assets/enemy-mech.md) | `assets/generated/sprites/enemy_mech/` |
| Enemy tank | [Tank](assets/enemy-tank.md) | `assets/generated/sprites/enemy_tank/` |
| Map công nghiệp | [Map](assets/industrial-map.md) | `assets/generated/map/industrial/` |

Runtime PNG/TRES nằm trong `assets/sprites/` và `assets/terrain/`. Manifest runtime ghi nguồn; `.gdignore` loại nguồn generation khỏi import/export. Nguồn chứa prompts, ảnh raw, frames, guides và reports phục vụ lần nâng cấp tiếp theo.

## QA

- [Object và artwork](qa/environment-objects.md): collision, sprite weapon chính xác và native rendering.
- [Refactor map](qa/map-refactor.md): kết quả gameplay, scene validation, camera và native rendering; giới hạn Web/handheld.

- [Player DOWN](qa/player-mech/down.md) và [UP/LEFT/RIGHT](qa/player-mech/directions.md).
- [Enemy mech](qa/enemy-mech.md) và [enemy tank](qa/enemy-tank.md).
- Kết quả map nằm trong [QA hình ảnh map](features/map/art.md#qa-và-giới-hạn); ảnh preview tập trung ở `docs/images/`.

QA lịch sử không thay thế việc chạy test sau một thay đổi. Các giới hạn motion/seam và Web PWA phải được đọc cùng bằng chứng kiểm tra native.
