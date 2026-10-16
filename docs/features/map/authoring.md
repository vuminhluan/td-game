# Tạo map bằng Godot

Layout chạy trong game lấy từ scene map đã chọn. Hai map hiện hành là `scenes/maps/industrial_yard.tscn` và `scenes/maps/abandoned_city.tscn`, cùng chế độ `defense` và kích thước 21 × 19 ô. Một ô gameplay luôn bằng 40 world units. Scene và TileSet là nguồn thiết kế; renderer và simulation không giữ bản layout riêng.

## Kiến trúc runtime và hình ảnh

`MapDefinition.build_runtime()` đọc metadata TileSet, marker và object trong scene. `Simulation` giữ HP, trạng thái phá hủy, pickup và revision của từng trận; `BattleMap` dùng cùng flags cho collision và đường đi. `MapTerrain` gắn scene vào BattleView, xóa cell bị phá và ẩn object theo runtime state. `MapOverlay` vẽ nứt gạch, bờ nước, căn cứ và thanh HP; `MapSkin` giữ texture của overlay. Texture terrain nằm trong TileSet; node Floor của scene giữ ảnh nền. Foliage có thể che actor, projectile hoặc thanh HP khi vùng ảnh trùng nhau.

Artwork không quyết định luật gameplay. Thay texture/visual rect không được tự đổi footprint hay HP. Skin thành phố dùng lại artwork căn cứ và decal damage của bộ công nghiệp; mỗi scene chọn TileSet và skin riêng. Xem [asset công nghiệp](../../assets/industrial-map.md) và [asset thành phố](../../assets/city-map.md) để thay hoặc tái tạo hình.

## Vẽ và chỉnh kích thước

1. Mở scene map trong Godot, chọn node `Terrain` (`TileMapLayer`), mở bảng TileMap và vẽ/xóa tile.
2. Chọn root để đổi `dimensions`. Terrain hợp lệ phải nằm trong hình chữ nhật từ `(0, 0)` đến `dimensions - 1`. Node `Floor` tự đổi vùng lặp ảnh theo kích thước map; các ô terrain không được vẽ mặc định là sàn đi được.
3. Giữ root và Terrain ở origin, scale 1, không xoay. Terrain trong một group vẫn phải có transform tổng hợp khớp lưới map.
4. Lưu scene, gán tên/mô tả/preview/map skin trên root, rồi thêm scene vào `Main.available_maps`. `Main.map_scene` là map khởi đầu mặc định; màn hình đầu game liệt kê các map khả dụng và tạo simulation từ scene người chơi chọn.

Tạo map khác bằng cách duplicate scene mẫu rồi đổi `map_id` và `dimensions`. TileSet dùng chung ở `assets/maps/industrial/terrain.tres`; nếu cần luật hoặc ảnh khác riêng cho map mới, tạo resource riêng bằng Make Unique hoặc Save As trước khi sửa. Giới hạn validation là 1024 ô mỗi trục và 262144 ô tổng, nhằm từ chối cấu hình cấp phát quá lớn trước khi tạo runtime grid. Vùng liên tục lớn hơn có thể chia theo chunk trong một thay đổi riêng về sau.

## Luật terrain

TileSet có custom data `kind` (String), `move_blocked`, `bullet_blocked`, `destructible` (bool), `hp` (int), và `steel` (bool tùy chọn). Chỉnh dữ liệu trong TileSet editor trên từng tile. HP không âm; tile phá được phải có HP dương. `kind` là nhãn hình ảnh; collision, tìm đường và damage dùng flags, không suy ra từ tên hoặc alpha của texture.

Ví dụ tile thép mẫu có HP 5, chặn di chuyển/đạn, phá được và `steel = true`: đạn thường không phá được; damage được cho phép phá thép có thể phá. Nước chặn di chuyển nhưng không chặn đạn. Foliage có z-index 1 để nằm trước actors. Luật gameplay nằm trong resource TileSet, không có bảng luật kind độc lập trong script.

## Marker và object

Thêm `Marker2D`, gán `gd/map_marker.gd`, chọn `role`: `base`, `enemy`, `player` hoặc `player_two`. Icon B/E/P/P2 chỉ hiện trong editor. Map thủ thành cần đúng một base và ít nhất một enemy spawn. Player marker tùy chọn; thiếu marker thì chọn tâm ô đi được gần base, cách base ít nhất 60 units. Marker `player_two` tùy chọn cho Local Co-op, tối đa một marker và không được chồng P1/căn cứ; simulation còn kiểm tra collider của loadout thực tế. Thiếu marker P2 thì tìm ô hợp lệ gần P1; xem [Local Co-op](../local-coop.md). Mỗi enemy spawn phải có đường tới ô tiếp cận căn cứ; đường có thể đi qua vật cản phá được và enemy sẽ phá trước khi đi qua. Mỗi đợt phân phối địch luân phiên qua danh sách spawn theo thứ tự node trong scene.

Ưu tiên kéo scene từ `scenes/objects/` vào map. Instance tham chiếu `MapObjectDefinition` dùng chung; Make Unique để tạo biến thể riêng. Catalog ở `assets/map_objects/catalog.tres` không giới hạn object theo theme. Xem [object môi trường](environment-objects.md).

Để tạo object standalone, thêm `Node2D`, gán `gd/map_object.gd` và để `definition` trống, rồi chỉnh các trường sau:

| Trường | Ý nghĩa |
| --- | --- |
| `category` | `decoration`, `fixed`, `destructible`, `pickup` |
| `texture`, `visual_rect` | Artwork và hình chữ nhật ảnh riêng với footprint |
| `footprint`, `footprint_offset` | Kích thước/offset tính bằng ô, bắt đầu từ ô chứa vị trí node |
| `move_blocked`, `bullet_blocked` | Flags cho fixed/destructible; decoration luôn bỏ qua flags |
| `initial_hp`, `steel` | HP của vật phá được, và yêu cầu damage phá thép nếu bật |
| `drop_settings` | PickupSettings ghi đè cho vật cản; để trống dùng map settings |
| `pickup_category`, `pickup_id` | Item gán rõ; ID trống trên destructible dùng random, pickup đặt sẵn phải có ID |

Vật cản cần footprint dương, không xoay hoặc scale kể cả qua group cha. Artwork có thể lớn hơn footprint. Các ô footprint dùng chung một dictionary runtime, nên một phát damage trừ HP của toàn object; phá object giải phóng toàn footprint và ẩn artwork. Terrain bên dưới không bị thay thế. Decoration đặt tự do và không tham gia collision/pathfinding. Pickup đặt sẵn được chuyển thành pickup runtime để dùng cùng lifetime, collection và giới hạn với item sinh trong trận.

## Pickup settings và validation

Root có `pickup_settings`, mặc định là `assets/maps/default_pickups.tres`. Resource chứa luật rơi, pool/trọng số, chu kỳ sinh, giới hạn power-up, lifetime chung và lifetime theo ID. Make Unique trước khi ghi đè riêng cho map. Weapon gán rõ vẫn được giữ dù character không tương thích; kiểm tra lúc nhặt quyết định có thể thay weapon hay không. Settings và drop override được deep-copy cho từng trận.

`build_runtime(catalog)` trả về grid, dimensions, vị trí base/player và `player_two_position` (Vector2.INF khi thiếu), enemy spawns, base goal, objects, settings và errors. Validation báo kích thước, thiếu marker, marker bị chặn/ngoài map hoặc chồng căn cứ, spawn không có đường tiếp cận, sai metadata tile, transform sai, footprint ngoài map/chồng vật cản, ID pickup sai hoặc trùng vị trí, cấu hình pool/trọng số/lifetime và quá nhiều power-up đặt sẵn. Root scene cung cấp configuration warnings trong editor; simulation không bắt đầu map sai cấu hình.

Chạy `make test` để kiểm tra map nguồn scene, kích thước khác nhau, metadata, object nhiều ô, phá hủy, pickup và camera. Chạy `make test-visual` để kiểm tra ảnh runtime. Chi tiết [đường đi](navigation.md), [camera](camera.md), [power-up và weapon pickup](../power-ups.md) và [QA map](../../qa/maps.md).

Chế độ tấn công và streaming/chunk chưa được triển khai. Giới hạn kích thước hiện tại là hợp đồng validation cho grid thủ thành; thêm vùng đất lớn cần thiết kế runtime riêng thay vì bỏ giới hạn cấp phát.
