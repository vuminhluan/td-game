# Tài liệu Robot Defense

Bắt đầu với [phát triển dự án](development.md) để chạy game và test. Tài liệu tính năng mô tả hành vi/invariant; tài liệu asset giữ geometry và nguồn; workflow hướng dẫn thay thế; QA ghi phạm vi kiểm tra và bằng chứng.

## Tính năng

| Tài liệu | Nội dung |
| --- | --- |
| [Chọn nhân vật](features/character-selection.md) | Luồng map trước nhân vật, stats, bảy loadout, lịch bắn và khóa di chuyển |
| [Body/Weapon/Loadout](features/player-loadout.md) | Trách nhiệm resource, socket/muzzle, collider và fixture regression |
| [Ghép hình/animation](features/robot-sprites/rendering.md) | Clock, pose hiện hành, thứ tự lớp, fixture và enemy |
| [Combat](features/combat.md) | Quét nòng/đạn, collision và hướng tấn công enemy |
| [Pickup/power-up](features/power-ups.md) | Pool, sinh/rơi, tương thích weapon, lifetime và hiệu ứng |
| [Biên soạn map](features/map/authoring.md) | Scene layout, TileSet, object/marker, validation, renderer/skin |
| [Navigation](features/map/navigation.md) | Terrain/footprint, Dijkstra, vật cản và phá hủy |
| [Camera/input](features/map/camera.md) | Desktop fit, mobile follow, HUD, safe area và screen/world conversion |
| [Object môi trường](features/map/environment-objects.md) | Catalog dùng chung, flags độc lập, connection và weapon pickup art |
| [Nhà máy](features/map/industrial-layout.md) | Hai tuyến cấp nước sát biên, địa hình và không gian giao tranh |
| [Thành phố bỏ hoang](features/map/abandoned-city.md) | Sáu lane, ngã tư, xe/đèn đổ, nhà và alpha crop |

## Quy trình

- [Sprite](workflows/sprites.md): tạo/thay player layers, fixture hoặc từng hướng enemy; geometry, nguồn và QA.
- [Bảo trì](maintenance.md): nơi đặt tài liệu, source/reference dependencies và dọn file.
- [Phát triển](development.md): lệnh import/chạy/test/export và giới hạn môi trường.

Các lệnh chạy từ repository root. Khi sửa gameplay, đọc tính năng và chạy `make test`. Khi sửa artwork/geometry, đọc asset contract và workflow rồi chạy thêm native visual.

## Asset

| Bộ | Hợp đồng | Nguồn |
| --- | --- | --- |
| Player hiện hành | [Body/vũ khí](assets/characters.md) | `assets/generated/sprites/characters/body-weapons/` |
| Player fixture/reference | [Player mech](assets/player-mech.md) | `assets/generated/sprites/player_mech/{down,directions}/` |
| Enemy robot/tank | [Enemy sprites](assets/enemy-sprites.md) | `assets/generated/sprites/enemy_{mech,tank}/<direction>/` |
| Nhà máy | [Industrial](assets/industrial-map.md) | `assets/generated/map/industrial/` |
| Thành phố | [City](assets/city-map.md) | `assets/generated/map/city/` |

`assets/generated/.gdignore` loại nguồn khỏi import/export. Raw được chọn, reference, prompts, manifests, frames và reports còn dùng được giữ để tái tạo/thay artwork. Tên file/thư mục thể hiện vai trò, không đánh số version.

## QA

- [Map](qa/maps.md): cả hai map, catalog, camera/input, damage, preview và native/handheld/Web limits.
- [Enemy sprites](qa/enemy-sprites.md): nguồn, motion/alpha evidence, runtime geometry và regression.
- [Player fixture](qa/player-mech.md): atlas DOWN/directions, reference chain và motion limits.

QA generation không thay thế regression cho checkout đang sửa. Locomotion/seam, cảm ứng thật và Web PWA cần được đọc cùng giới hạn của từng báo cáo.
