# Map thành phố bỏ hoang

## Thiết kế và bố cục

Map `abandoned_city_day` giữ phong cách minh họa của game và luật phòng thủ hiện tại. Ảnh tham khảo định hướng đại lộ thành phố bỏ hoang ban ngày: đường nứt, vạch sơn cũ, xe gỉ sét và các dãy nhà hư hại. Robot ở ảnh tham khảo là nhân vật điều khiển; scene không đặt robot bỏ hoang làm scenery.

Lưới chơi có kích thước 21 × 19 ô, tương ứng 840 × 760 world pixel. Đại lộ dọc rộng 480 pixel có sáu lane, ba lane mỗi chiều. Một đường ngang rộng 160 pixel tại y = 300 tạo ngã tư bốn hướng gần giữa map. Vỉa hè rộng 60 pixel và tám nhà có footprint 3 × 3 ô nằm ở hai mép; nhà còn nguyên, nhà cũ bám rêu và nhà vỡ một phần dùng cùng hợp đồng object. Khoảng trống giữa các cụm nhà giữ đường ngang mở. Không đặt bụi cỏ, robot bỏ hoang hay terrain gạch phá hủy trong map này.

Người chơi được đi tự do qua lane, vạch phân đường, vạch qua đường và nắp cống. Hai kiểu xe có bản dọc và bản ngang, đặt thưa để không khóa lối đi. Một đến hai đèn giao thông đổ tạo vật cản. Mỗi spawn địch phải có đường tới vị trí tiếp cận căn cứ.

Trên desktop, camera thu toàn bộ lưới chơi vào viewport. Trên điện thoại ngang, camera theo robot và cuộn dọc đại lộ. Thiết lập landscape đã có trong project; resize native không xác minh khóa hướng trên thiết bị thật. Xem [camera](camera.md).

## Trách nhiệm của scene và resource

`scenes/maps/abandoned_city.tscn` sở hữu kích thước, placement, marker, preview và skin. `gd/road_layout.gd` dựng đường bằng dữ liệu `road_rect`, `lane_count`, `intersection_rect` và `sidewalk_width`; thay chiều rộng đường hoặc vị trí ngã tư không cần thêm luật riêng theo map ID vào renderer hay simulation. Đường là lớp hình ảnh; lane và vạch sơn không tạo collision.

`assets/maps/city/terrain.tres` giữ metadata terrain. `assets/terrain/abandoned_city/map_skin.tres` giữ theme cho renderer. TileSet và skin thành phố tách khỏi map công nghiệp. Các object dùng `MapObjectDefinition` và scene riêng trong `assets/map_objects/city/` và `scenes/objects/city/`; catalog dùng chung không phụ thuộc tên map.

| Object | Di chuyển | Đạn | Độ bền |
| --- | --- | --- | --- |
| Xe sedan và wagon, dọc hoặc ngang | Chặn theo footprint | Xuyên qua | Cố định, không phá được |
| Đèn giao thông đổ | Chặn theo footprint | Xuyên qua | Cố định, không phá được |
| Nắp cống và biển báo | Đi qua | Xuyên qua | Decoration, không phá được |
| Nhà mép phố | Chặn theo footprint | Chặn | Cố định, không phá được |

Bản ngang của xe dùng texture đã xoay và footprint tương ứng, không xoay node có collision. Quy ước grid và kiểm tra hợp lệ của `MapDefinition` vẫn áp dụng: node gameplay có unit scale, không xoay, không chồng footprint và nằm trong lưới. Xe và đèn đổ chặn di chuyển nhưng không chặn đạn, nên không thể bị AI phá để mở đường. Mọi giải thích về luật object nằm tại đây thay vì comment trong hàm.

## Artwork và khả năng thay thế

Xe và bụi cỏ có spritesheet riêng. Mỗi crop có vùng alpha trống quanh đủ bốn phía, giữ cả đầu và đuôi xe; không cắt xe cùng vùng atlas của bụi cỏ. Hai kiểu xe được lưu trong atlas xe với bản dọc/ngang riêng. Nguồn theo vai trò ở `assets/generated/map/city/` giúp thay artwork mà giữ nguyên placement, ID và metadata collision.

Normalizer lấy bounds từ alpha lớn hơn 0.04 và giữ thêm fringe nguồn 4 pixel trước khi resize vào cell có gutter. Alpha rất nhỏ ngoài thân xe không làm xe bị thu bé vào giữa frame. QA yêu cầu thân xe có alpha từ 0.1 trở lên phủ ít nhất 75% một chiều frame; kiểm tra này bảo vệ độ rõ của xe mà không thay luật gameplay hoặc footprint.

Bụi cỏ vẫn có resource dùng chung và atlas `assets/map_objects/vegetation/bushes.png` để dùng trong map khác. Asset cũ chỉ được xóa sau khi kiểm tra tham chiếu runtime, nguồn tạo asset, manifest, tài liệu và QA. Các nguồn vẫn cần tái tạo artwork phải được giữ lại hoặc chuyển sang đường dẫn vai trò có tên rõ ràng.

Xem [artwork thành phố](../../assets/city-map.md) để biết nguồn, manifest và lệnh tái tạo. Preview toàn map nằm ở `assets/maps/previews/abandoned-city.png` và được chụp bằng renderer native.

## Luồng chọn map

`Main.available_maps` dựng thẻ lựa chọn từ scene map. Màn chọn map nhận tên, mô tả và `preview_texture` từ root của scene. Sau khi người chơi chọn map, `Main.choose_map()` tạo simulation, gắn map skin vào BattleView rồi mở màn chọn nhân vật. Map công nghiệp là lựa chọn mặc định. Quay lại chọn nhân vật giữ map; quay lại chọn map và xác nhận tạo simulation theo lựa chọn mới.

Khi thêm map, tạo root `MapDefinition` có tên, mô tả, preview, dimensions, skin và marker hợp lệ, rồi thêm scene vào `available_maps`. Không thêm điều kiện theo tên map vào collision runtime hoặc object catalog. Hợp đồng marker và spawn nằm ở [biên soạn map](authoring.md).

## Kiểm tra

`godot_tests/map_selection.gd` kiểm tra đường đi của từng spawn, bố cục đường, đủ hai mẫu xe với cả hai hướng, collision toàn footprint, đạn thực sự xuyên vật cản, độ bền, nắp cống đi qua được, crop alpha và hash source/runtime. Test cũng kiểm tra bụi cỏ vẫn dùng atlas riêng và luồng chọn map trước chọn nhân vật.

`godot_tests/map_selection_visual.gd` chụp preview, màn chọn map/nhân vật, battle desktop và battle điện thoại ngang; xác nhận desktop chứa trọn lưới và camera mobile theo robot. Kết quả và giới hạn nằm ở [QA thành phố](../../qa/abandoned-city.md).
