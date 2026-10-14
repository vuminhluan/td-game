# QA hệ thống map

Tài liệu này gom phạm vi test hiện hành và bằng chứng map công nghiệp/thành phố. Hướng dẫn chỉnh scene ở [biên soạn map](../features/map/authoring.md); artwork/source contract ở [asset công nghiệp](../assets/industrial-map.md) và [asset thành phố](../assets/city-map.md).

## Chạy lại

```sh
godot --headless --path . --editor --import --quit
make test
make test-visual
```

`make test` chạy logic/headless; visual runners cần native renderer. Không dùng tổng assertion của lần chạy cũ làm bằng chứng cho checkout vừa thay đổi. Kết quả ngày 13–14/10/2026 bên dưới là lần kiểm tra đã ghi nhận trước khi dọn tài liệu; cần chạy lại suite khi đổi source, path hoặc asset.

## Kiểm tra sau dọn source — 14/10/2026

`make test` pass: environment 150, map authoring 118, camera 325, chọn map 630, chọn nhân vật 916, loadout 392, power-up 39, acceptance 234, enemy 305 và map art 24 checks; player fixture/integration cũng pass. Đã chạy cả mười visual runners native, xem lại city, chọn nhân vật và enemy battle. Hash của 38 ảnh runtime/preview vẫn khớp trước/sau cleanup. Bản sao checkout bỏ cache `.godot` cũng import từ đầu và chạy toàn bộ `make test` thành công, xác nhận không phụ thuộc remap/cache cũ.

`make check` xác minh resource paths, link/heading Markdown, source fingerprints và naming; chi tiết cleanup ở [summary](../cleanup-summary.json).

## Runtime và camera

| Suite | Phạm vi |
| --- | --- |
| `godot_tests/map_refactor.gd` | Scene fixture/PackedScene, dimensions, TileSet metadata và flags độc lập, fallback player, spawn luân phiên, footprint shared HP, damage giữ underlay, invalid configuration, pickup settings clone/lifetime/pool/compatibility |
| `godot_tests/map_camera.gd` | Desktop fit toàn map, mobile zoom/clamp/căn giữa, viewport lớn/nhỏ/portrait, screen/world đối chiếu canvas transform, touch độc lập, landscape config, replay/loadout giữ map |
| `godot_tests/map_camera_visual.gd` | Native desktop 1280×720, landscape 844×390 và 568×320, portrait fallback 375×667; HUD trong màn hình |
| `godot_tests/map_art_asset.gd` | Binding texture, kích thước, alpha, damage stage, phá căn cứ và replay |
| `godot_tests/map_art_visual.gd` | So sánh pixels ở ba mức HP gạch/phá hủy, phá căn cứ và replay |

Revision và terrain/object state dùng chung giữa collision/pathfinding và renderer. Fixture test không dựa vào bảng luật kind độc lập. Explicit incompatible weapon được giữ trong map và kiểm tra compatibility lúc nhặt; settings không sửa Resource shared.

## Industrial yard

`godot_tests/environment_objects.gd` kiểm tra catalog canonical Resource, alpha/region/aspect ratio, flags di chuyển/đạn, độ bền object cố định, placement trên map khác theme và artwork weapon dùng lại atlas nhân vật. Layout hiện hành có 18 brick, 8 steel, 4 water, 5 module ống, 2 bơm và 2 lon; không đặt grass. Hai tuyến sát cột biên nối đúng inlet, 345/399 ô đi được và cả ba spawn tới base. Grass/máy/cụm ống/wreck vẫn có dependency trong TileSet hoặc catalog.

`environment_objects_visual.gd` so sánh pixels khi ẩn bơm/ống/lon hoặc weapon pickup để xác minh chúng được compositing. Screenshot game thật dùng camera desktop fit toàn map, có pickup mẫu; ảnh overview không HUD dùng BattleView scale 1, ảnh inlet dùng scale 3. Tọa độ nối trùng nhau cần được đối chiếu với artwork để xác nhận co/van/ống nằm trên mặt sàn.

Bản sửa inlet/van ngày 13/10/2026 ghi nhận suite logic pass, environment 150 checks/0 failures và native environment 15 checks/0 failures trên Godot 4.7.2, macOS Apple M4 Pro, Compatibility. Manifest/source/runtime khớp SHA-256; tái chạy installer giữ geometry, flags và catalog khác theme. Tổng suite cũ thay đổi theo source, nên không được giữ làm số lượng hiện hành.

| Bằng chứng do visual runner tái tạo | Nội dung |
| --- | --- |
| [Map trong game](../images/map-art-in-game.png) | Terrain/căn cứ và actor fixture |
| [Damage](../images/map-art-damage.png) | Gạch và căn cứ hư hại |
| [Object và weapon pickup](../images/industrial-objects-in-game.png) | Object được render cùng terrain/weapon |
| [Overview](../../assets/maps/previews/industrial.png) | Bố cục 840×760 không HUD |
| [Chi tiết hai cụm](../images/industrial-water-line-detail.png) | Hai đầu inlet, co và van |

## Abandoned city

`godot_tests/map_selection.gd` kiểm tra map hợp lệ, ba spawn tới base, đường sáu lane/ngã tư bốn hướng đi qua được, không terrain phá hủy/bụi cỏ/robot scenery. Hai kiểu xe có bản ngang/dọc; xe và hai đèn đổ chặn toàn footprint, đạn xuyên, không bị phá. Nắp cống đi qua được. Art checks xác minh alpha gutter/thân xe, atlas vegetation riêng, extraction metadata và SHA-256 source/runtime. Luồng chọn map trước chọn nhân vật và replay giữ map được kiểm tra.

`map_selection_visual.gd` render preview, chọn map/nhân vật, battle desktop/mobile landscape. Native checks xác minh desktop chứa trọn grid và camera mobile cuộn theo player. Preview tĩnh cần chụp trước, import lại rồi chạy capture chọn map; texture preload trong cùng process không tự cập nhật khi ghi PNG. Lệnh ở [asset thành phố](../assets/city-map.md#tái-tạo-và-kiểm-tra).

Lần kiểm tra ngày 14/10/2026 trên Godot 4.7.2 ghi nhận `make test` và tất cả visual runners pass; map selection 630 checks/0 failures, camera headless/native 325/81 checks/0 failures, city visual 3 checks/0 failures. Đã xem overview, battle desktop và hai vị trí mobile: sáu lane/ngã tư mở, xe giữ đầu/đuôi và kích thước đọc được, nhà giữ alpha.

| Bằng chứng do visual runner tái tạo | Nội dung |
| --- | --- |
| `assets/maps/previews/abandoned-city.png` | Overview native, thumbnail của thẻ chọn map |
| [Battle desktop](../images/abandoned-city-in-game.png) | Toàn lưới thành phố |
| [Battle mobile](../images/abandoned-city-mobile.png) | Camera gần đầu đại lộ trên landscape |
| [Chọn map desktop](../images/map-selection-desktop.png), [mobile](../images/map-selection-mobile.png) | Hai layout chọn map |
| [Chọn nhân vật](../images/character-selection-desktop.png) | Bước sau khi xác nhận map |

Các screenshot khóa thời gian/spawn để ổn định; sau khi đổi vị trí player cần queue redraw trước capture. Suite simulation/acceptance kiểm tra chiến đấu đầy đủ. File dưới `/private/tmp/` như `map-camera-*.png` hoặc `abandoned-city-mobile-intersection.png` chỉ là artifact của lần chạy, không phải tài liệu được giữ trong repository.

## Limitations

- Native resize/input mô phỏng chưa xác minh orientation lock, notch/safe area hoặc cảm ứng trên handheld thật.
- Web PWA export từng bị chặn vì thiếu template `web_nothreads_debug.zip`/`web_nothreads_release.zip` cho Godot 4.7.2; chưa ghi nhận browser/PWA/offline/touch trên bản export.
- Alpha/gutter và connection assertions không thay thế xem silhouette và hướng cơ khí của sprite ở tỉ lệ chơi.
- Artwork nước/foliage là ảnh tĩnh; kiểm tra seamless và cân bằng độ khó vẫn cần xem/playtest dài.
- Chế độ tấn công và streaming/chunk chưa triển khai; validation hiện hành giới hạn grid thủ thành.
