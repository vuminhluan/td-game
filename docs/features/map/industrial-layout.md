# Bố cục map nhà máy cũ

Scene `scenes/maps/industrial_yard.tscn` dùng 21×19 ô, mỗi ô 40 world units. Hai cụm cấp nước sát biên thay các object lớn rải đều. Độ dài hai tuyến khác nhau để tránh lặp; giữa map và vùng trước căn cứ giữ thoáng. Có 18 ô gạch, 8 thép, 4 nước và không đặt grass. Khoảng 86,5% grid không bị terrain/object chặn di chuyển; hai lon nằm cạnh bơm trong khu bảo trì.

Máy nén, cụm ba ống, robot wreck và grass còn trong catalog/TileSet cho designer hoặc map khác. Scene không đặt chúng; việc bỏ placement không đồng nghĩa có thể xóa nguồn/resource. Xem [object và catalog](environment-objects.md) và [asset công nghiệp](../../assets/industrial-map.md).

## Prefab và điểm nối

| Scene trong `scenes/objects/industrial/` | Bố trí |
| --- | --- |
| `single_pipe.tscn` | Module dọc 160 units, footprint 1×4 |
| `water_pump.tscn`, `water_pump_right.tscn` | Bơm footprint 2×1; bản phải mirror artwork, giữ node gameplay không xoay/scale |
| `water_line_west.tscn` | Ba module từ y=0 tới y=480, nối bơm; map đặt x=0 |
| `water_line_east.tscn` | Hai module từ y=0 tới y=320, nối bơm; map đặt x=760, ống ở x=800 |

`MapObjectDefinition.connections` lưu điểm nối local trước mirror; `connection_point()` áp dụng mirror như renderer. `flip_h` không đổi footprint. Các module ghép đầu-cuối, kết thúc ở inlet của bơm. Artwork bơm có ống nằm trên mặt sàn, co 90° vào hông bơm và một van đỏ trước co; không thêm van vào từng module.

## Invariants

- Ba spawn địch, player và base ở vùng hợp lệ; mỗi enemy spawn có đường tới base.
- Ống chặn di chuyển nhưng đạn đi qua; bơm chặn cả hai. Các object cố định không phá được.
- Hai tuyến sát cột biên, không chồng terrain/object footprint hoặc cắt tuyến giữa map.
- Đầu module khớp đầu kế tiếp và inlet bơm trong world space; footprint không suy từ alpha artwork.
- Các prefab/resource dùng được trên map khác, không bị giới hạn theo theme.

Visual rect, crop bơm và đầu vào generation nằm ở [asset công nghiệp](../../assets/industrial-map.md#object-và-generation-source). Installer giữ geometry và flags designer đã chỉnh. Xem cả tọa độ và hình rendered: điểm nối khớp không chứng minh artwork có hướng cơ khí đúng.

## Kiểm tra và preview

`godot_tests/environment_objects.gd` kiểm tra nối module/bơm, cột biên, tỷ lệ sàn đi được, grass không đặt nhưng TileSet vẫn dùng được, flags và đường tới căn cứ. `environment_objects_visual.gd` chụp [overview](../../../assets/maps/previews/industrial.png) ở scale 1 và [hai cụm cấp nước](../../images/industrial-water-line-detail.png) ở scale 3. [Object và weapon pickup](../../images/industrial-objects-in-game.png) dùng game thật với camera desktop fit toàn map và pickup mẫu. [QA map](../../qa/maps.md#industrial-yard) ghi phạm vi và giới hạn.
