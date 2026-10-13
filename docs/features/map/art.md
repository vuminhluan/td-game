# Hình ảnh map — Industrial v1

Bộ hình tĩnh phong cách khu công nghiệp cũ đã áp dụng vào game: nền slate tối, tường gạch rỉ sét, thép lạnh, nước xanh dầu, cây olive và Nhà chính có lõi cyan. Xem [map trong game](../../images/map-art-in-game.png) và [trạng thái phá hủy](../../images/map-art-damage.png).

## Phân chia trách nhiệm

- `scenes/maps/industrial_yard.tscn` sở hữu layout, TileMapLayer, marker và object. `assets/maps/industrial/terrain.tres` sở hữu metadata gameplay và texture atlas. Designer chỉnh trực tiếp trong Godot; xem [tạo map](authoring.md).
- `gd/map_definition.gd` tạo runtime grid/object state từ scene. `gd/simulation.gd` sở hữu thay đổi HP, phá hủy và pickup; `gd/battle_map.gd` dùng cùng flags cho collision và pathfinding.
- `gd/map_terrain.gd` gắn scene gốc vào renderer, xóa tile bị phá và ẩn object theo state runtime. Không còn vòng vẽ terrain bằng kind hoặc layout procedural riêng.
- `gd/map_overlay.gd` vẽ decal damage, bờ nước, Nhà chính và thanh HP sau terrain. `gd/map_skin.gd` giữ binding artwork cho overlay; texture terrain được gán trong TileSet. Foliage dùng z-index trong TileData để che actors; nó có thể che projectile/health indicator nếu trùng vùng ảnh.
- Bộ object hiện hành ở `assets/map_objects/industrial/` dùng PNG alpha sinh bằng ImageGen: machinery, pipes, robot wreck, drink can, single pipe và water pump. Map mẫu chỉ đặt cụm ống đơn/bơm và hai lon; [layout](industrial-layout.md) mô tả bố cục thoáng, không đặt grass. Các Resource/scene dùng lại trên mọi map, với flags di chuyển/đạn độc lập; xem [object môi trường](environment-objects.md). SVG placeholder machinery/pipes/crates đã được thay và gỡ sau khi kiểm tra dependency.

Atlas `terrain_atlas.png` ghép năm ảnh brick/steel/water/grass/floor thành tile 40 × 40 từ PNG hiện tại. Nguồn tạo atlas ở `assets/maps/industrial/source/build_atlas.gd`; đây chỉ là bước chuẩn hóa ảnh, không tạo layout hoặc bảng luật runtime. TileSet metadata được lưu trực tiếp trong resource. `.gdignore` giữ script nguồn ngoài asset export. Chạy lại bằng:

```sh
godot --headless --path . --script assets/maps/industrial/source/build_atlas.gd
godot --headless --path . --editor --import --quit
```

## Hợp đồng asset

| Asset | Runtime PNG | Hiển thị |
| --- | --- | --- |
| Nền | `floor.png`, 320×320, opaque | Lặp mỗi 320 world units; tint mặc định `(0.55, 0.60, 0.62)` giúp robot nổi bật |
| Gạch, thép, nước | 80×80, opaque | Đúng ô 40×40, không tràn collision |
| Cây | `grass.png`, 80×80, RGBA | Ô 40×40, viền trong suốt, vẽ sau actors |
| Nhà chính / xác Nhà chính | 224×200, RGBA | Rect `(-56, -56, 112, 100)` tương đối với `Simulation.base_position` |
| Nứt HP 2 / HP 1 | `brick_damage.svg`, `brick_critical.svg` | Decal riêng, không bake nứt gameplay vào texture gốc |

Godot dùng nearest filtering theo cấu hình dự án. Bờ nước được vẽ ở cạnh giáp terrain khác; hai ô nước liền nhau không có bờ ở giữa. Thanh HP Nhà chính độc lập artwork; HP 0 chọn texture wreck. Nhà chính giữ collider gameplay hiện có, không suy ra collider từ alpha.

## Thay hình và tạo phiên bản mới

1. Tạo thư mục runtime có phiên bản mới và copy `map_skin.tres`. Không ghi đè nguồn đã duyệt.
2. Gán PNG overlay mới vào slot của skin; chuẩn hóa texture terrain thành atlas 40 × 40 và gán trong TileSet resource riêng. Giữ vật cản khớp ô vuông; cây/Nhà chính cần alpha thật. Đổi `headquarters_rect` nếu kích thước hình thay đổi; đó là visual rect, không phải collider.
3. Chọn TileSet cho Terrain trong scene và thay `BattleView.map_skin` khi đổi artwork overlay. Trong scene chính hiện tại, `Main` tạo BattleView bằng code nên bộ mặc định nằm ở khai báo export trong `gd/battle_view.gd`; không có node BattleView lưu sẵn trong `main.tscn`.
4. Giữ raw, prompts, request và reports dưới `assets/generated/map/<asset-id>/`; tài liệu QA nằm trong `docs/qa/`. `.gdignore` ở `assets/generated/map/` ngăn import/export ảnh nguồn. Runtime chỉ tham chiếu thư mục terrain.
5. Import và chạy kiểm tra dưới đây. Nếu đổi kích thước chuẩn, cập nhật assertion kích thước theo hợp đồng mới, không bỏ kiểm tra alpha/phá hủy/replay.

## Nguồn và tái xuất

Tạo bằng **image_gen tích hợp ChatGPT**, không dùng API key/dịch vụ trả phí khác. Bảy lần generation/edit riêng: floor, brick, steel, water, grass, headquarters và wreck từ reference headquarters. Prompts và đường dẫn nguồn được lưu trong `assets/generated/map/industrial/request.json`; prompt edit chính xác ở `headquarters-wreck-prompt.txt` cùng thư mục.

`sprite-gen 2.43.0 background-tile` xử lý floor và water theo trục X rồi Y (`period=1180`, `overlap=64`); ảnh trung gian và reports được giữ nguyên. `scripts/install_map_art.py` chỉ chuẩn hóa kích thước bằng Pillow, fit silhouette RGBA và ghi manifest SHA-256, giữ nguyên ảnh nguồn và không vẽ thêm chi tiết. Đây là pipeline ảnh tĩnh, không dùng prepare/extract animation rows hoặc cắt lưới ảnh AI. Không loại alpha native hay thay pipeline bằng flood fill.

Script cần môi trường Python có Pillow; có thể dùng venv của sprite-gen đã cài.

```sh
python scripts/install_map_art.py \
  --run-dir assets/generated/map/industrial \
  --target assets/terrain/industrial_v1
godot --headless --path . --editor --import --quit
make test
make test-visual
```

Manifest runtime ở `assets/terrain/industrial_v1/manifest.json` ghi file, kích thước, alpha bbox và hash nguồn. Hai decal nứt là SVG vẽ thủ công, giữ ở thư mục runtime để sửa trực tiếp.

## QA và giới hạn

- Các checks hiện hành nằm trong `godot_tests/map_art_asset.gd`, `godot_tests/map_refactor.gd` và `godot_tests/map_camera.gd`: binding asset, alpha, damage stage, revision/replay, metadata scene và kích thước map.
- Đã chạy lại `make test-visual` ngày 2026-10-13 sau khi chuyển sang scene map, tất cả pass. Kết quả hiện hành và giới hạn ở [QA refactor](../../qa/map-refactor.md).
- Native map visual: ảnh thực thay đổi ở cả ba mức damage/phá gạch; xác Nhà chính và chơi lại được kiểm tra bằng so sánh pixels, pass.
- Native smoke: desktop, pause, 375×667 và 320×568; ảnh kiểm tra ở `/private/tmp/robot-defense-*.png`. Player/enemy visual cũng pass trên map mới.
- Reports bước X của floor/water đánh dấu `needs-review`; bước Y pass theo metric. Đã xem các bản lặp ở tỉ lệ chơi trong ảnh desktop/mobile: không thấy khe alpha hay viền sáng lớn. Đây không phải chứng nhận seamless tuyệt đối; motif sàn vẫn lặp theo chu kỳ 320 units.
- Water/foliage là ảnh tĩnh. Chưa xác nhận Web PWA hoặc thiết bị cảm ứng thật; kiểm tra native mobile là resize cửa sổ.
