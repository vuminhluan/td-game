# Tài liệu Robot Defense

Nếu mới vào dự án, đọc [phát triển dự án](development.md) để chạy game và test, sau đó chọn tính năng cần sửa bên dưới. Mỗi tài liệu có một vai trò: tính năng giải thích hành vi, workflow hướng dẫn thao tác, asset mô tả bộ đang dùng, QA lưu bằng chứng và giới hạn.

## Tính năng

| Tài liệu | Nội dung |
| --- | --- |
| [Bắn và va chạm đạn](features/combat.md) | Cooldown, nòng dài, chống xuyên vật cản |
| [Map: terrain và đường đi](features/map/navigation.md) | Grid, collision, Dijkstra, phá tường |
| [Map: hình ảnh](features/map/art.md) | Skin, cache terrain, lớp vẽ, bờ nước, Nhà chính |
| [Robot: skin và animation](features/robot-sprites/rendering.md) | Hướng, clock, moving fire, thay geometry |

## Quy trình

- [Tạo hoặc thay sprite robot](workflows/sprites.md): generation, extraction, composition, tích hợp và kiểm tra player/enemy.
- [Thay từng hướng enemy](workflows/enemy-sprites.md): dùng installer, giữ geometry đúng và cập nhật binding.
- [Bảo trì tài liệu và dọn asset](maintenance.md): nơi đặt file, nguồn hiện hành, cách xác định bản cũ có thể xóa.

Khi thay artwork: đọc tài liệu tính năng → asset đang dùng → workflow tương ứng → QA. Khi sửa gameplay: đọc tính năng → code simulation → chạy `make test`. Các lệnh chạy từ thư mục gốc repository.

## Asset

| Bộ | Hợp đồng runtime | Nguồn hiện hành |
| --- | --- | --- |
| Player mech | [Player](assets/player-mech.md) | `assets/generated/sprites/player_mech/down/`, `player_mech/directions/` |
| Enemy mech | [Mech](assets/enemy-mech.md) | `assets/generated/sprites/enemy_mech/` |
| Enemy tank | [Tank](assets/enemy-tank.md) | `assets/generated/sprites/enemy_tank/` |
| Map công nghiệp | [Map](assets/industrial-map.md) | `assets/generated/map/industrial/` |

Runtime PNG/TRES nằm trong `assets/sprites/` và `assets/terrain/`. Manifest runtime ghi nguồn; `.gdignore` loại nguồn generation khỏi import/export. Nguồn chứa prompts, ảnh raw, frames, guides và reports phục vụ lần nâng cấp tiếp theo.

## QA

- [Player DOWN](qa/player-mech/down.md) và [UP/LEFT/RIGHT](qa/player-mech/directions.md).
- [Enemy mech](qa/enemy-mech.md) và [enemy tank](qa/enemy-tank.md).
- Kết quả map nằm trong [QA hình ảnh map](features/map/art.md#qa-và-giới-hạn); ảnh preview tập trung ở `docs/images/`.

QA lịch sử không thay thế việc chạy test sau một thay đổi. Các giới hạn motion/seam và Web PWA phải được đọc cùng bằng chứng kiểm tra native.
