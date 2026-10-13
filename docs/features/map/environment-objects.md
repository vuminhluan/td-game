# Object môi trường và hình weapon pickup

## Quyết định ngày 2026-10-13

Giữ phong cách nhà máy cũ của map công nghiệp: thép bạc màu, sơn bong, rỉ sét, chi tiết cơ khí và ánh sáng đồng bộ với terrain hiện có. Artwork object dùng bitmap có alpha thật. Weapon pickup dùng đúng artwork weapon đang gắn trên nhân vật, không tạo icon súng khác.

Máy móc, ống nước và robot bỏ hoang không phá được. Di chuyển và đạn có flags độc lập:

| Object mẫu | Chặn di chuyển | Chặn đạn | Phá được |
| --- | --- | --- | --- |
| Lon nước trên sàn | Không | Không | Không |
| Ống nước ngang đường | Có | Không | Không |
| Máy móc | Có | Có | Không |
| Robot bỏ hoang | Có | Có | Không |

Object catalog độc lập với map/theme. Designer được dùng object công nghiệp trên map thành phố hoặc bất kỳ map nào; theme không lọc hoặc hạn chế danh sách object. Theme chỉ gợi ý artwork cho map. Một Resource định nghĩa hình ảnh, visual rect, footprint và flags; scene instance tham chiếu Resource đó để tái sử dụng và chỉnh vị trí trực quan. Hình ảnh không quyết định collision bằng alpha hoặc kích thước texture.

## Rìa map

Bố cục hiện tại dùng hai cụm cấp nước dọc biên, đi cùng map khi camera cuộn; xem [thiết kế layout](industrial-layout.md). Máy nén, cụm ba ống và xác robot còn trong catalog nhưng không đặt trong map mẫu. Các vật thể có footprint vẫn dùng collision/pathfinding chung. Bố trí phải giữ vùng spawn, player, căn cứ và tuyến tiếp cận hợp lệ. Object trang trí trên sàn có thể đặt tự do. Không tự ghim máy móc vào rìa màn hình vì camera có thể nhìn vào giữa một map lớn.

## Weapon pickup

Ưu tiên hình weapon của character hiện tại; với weapon không tương thích vẫn hiển thị hình từ character hỗ trợ weapon đó. Chỉ chọn artwork, không đổi luật compatibility lúc nhặt. Dùng vùng sprite từ atlas nhân vật và bỏ khoảng alpha trống để hình dễ đọc ở kích thước pickup. Bóng/viền sáng là hiệu ứng trình bày; không dùng hình súng bằng đường vẽ làm biểu tượng thay thế.

## Nguồn và mở rộng

Nguồn generation giữ dưới `assets/generated/map/industrial/objects/`, assets runtime và object definitions nằm trong catalog riêng của object. Bổ sung bộ thành phố bằng Resource/scene mới mà không thêm bảng luật theo theme trong code. Giữ prompts, raw PNG và manifest cho bộ đang dùng. Các kiểm tra artwork, flags, footprint, placement và pickup sẽ được ghi trong QA sau khi hoàn thành.

## Dùng trong Godot

Catalog tổng ở `assets/map_objects/catalog.tres` tham chiếu các Resource riêng ở `assets/map_objects/industrial/`. Scene kéo thả tương ứng nằm trong `scenes/objects/industrial/`: `machinery.tscn`, `pipes.tscn`, `robot_wreck.tscn`, `drink_can.tscn`, cùng `single_pipe.tscn`, `water_pump.tscn`, `water_pump_right.tscn` và hai prefab `water_line_west/east.tscn`. Kéo scene vào bất kỳ map nào rồi đổi vị trí node. `tags` chỉ là metadata để tổ chức; không kiểm tra theme của map.

`gd/map_object_definition.gd` định nghĩa hình ảnh và gameplay; `gd/map_object.gd` là instance có vị trí. Khi instance có `definition`, Inspector chỉ hiện Resource này và ẩn các trường standalone để tránh hai nơi chỉnh cùng một giá trị. Chỉnh Resource dùng chung để đổi mọi instance; Make Unique nếu muốn biến thể riêng. Artwork/visual rect/footprint đổi trong Resource sẽ cập nhật preview editor. Các node standalone vẫn dùng các trường cũ để designer tạo object riêng mà chưa cần đưa vào catalog; cả hai cách đều tạo cùng cấu trúc runtime và dùng cùng validation/collision/pathfinding.

Snapshot gameplay được tạo khi bắt đầu simulation. HP, alive và các flags runtime không sửa Resource dùng chung. Máy và robot chặn cả di chuyển/đạn; ống chỉ chặn di chuyển. Radar cũng đọc flags object để thể hiện footprint chặn đường. Map mẫu dùng hai tuyến ống đơn nối vào bơm và hai lon cạnh khu bảo trì, vẫn giữ cả ba spawn có đường đến căn cứ.

## Artwork và tái tạo Resource

Sáu PNG sinh riêng bằng **ImageGen tích hợp**, không dùng API/CLI trả phí. Ảnh nguồn alpha được giữ nguyên byte; runtime cũng dùng cùng PNG. AtlasTexture cắt vùng hiển thị, không thay alpha hay repaint ảnh. Ngưỡng alpha 0,1 trong installer chỉ chọn visual region để bỏ padding/haze rất nhạt; footprint khai báo độc lập và không suy từ vùng này.

Prompts và request chính xác:

- machinery: [prompt](../../../assets/generated/map/industrial/objects/machinery/prompt.txt), [request](../../../assets/generated/map/industrial/objects/machinery/request.json), [PNG nguồn](../../../assets/generated/map/industrial/objects/machinery/source.png).
- pipes: [prompt](../../../assets/generated/map/industrial/objects/pipes/prompt.txt), [request](../../../assets/generated/map/industrial/objects/pipes/request.json), [PNG nguồn](../../../assets/generated/map/industrial/objects/pipes/source.png).
- wreck: [prompt](../../../assets/generated/map/industrial/objects/wreck/prompt.txt), [request](../../../assets/generated/map/industrial/objects/wreck/request.json), [PNG nguồn](../../../assets/generated/map/industrial/objects/wreck/source.png).
- can: [prompt](../../../assets/generated/map/industrial/objects/can/prompt.txt), [request](../../../assets/generated/map/industrial/objects/can/request.json), [PNG nguồn](../../../assets/generated/map/industrial/objects/can/source.png).

[Ống đơn và bơm](industrial-layout.md#artwork-và-kiểm-tra) có source/prompt riêng cho bố cục mới. Pipes/can dùng machinery làm style reference; wreck dùng machinery và atlas character làm reference. Runtime PNG/TRES nằm trong `assets/map_objects/industrial/`; [manifest](../../../assets/map_objects/industrial/manifest.json) ghi từng đường dẫn asset, nguồn và SHA-256. Nguồn generation được loại khỏi import/export bởi `.gdignore` của `assets/generated/`.

Tái tạo vùng sprite, visual rect và catalog từ PNG đã chọn:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script scripts/install_environment_art.gd
make test
make test-visual
```

Installer chỉ cập nhật texture/AtlasTexture trên Resource đã tồn tại, giữ visual rect, footprint, flags và các chỉnh sửa của designer. Giá trị seed trong script chỉ dùng lần tạo Resource đầu tiên. Catalog giữ cả các entry khác chủ đề khi tái xuất bộ công nghiệp. Installer không sinh hoặc sửa layout map. Layout biên được lưu trực tiếp trong scene mẫu, designer có thể thay tự do. Khi thay PNG, chạy installer rồi kiểm tra visual vì bounds có thể thay đổi; không đổi footprint theo alpha.

Weapon pickup được cache bởi `gd/weapon_pickup_art.gd`, đọc manifest character và tạo AtlasTexture từ đúng sprite súng hướng phải. Không tạo bitmap súng thứ hai. Nhân vật/weapon khác có art binding riêng nên pickup ưu tiên cùng hình mà nhân vật đó sẽ trang bị. Không dùng animation/muzzle flash của súng trên mặt đất.

## QA

Xem [QA object và artwork](../../qa/environment-objects.md). Screenshot [object và weapon pickup trong game](../../images/industrial-objects-in-game.png) là fixture full-map ở zoom 0,75 để thấy cả hai biên; camera lúc chơi vẫn theo player.
