# Robot Defense — Godot / GDScript

Game 2D top-down dùng **Godot 4.7.2 + GDScript**. Renderer **Compatibility** và preset **Web PWA**, single-thread, đã được cấu hình cho mục tiêu xuất bản Web trong tương lai.

## Chạy bằng Godot

Mở `project.godot` trong Godot và nhấn **F6/F5**, hoặc chạy từ thư mục dự án:

```sh
godot --version
godot --path . --editor
godot --path .
```

Phiên bản đã kiểm thử: `4.7.2.stable.official.ed1daf0bf`.

## Cách chơi

- WASD hoặc phím mũi tên: di chuyển 4 hướng, phím vừa nhấn có ưu tiên; không di chuyển chéo.
- Giữ Space để bắn. P hoặc Escape: tạm dừng/tiếp tục.
- Mất focus cửa sổ hoặc ứng dụng đi vào nền: tự tạm dừng, xóa các phím/cảm ứng đang giữ.
- Màn hình hẹp: D-pad và nút BẮN hỗ trợ đồng thời nhiều ngón tay. Trượt ngón ra khỏi nút sẽ bỏ giữ nút đó.
- 3 robot, mỗi robot 5 giáp. Hồi sinh có 3 giây miễn nhiễm sát thương.
- Căn cứ có 20 HP. Căn cứ bị phá hoặc hết robot thì thua; hạ hết 5 đợt thì thắng.
- Gạch cần 3 phát để phá, có trạng thái nứt. Thép chặn robot và đạn; nước chặn robot nhưng đạn đi qua; cây đi/bắn xuyên và che robot.
- Đạn người chơi không gây sát thương căn cứ. Robot địch 2 HP/100 điểm; xe tăng 4 HP/250 điểm.
- Âm thanh tổng hợp tùy chọn, mặc định tắt. Không có vật phẩm, lưu tiến trình hoặc multiplayer.

## Kiểm thử Godot

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script godot_tests/acceptance.gd
godot --headless --path . --fixed-fps 60 --script godot_tests/player_mech_asset.gd
godot --path . --script godot_tests/visual_smoke.gd
```

- Acceptance kiểm tra luật chơi, địch tự tìm đường/phá căn cứ, đạn/sát thương/điểm, 5 đợt, hồi sinh, tạm dừng, chơi lại, bàn phím và đa điểm chạm. Script trả mã lỗi khác 0 nếu có thất bại.
- Player mech kiểm tra 56 frame, animation và tích hợp scene chính: chọn 4 góc riêng không xoay hình, vừa đi vừa bắn, va chạm tường, địch sát nòng súng, giật súng, pause, sát thương, hồi sinh và chơi lại. `make test` chạy cả hai bộ kiểm thử.
- Visual smoke cần màn hình/GUI, chạy renderer Compatibility thật và lưu 5 ảnh ở `/private/tmp/robot-defense-*.png` (macOS). Kiểm tra desktop, pause, mobile và màn hình 320px.
- Kết quả tại lần chuyển đổi: **234 checks, 0 failures**; render native thành công trên Apple M4 Pro, OpenGL Compatibility. Các bài kiểm tra cảm ứng dùng sự kiện mô phỏng; chưa xác nhận trên thiết bị cảm ứng thật hoặc trình duyệt.

## Xuất Web PWA

1. Trong Godot: **Editor → Manage Export Templates → Download and Install**. Templates phải khớp phiên bản editor **4.7.2.stable**.
2. **Project → Export → Web PWA → Export Project** tới `build/web/index.html`, hoặc:

```sh
mkdir -p build/web
godot --headless --path . --export-release "Web PWA" build/web/index.html
python3 -m http.server 8080 --directory build/web
```

Mở `http://localhost:8080`. Không mở trực tiếp HTML bằng `file://`. Khi phát hành, dùng HTTPS và giữ nguyên toàn bộ file xuất ra, gồm WebAssembly, `.pck`, manifest và service worker. Server cần phục vụ `.wasm` với MIME `application/wasm`.

Preset bật PWA, chế độ standalone, hướng dọc và icon; tắt `variant/thread_support` và hỗ trợ GDExtension. Single-thread không cần SharedArrayBuffer/COOP/COEP. Godot Web cần WebGL 2.0; Compatibility là renderer thích hợp. Xem [tài liệu xuất Web chính thức](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

**Trạng thái:** đã thử export; máy hiện chưa cài `web_nothreads_debug.zip` và `web_nothreads_release.zip` cho 4.7.2. Chưa tạo được bản Web, nên chưa kiểm chứng cài PWA, service worker, offline, âm thanh hay thao tác cảm ứng trong trình duyệt. Sau khi cài template, cần kiểm tra Chrome/Safari, thêm vào màn hình chính, tải lần đầu online rồi thử offline. File build không được commit.

## Cấu trúc

Giải thích kỹ thuật theo tính năng được lưu trong `docs/features/`: [bắn và va chạm đạn](docs/features/combat.md), [terrain và đường đi](docs/features/map-navigation.md), [skin và animation robot](docs/features/robot-sprites/rendering.md), [hình ảnh map](docs/features/map-art.md). Quy ước comment và tài liệu nằm trong `AGENTS.md`.

| Tệp | Trách nhiệm |
| --- | --- |
| `project.godot`, `scenes/main.tscn` | Dự án và scene chính |
| `gd/rules.gd` | Thông số cân bằng |
| `gd/battle_map.gd` | Bản đồ, va chạm terrain, Dijkstra có chi phí phá gạch |
| `gd/simulation.gd` | Mô phỏng gameplay độc lập với scene và renderer |
| `gd/battle_view.gd` | Vẽ robot, lớp cây che phủ và hiệu ứng bằng Godot 2D |
| `gd/map_skin.gd`, `gd/map_terrain.gd`, `assets/terrain/` | Resource hình ảnh map và lớp terrain cache theo revision/HP |
| `gd/player_skin.gd`, `assets/sprites/player_mech/` | Sprite player, hướng và lựa chọn frame theo trạng thái mô phỏng |
| `gd/main.gd` | HUD responsive, bàn phím/cảm ứng, pause/replay, âm thanh |
| `export_presets.cfg`, `assets/icon.svg` | Cấu hình Web/PWA và icon |
| `godot_tests/` | Kiểm thử GDScript và render |

Player và hai loại enemy dùng sprite sheet; terrain dùng bộ texture riêng qua `MapSkin`, hiệu ứng được vẽ bằng code. Mô phỏng giữ luật và bản đồ cũ, giao diện được dựng lại bằng Godot Controls. GDScript dùng `RefCounted` và dữ liệu thuần để có thể kiểm thử không cần cửa sổ.

Map đã áp dụng hình cho Nhà chính (cả trạng thái phá hủy), gạch, thép, nước, cây và nền công nghiệp. Hướng dẫn thay hình, provenance và kiểm tra: [docs/features/map-art.md](docs/features/map-art.md). [Ảnh map mới](docs/images/map-art-in-game.png). `make test` gồm kiểm tra asset map; `make test-visual` kiểm tra pixels khi phá gạch, phá Nhà chính và chơi lại.

`Makefile` cung cấp lệnh tắt: `make dev` mở game, `make editor` mở editor, `make import` import asset, `make test` kiểm thử, `make test-visual` render kiểm tra và `make build` xuất Web PWA. Có thể dùng các lệnh Godot trực tiếp ở trên nếu không có Make. Export preset loại test và tài liệu khỏi bản phát hành.

## Player mech — đã áp dụng trong game

Quy trình dùng lại cho tạo/thay player hoặc enemy: [docs/sprite-workflow.md](docs/sprite-workflow.md). Có thể mention file này trong yêu cầu tiếp theo.

Enemy tank và mech hai chân có skin riêng theo loại, với PNG/SpriteFrames/geometry riêng cho DOWN, UP, LEFT, RIGHT. Mỗi loại có 56 frame 128×128; thay một hướng bằng `scripts/install_enemy_direction.py` từ composed manifest. Xem [hướng dẫn enemy](docs/enemy-sprite-workflow.md). Preview 24 animation: `godot --path . scenes/enemy_sprite_preview.tscn`; test enemy được chạy trong `make test` và `make test-visual`.

Player có bốn góc nhìn riêng: Xuống, Lên (nhìn từ sau), Trái và Phải. Mỗi hướng có đứng 4 frame, đi 6 frame, bắn 4 frame: tổng 56 frame 128×128. Sheet Xuống ở `assets/sprites/player_mech/player_mech.png`; ba hướng mới ở `player_mech_directions.png`, với resource `player_mech_directions.tres`. Scene chính dùng `player_skin.tres` để chọn đúng hướng và animation, không xoay hình robot.

Đứng yên bắn có animation giật súng; vừa đi vừa bắn giữ chu kỳ chân và hiện chớp nòng súng. Va chạm tường trở về đứng, pause đóng băng animation, sát thương có nháy màu, hồi sinh có nhấp nháy bảo vệ. Sprite, kích thước, điểm neo từng hướng và độ dài nòng có thể đổi qua resource skin. Đạn kiểm tra cả đoạn từ robot tới đầu nòng, tránh bỏ qua vật cản hoặc địch đứng sát. Frame AI còn chênh lệch nhỏ về chi tiết giữa tư thế; các chu kỳ đi chưa được chứng nhận seamless.

Xem trước 12 animation: `godot --path . scenes/player_mech_preview.tscn`. Render kiểm tra bốn góc trong game: `godot --path . --script godot_tests/player_mech_visual.gd`. [Bảng bốn góc](docs/images/player-mech-four-directions.png). Chi tiết thay asset và provenance ở [README của player](assets/sprites/player_mech/README.md). Hình được tạo qua công cụ ảnh tích hợp, không dùng thêm API key; tách nền và ghép atlas bằng sprite-gen.
