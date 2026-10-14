# Phát triển Robot Defense

Dự án dùng Godot 4.7.2, GDScript và renderer Compatibility. `project.godot` mở `scenes/main.tscn`; cấu hình mặc định 1280×720, handheld landscape. Các lệnh bên dưới chạy từ repository root.

## Chạy và kiểm thử

```sh
godot --version
make import
make dev
make editor
make test
make test-visual
```

`GODOT` trong Makefile có thể trỏ tới binary khác. `TEST_LOG_DIR` mặc định `/tmp`; truyền thư mục writable khác nếu cần. `make check` kiểm tra tên file, resource paths, link/heading Markdown và fingerprint nguồn bằng Python stdlib; target này cũng chạy trước `make test`. `make test` chạy headless: catalog/object, map authoring/validation, camera, chọn map/nhân vật, loadout, pickup/power-up, acceptance và asset player/enemy/map. Script trả mã khác 0 nếu có failure.

`make test-visual` cần màn hình/native renderer và chạy toàn bộ visual runners; ảnh dùng trong tài liệu nằm ở `docs/images/`, preview map ở `assets/maps/previews/`, artifact tạm của từng ca nằm dưới `/private/tmp/`. Khi môi trường GUI không cho chạy qua Make, chạy từng lệnh Godot trong target này trực tiếp. Sau khi scene đổi, tạo preview trước và import lại để thumbnail preload đọc ảnh mới; xem [asset thành phố](assets/city-map.md#tái-tạo-và-kiểm-tra).

Phiên bản đã kiểm tra: `4.7.2.stable.official.ed1daf0bf`, macOS Apple M4 Pro, OpenGL Compatibility. Native resize và input mô phỏng kiểm tra layout/touch logic; chúng không xác nhận thiết bị cảm ứng thật hoặc trình duyệt. Phạm vi/evidence ở [QA](README.md#qa).

## Cách chơi

Mở game: chọn map → Robot/Xe tăng → Body → một vũ khí tương thích → vào trận. Game có hai map và bảy loadout; lựa chọn không lưu qua lần mở game. Stats và nhịp bắn đọc từ `config/player_characters.json`, xem [nhân vật](features/character-selection.md).

- WASD/mũi tên: bốn hướng, phím nhấn sau cùng ưu tiên; không đi chéo.
- Giữ Space hoặc nút BẮN để khai hỏa; P/Escape để pause/resume.
- Mất focus hoặc đi vào nền tự pause và xóa input đang giữ. Màn hình hẹp hỗ trợ giữ nhiều nút touch đồng thời.
- Bảo vệ căn cứ 20 HP qua 5 đợt; mất căn cứ hoặc hết 3 lượt sinh thì thua. Robot 5 HP/tốc độ 150, tank 10 HP/tốc độ 100; hồi sinh có 3 giây miễn nhiễm.
- Gạch/theo metadata có thể phá; thép chặn đạn thường, nước chặn di chuyển nhưng cho đạn xuyên. Xe/đèn đổ thành phố chặn di chuyển và cho đạn xuyên; lane/vạch sơn không collision.
- Đạn player không làm hỏng căn cứ. Enemy robot 2 HP/100 điểm; tank 4 HP/250 điểm. Có power-up và weapon pickup; xem [pickup](features/power-ups.md).
- Desktop chứa trọn map; mobile giữ zoom đủ lớn và cuộn theo player. Âm thanh tổng hợp tùy chọn, mặc định tắt; chưa lưu tiến trình/multiplayer.

## Source và công cụ

| Nhóm | Trách nhiệm |
| --- | --- |
| `gd/main.gd`, selection Controls | Map-first UI, HUD, camera, input, pause/replay và âm thanh |
| `config/player_characters.json`, CharacterCatalog | Stats, compatibility, muzzle geometry và schedule bắn |
| `MapDefinition`, `scenes/maps/`, TileSet | Layout, terrain/object/marker metadata và validation |
| `BattleMap`, `Simulation` | Runtime flags, collision, navigation, wave/damage/pickup |
| `BattleView`, MapTerrain/MapOverlay | Sprite layers, scene map, destruction sync và effect/base overlay |
| `assets/` | Runtime resources và source/reference tách theo vai trò |
| `godot_tests/` | Logic/resource regression và native renderer |

[Biên soạn map](features/map/authoring.md), [rendering](features/robot-sprites/rendering.md), [asset index](README.md#asset) và [workflow sprite](workflows/sprites.md) mô tả hợp đồng riêng. Các installer/builders chỉ tái tạo nhóm asset được ghi rõ trong tài liệu; đọc tác động lên scene/geometry trước khi chạy.

## Web PWA

`export_presets.cfg` có preset Web PWA, single-thread, standalone landscape. Tests/docs/generated sources được loại khỏi export; config JSON và manifests runtime được bao gồm.

```sh
make build
python3 -m http.server 8080 --directory build/web
```

Export templates phải khớp phiên bản Godot. Sau khi export thành công, mở `http://localhost:8080`; không mở HTML qua `file://`. Phát hành cần HTTPS, đủ WASM/PCK/manifest/service worker và MIME `application/wasm`. Hướng dẫn ở [Godot Web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

Lần export trước bị chặn vì thiếu templates Web non-threaded cho Godot 4.7.2. Chưa có evidence cho browser, cài PWA, service worker, offline, âm thanh hoặc touch của bản Web. Khi templates sẵn sàng cần chạy export và kiểm tra Chrome/Safari, cài lên màn hình chính, tải online lần đầu rồi thử offline. Không commit build output.
