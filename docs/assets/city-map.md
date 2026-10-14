# Artwork thành phố bỏ hoang

Runtime của map thành phố dùng scene `scenes/maps/abandoned_city.tscn`, TileSet `assets/maps/city/terrain.tres`, skin `assets/terrain/abandoned_city/` và object resource `assets/map_objects/city/`. Preview native nằm ở `assets/maps/previews/abandoned-city.png`.

## Tách asset theo vai trò

| Vai trò | Dữ liệu/runtime | Nguồn |
| --- | --- | --- |
| Đường sáu lane và ngã tư | `gd/road_layout.gd`, `assets/terrain/abandoned_city/floor.png` | `assets/generated/map/city/road_surface/` |
| Xe sedan, wagon; bản ngang/dọc | `assets/map_objects/city/cars.png`, `cars_horizontal.png`; Resource riêng cho mỗi mẫu/hướng | `assets/generated/map/city/cars/` |
| Nắp cống, biển báo, đèn đổ | `assets/map_objects/city/street_props.png` và Resource thành phố | `assets/generated/map/city/street_props/` |
| Nhà còn nguyên/cũ/đổ một phần | `assets/maps/city/outer_houses.png`, object nhà trong lưới | `assets/generated/map/city/houses/` |
| Bụi cỏ dùng cho map khác | `assets/map_objects/vegetation/bushes.png`, Resource `city_bush` giữ trong catalog | Vùng bush của `assets/generated/map/city/objects/source.png` |
| Robot bỏ hoang dùng cho map khác | `assets/map_objects/city/abandoned_robot.png`, Resource giữ trong catalog | Vùng robot của `assets/generated/map/city/objects/source.png` |
| Vỉa hè và tile nguồn dùng lại | `assets/maps/city/sidewalk.png`, `terrain_atlas.png` | `assets/generated/map/city/terrain/` |

Scene thành phố không dùng bụi cỏ hoặc robot bỏ hoang. Bộ terrain nguồn cũ vẫn được giữ nếu đang cung cấp tile hoặc reference cho các asset hiện hành. Việc giữ nguồn không thêm lại các object đó vào map.

Nguồn nhà mới có alpha thật và ba biến thể. `assets/generated/map/city/houses/style_reference.png` giữ ảnh nhà trước làm reference phong cách; file này không được dùng làm atlas runtime. Nguồn object cũ vẫn cung cấp bush và robot qua các crop đã sửa, nên còn là dependency tái tạo dù mixed atlas runtime đã được thay bằng các atlas riêng.

Xe có alpha gutter ở bốn phía crop để không mất đuôi và không dính vào bụi cỏ. Các bản ngang dùng texture đã xoay cùng footprint ngang; designer không xoay node gameplay. Crop hình ảnh, `visual_rect` và footprint là dữ liệu resource, có thể thay độc lập khi mở rộng bộ xe.

`assets/maps/city/manifest.json` ghi các vai trò artwork, đường dẫn source/runtime và SHA-256. `assets/map_objects/city/manifest.json` ghi object resource/scene. Request JSON giữ provider, đường dẫn và prompt chính xác khi tạo ảnh. Raw PNG vẫn được giữ trong source tree để tái tạo và thay thế; không chỉnh trực tiếp raw nguồn bằng tay.

Các thư mục `cars`, `street_props`, `houses` và `objects` có `extraction.json` với `source_size` và các vùng `regions` theo tên sprite. Khi thay ảnh nguồn khác kích thước, cập nhật dữ liệu này; builder từ chối dimension hoặc crop ngoài ảnh. Manifest cũng fingerprint file extraction để việc thay crop là một thay đổi đầu vào có thể kiểm tra.

## Hợp đồng crop

Normalizer lấy bounds alpha >0,04, giữ fringe nguồn 4 pixel rồi fit vào cell có tổng gutter 16 pixel mỗi trục. Alpha nhiễu rất mờ ngoài silhouette không làm xe bị thu nhỏ. Crop phải giữ alpha trống ở cả bốn phía; test yêu cầu thân xe alpha ≥0,1 phủ ít nhất 75% một chiều frame để bảo vệ độ rõ ở tỉ lệ chơi. Gutter và tỷ lệ không chứng minh silhouette nguyên vẹn: vẫn cần xem ảnh native để kiểm tra đầu/đuôi xe.

Xe dọc có cell 128×192 trong atlas 256×192, bản ngang xoay PNG 90° vào cell 192×128 trong atlas 384×128. Footprint tương ứng 2×3 hoặc 3×2; node gameplay không xoay. Nhà có ba cell 160×160, atlas 480×160; visual rect nằm riêng với footprint 3×3. Street props dùng atlas 512×128; signal có cell 256×128, biển báo/nắp cống có cell 128×128.

## Prompt tạo artwork

Bốn ảnh mới được tạo bằng ImageGen tích hợp; `source.png` và `request.json` nằm cạnh mỗi prompt.

| Bộ | Prompt hiện hành |
| --- | --- |
| Xe sedan và wagon | [cars/prompt.txt](../../assets/generated/map/city/cars/prompt.txt) |
| Đèn đổ, biển báo, nắp cống | [street_props/prompt.txt](../../assets/generated/map/city/street_props/prompt.txt) |
| Nhà ba biến thể | [houses/prompt.txt](../../assets/generated/map/city/houses/prompt.txt) |
| Mặt đường | [road_surface/prompt.txt](../../assets/generated/map/city/road_surface/prompt.txt) |

## Tái tạo và kiểm tra

```sh
godot --headless --path . --script scripts/build_city_map_art.gd
godot --headless --path . --editor --import --quit
godot --headless --path . --script scripts/install_city_map.gd
godot --headless --path . --editor --import --quit
```

Builder chuẩn hóa ảnh nguồn và atlas theo vai trò. Installer tạo lại scene thành phố, Resource/scene object, TileSet, skin, manifest và entry thành phố trong catalog. Lệnh này ghi đè placement/geometry đã chỉnh thủ công của thành phố theo dữ liệu trong installer; để tái tạo đúng thiết kế mới, cập nhật bảng dữ liệu installer trước. Catalog vẫn giữ entry của bộ khác. Khi đổi số mẫu hoặc crop, cập nhật extraction metadata, bảng dữ liệu installer và resource variant thay vì thêm điều kiện vào simulation.

Chạy `make test` rồi `make test-visual` khi đổi art, crop, footprint hoặc placement; test native cập nhật preview và ảnh QA. Kiểm tra ảnh xe, nắp cống và nhà trong overview cùng battle desktop/mobile. Theo [bảo trì asset](../maintenance.md), kiểm tra cả tham chiếu source/reference trước khi bỏ một atlas hoặc run cũ. Xem [thiết kế map](../features/map/abandoned-city.md) và [QA](../qa/maps.md#abandoned-city).

Sau khi sửa scene, chụp preview trước và import lại để màn chọn map đọc texture mới. Texture đã preload trong cùng process không tự đổi khi PNG được ghi lại:

```sh
godot --path . --script godot_tests/map_selection_visual.gd -- --preview-only
godot --headless --path . --editor --import --quit
godot --path . --script godot_tests/map_selection_visual.gd
```
