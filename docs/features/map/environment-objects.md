# Object môi trường và hình weapon pickup

Catalog tổng ở `assets/map_objects/catalog.tres` chứa `MapObjectDefinition` dùng chung. Tags chỉ tổ chức resource, không hạn chế map/theme. Scene instance trong `scenes/objects/` tham chiếu Resource để designer kéo thả và đặt vị trí. Các bộ công nghiệp, thành phố và vegetation dùng cùng validation/collision/pathfinding.

## Resource, instance và collision

`gd/map_object_definition.gd` giữ texture, visual rect, footprint, flags, mirror và connection metadata; `gd/map_object.gd` giữ instance có vị trí. Khi có `definition`, Inspector ẩn trường standalone để tránh hai nơi chỉnh cùng giá trị. Chỉnh Resource shared để đổi mọi instance; Make Unique cho biến thể. Node standalone không có definition dùng hợp đồng tại [biên soạn map](authoring.md).

Snapshot được tạo khi bắt đầu simulation. HP, active và flags runtime không sửa Resource shared. Footprint gameplay khai báo theo ô, không lấy từ alpha/texture/visual rect. Object nhiều ô dùng chung HP; phá object giải phóng footprint và giữ terrain bên dưới. Decoration không có footprint gameplay; pickup đặt sẵn chuyển thành pickup runtime. Radar đọc cùng movement flags.

| Object công nghiệp trong catalog | Chặn di chuyển | Chặn đạn | Phá được |
| --- | --- | --- | --- |
| Lon nước | Không | Không | Không |
| Cụm ống và module ống đơn | Có | Không | Không |
| Máy nén, bơm và robot bỏ hoang | Có | Có | Không |

Map mẫu dùng hai tuyến ống đơn nối bơm và hai lon, không đặt máy nén/cụm ống/wreck. Các Resource/scene đó vẫn là thành phần catalog dùng lại trên mọi map. Cụm môi trường nằm trong world space và cuộn cùng camera. [Bố cục công nghiệp](industrial-layout.md) giữ tuyến giữa map và cả ba spawn tới base. [Thành phố](abandoned-city.md) mô tả flags cho xe, nhà và street props.

## Weapon pickup

`gd/weapon_pickup_art.gd` đọc manifest character, chọn đúng vùng súng hướng phải trong atlas dùng cho weapon trang bị, bỏ padding alpha và cache AtlasTexture theo artwork ID. Weapon tương thích ưu tiên hình của character hiện tại; weapon không tương thích lấy hình của character hỗ trợ nó. Đây là lựa chọn hình ảnh; luật compatibility khi nhặt vẫn nằm trong gameplay. Pickup không dùng animation/muzzle flash của súng.

## Artwork và kiểm tra

Nguồn generation, alpha contract, installer giữ chỉnh sửa designer và manifest nằm ở [asset công nghiệp](../../assets/industrial-map.md#object-và-generation-source) và [asset thành phố](../../assets/city-map.md). Bộ theme mới thêm Resource/scene, không thêm bảng luật theme vào simulation.

`godot_tests/environment_objects.gd` kiểm tra Resource shared, alpha/region, flags độc lập, độ bền, nối ống, map khác theme, đường đi và dùng lại artwork weapon. Native `environment_objects_visual.gd` so sánh pixels khi ẩn object hoặc pickup, rồi chụp overview/chi tiết inlet. Xem [QA map](../../qa/maps.md#industrial-yard).
