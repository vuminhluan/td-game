# Hình ảnh map — Industrial v1

Bộ hình tĩnh phong cách khu công nghiệp cũ đã áp dụng vào game: nền slate tối, tường gạch rỉ sét, thép lạnh, nước xanh dầu, cây olive và Nhà chính có lõi cyan. Xem [map trong game](../images/map-art-in-game.png) và [trạng thái phá hủy](../images/map-art-damage.png).

## Phân chia trách nhiệm

- `gd/battle_map.gd` và `gd/simulation.gd` sở hữu kind, HP, collision, pathfinding và revision. Hình ảnh không đổi luật chơi.
- `gd/map_skin.gd` là Resource chứa texture, tint nền và rect Nhà chính. Bộ hiện tại: `assets/terrain/industrial_v1/map_skin.tres`; gán qua `BattleView.map_skin`.
- `gd/map_terrain.gd` vẽ nền và vật cản trong một Node2D nằm sau actors. Cache lệnh vẽ được làm mới khi thay simulation/skin, revision terrain đổi hoặc HP căn cứ đổi. Gạch biến thành floor sau phát thứ ba, lập tức lộ nền bên dưới.
- `gd/battle_view.gd` vẽ actors → foliage → đạn/hiệu ứng → thanh HP. Cây giữ alpha, che robot nhưng không che đạn.

Không dùng TileMapLayer ở quy mô hiện tại: map cố định 21×19 đã có grid gameplay độc lập. Thêm một grid tile ID nữa sẽ cần đồng bộ HP và phá tường ở hai nơi. Skin dùng trực tiếp kind hiện có; có thể thay renderer bằng TileMapLayer khi cần map lớn hoặc editor terrain, mà giữ nguyên simulation.

## Hợp đồng asset

| Asset | Runtime PNG | Hiển thị |
| --- | --- | --- |
| Nền | `floor.png`, 320×320, opaque | Lặp mỗi 320 world units; tint mặc định `(0.55, 0.60, 0.62)` giúp robot nổi bật |
| Gạch, thép, nước | 80×80, opaque | Đúng ô 40×40, không tràn collision |
| Cây | `grass.png`, 80×80, RGBA | Ô 40×40, viền trong suốt, vẽ sau actors |
| Nhà chính / xác Nhà chính | 224×200, RGBA | Rect `(-56, -56, 112, 100)` tương đối với `Rules.BASE` |
| Nứt HP 2 / HP 1 | `brick_damage.svg`, `brick_critical.svg` | Decal riêng, không bake nứt gameplay vào texture gốc |

Godot dùng nearest filtering theo cấu hình dự án. Bờ nước được vẽ ở cạnh giáp terrain khác; hai ô nước liền nhau không có bờ ở giữa. Thanh HP Nhà chính độc lập artwork; HP 0 chọn texture wreck. Nhà chính giữ collider gameplay hiện có, không suy ra collider từ alpha.

## Thay hình và tạo phiên bản mới

1. Tạo thư mục runtime có phiên bản mới và copy `map_skin.tres`. Không ghi đè nguồn đã duyệt.
2. Gán PNG mới vào từng slot texture của resource. Giữ vật cản khớp ô vuông; cây/Nhà chính cần alpha thật. Đổi `headquarters_rect` nếu kích thước hình thay đổi; đó là visual rect, không phải collider.
3. Thay `BattleView.map_skin`. Trong scene chính hiện tại, `Main` tạo BattleView bằng code nên bộ mặc định nằm ở khai báo export trong `gd/battle_view.gd`; không có node BattleView lưu sẵn trong `main.tscn`.
4. Giữ raw, prompts, request và QA dưới `assets/generated/map/<version>/`. `.gdignore` ở `assets/generated/map/` ngăn import/export ảnh nguồn. Runtime chỉ tham chiếu thư mục terrain.
5. Import và chạy kiểm tra dưới đây. Nếu đổi kích thước chuẩn, cập nhật assertion kích thước theo hợp đồng mới, không bỏ kiểm tra alpha/phá hủy/replay.

## Nguồn và tái xuất

Tạo bằng **image_gen tích hợp ChatGPT**, không dùng API key/dịch vụ trả phí khác. Bảy lần generation/edit riêng: floor, brick, steel, water, grass, headquarters và wreck từ reference headquarters. Prompts và đường dẫn nguồn được lưu trong `assets/generated/map/industrial-v1/request.json`; prompt edit chính xác ở `headquarters-wreck-prompt.txt` cùng thư mục.

`sprite-gen 2.43.0 background-tile` xử lý floor và water theo trục X rồi Y (`period=1180`, `overlap=64`); ảnh trung gian và reports được giữ nguyên. `scripts/install_map_art.py` chỉ chuẩn hóa kích thước bằng Pillow, fit silhouette RGBA và ghi manifest SHA-256, giữ nguyên ảnh nguồn và không vẽ thêm chi tiết. Đây là pipeline ảnh tĩnh, không dùng prepare/extract animation rows hoặc cắt lưới ảnh AI. Không loại alpha native hay thay pipeline bằng flood fill.

Script cần môi trường Python có Pillow; có thể dùng venv của sprite-gen đã cài.

```sh
python scripts/install_map_art.py \
  --run-dir assets/generated/map/industrial-v1 \
  --target assets/terrain/industrial_v1
godot --headless --path . --editor --import --quit
make test
make test-visual
```

Manifest runtime ở `assets/terrain/industrial_v1/manifest.json` ghi file, kích thước, alpha bbox và hash nguồn. Hai decal nứt là SVG vẽ thủ công, giữ ở thư mục runtime để sửa trực tiếp.

## QA và giới hạn

- Godot 4.7.2 Compatibility native: import thành công; acceptance 234 checks, enemy 264 checks và player integration pass.
- Map asset: 24 checks pass, gồm binding, alpha, damage stage, cache invalidation và replay.
- Native map visual: ảnh thực thay đổi ở cả ba mức damage/phá gạch; xác Nhà chính và chơi lại được kiểm tra bằng so sánh pixels, pass.
- Native smoke: desktop, pause, 375×667 và 320×568; ảnh kiểm tra ở `/private/tmp/robot-defense-*.png`. Player/enemy visual cũng pass trên map mới.
- Reports bước X của floor/water đánh dấu `needs-review`; bước Y pass theo metric. Đã xem các bản lặp ở tỉ lệ chơi trong ảnh desktop/mobile: không thấy khe alpha hay viền sáng lớn. Đây không phải chứng nhận seamless tuyệt đối; motif sàn vẫn lặp theo chu kỳ 320 units.
- Water/foliage là ảnh tĩnh. Chưa xác nhận Web PWA hoặc thiết bị cảm ứng thật; kiểm tra native mobile là resize cửa sổ.
