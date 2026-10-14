# Artwork map công nghiệp

Layout là `scenes/maps/industrial_yard.tscn`; TileSet là `assets/maps/industrial/terrain.tres`; skin là `assets/terrain/industrial/map_skin.tres`. Kiến trúc scene/runtime nằm ở [biên soạn map](../features/map/authoring.md), bố cục ở [nhà máy](../features/map/industrial-layout.md). Bộ artwork dùng nền slate tối, gạch rỉ sét, thép lạnh, nước xanh dầu và căn cứ có lõi cyan.

## Hợp đồng terrain và overlay

| Asset runtime trong `assets/terrain/industrial/` | Kích thước | Hợp đồng hiển thị |
| --- | --- | --- |
| `floor.png` | 320×320, opaque | Scene lặp ảnh nền và tint `(0.55, 0.60, 0.62)` |
| `brick.png`, `steel.png`, `water.png` | 80×80, opaque | Atlas dùng tile 40×40, không tràn collision |
| `grass.png` | 80×80, RGBA | Atlas dùng tile 40×40 với z-index 1, alpha thật |
| `headquarters.png`, `headquarters_wreck.png` | 224×200, RGBA | Rect `(-56, -56, 112, 100)` tương đối với base marker |
| `brick_damage.svg`, `brick_critical.svg` | SVG | Decal ở HP 2 và HP 1, tách khỏi texture gạch |

Godot dùng nearest filtering theo cấu hình dự án. Overlay chỉ vẽ bờ nước ở cạnh giáp terrain khác; HP 0 dùng căn cứ wreck. Collider căn cứ giữ theo gameplay, độc lập silhouette. Skin thành phố cũng tham chiếu căn cứ và hai decal của bộ này; kiểm tra cả hai map khi thay chúng. Grass không được đặt trong map mẫu nhưng còn được dùng bởi TileSet, skin và test metadata.

Nguồn terrain, prompt và processing report ở `assets/generated/map/industrial/`; `request.json` ghi nguồn và hợp đồng chuẩn hóa. Floor/water dùng bản repeat đã xử lý theo X rồi Y (`period=1180`, `overlap=64`); raw và report là dependency tái tạo. `scripts/install_map_art.py` chỉ chuẩn hóa bằng Pillow, fit silhouette RGBA và ghi source SHA-256/alpha bounds vào `assets/terrain/industrial/manifest.json`. Không sửa raw nguồn hoặc bake damage vào texture.

```sh
python scripts/install_map_art.py \
  --run-dir assets/generated/map/industrial \
  --target assets/terrain/industrial
godot --headless --path . --script assets/maps/industrial/source/build_atlas.gd
godot --headless --path . --editor --import --quit
```

Python cần Pillow. Atlas builder resize brick/steel/water/grass/floor thành năm tile 40×40 và ghi `assets/maps/industrial/terrain_atlas.png`; metadata gameplay được lưu trong TileSet, builder không tạo layout. Script nguồn và generated tree được `.gdignore` loại khỏi export.

## Object và generation source

Runtime PNG/Resource nằm trong `assets/map_objects/industrial/`; scenes và prefab nằm trong `scenes/objects/industrial/`. PNG nguồn có alpha và dùng ImageGen tích hợp; runtime giữ nguyên byte PNG, AtlasTexture chọn vùng hiển thị. `manifest.json` trong thư mục runtime ghi source, region và SHA-256. Weapon pickup dùng vùng súng hướng phải trong atlas nhân vật qua `gd/weapon_pickup_art.gd`, không có bitmap súng riêng.

| Artwork | Nguồn hiện hành trong `assets/generated/map/industrial/objects/` |
| --- | --- |
| Máy nén | `machinery/source.png`, `prompt.txt`, `request.json` |
| Cụm ống thấp | `pipes/source.png`, `prompt.txt`, `request.json` |
| Robot bỏ hoang | `wreck/source.png`, `prompt.txt`, `request.json` |
| Lon nước | `can/source.png`, `prompt.txt`, `request.json` |
| Module ống đơn | `single_pipe/source.png`, `prompt.txt`, `request.json` |
| Bơm, cả hai hướng | `water_pump/source.png`, `prompt.txt`, `request.json` |

`water_pump/inputs/` giữ các đầu vào của edit được khai báo trong request. Pipes/can dùng machinery làm reference; wreck tham chiếu machinery và artwork nhân vật. Những file này cần được giữ khi thay artwork vì còn là nguồn/reference, dù không được load trực tiếp trong trận. Máy nén, cụm ống thấp và wreck còn được catalog và prefab tham chiếu dù map mẫu không đặt chúng.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script scripts/install_environment_art.gd
```

Installer lấy bounds từ alpha >0,1, thêm fringe 2 pixel và cập nhật texture/AtlasTexture. Trên Resource đã tồn tại, nó giữ visual rect, footprint, flags, mirror, connections và chỉnh sửa designer; seed chỉ dùng khi tạo mới. Catalog giữ cả entry của chủ đề khác. Installer không sửa layout map. Khi thay PNG, kiểm tra visual vì bounds đổi có thể làm điểm ghép sprite lệch trong visual rect.

Điểm ghép bơm trong PNG hiện hành là `(531, 166)`, atlas region `(404, 131, 1178, 679)`. Visual rect và connection metadata căn inlet ở `(20, 0)` cho bơm trái, `(60, 0)` sau mirror cho bơm phải; stub lồng vào mặt bích khoảng 2 world units. Dùng `connection_point()` để ghép prefab, không dùng điểm local thô của biến thể mirror. [Ảnh hai cụm](../images/industrial-water-line-detail.png) kiểm tra co 90°, van đỏ và hướng ống nằm trên mặt sàn; assertion tọa độ không thay thế xem artwork.

## Thay asset và kiểm tra

Thay bộ đang dùng dưới đường dẫn vai trò hiện hành, cập nhật nguồn/request/manifest và chạy builder tương ứng. Không tạo thư mục runtime đánh số phiên bản. Muốn theme mới độc lập thì tạo thư mục theo tên theme, TileSet và skin riêng rồi gán vào scene. `headquarters_rect` và `visual_rect` chỉ thay hình ảnh; gameplay footprint chỉnh riêng trong Resource.

Chạy `make test` và `make test-visual` sau khi thay asset hoặc metadata. Xem [QA map](../qa/maps.md) cho suite, screenshots và giới hạn. Floor/water là ảnh tĩnh; repeat report X có trạng thái `needs-review` và Y pass theo metric, không bảo đảm motif không lặp. Kiểm tra ở tỉ lệ chơi khi thay chúng. Trước khi xóa asset/source, đối chiếu runtime, builder, request reference, manifest, tài liệu và test theo [bảo trì](../maintenance.md).
