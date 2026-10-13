# Terrain, footprint và đường đi

`gd/map_definition.gd` đọc TileMapLayer và object trong scene để tạo runtime grid có kích thước riêng. Luật tile đến từ custom data của TileSet; xem [hướng dẫn tạo map](authoring.md). `gd/battle_map.gd` cung cấp tra ô, kiểm tra vùng actor và tìm đường, không tạo layout bằng tọa độ trong script.

`can_occupy()` kiểm tra mọi ô giao với hình vuông collision của actor. Cả terrain và object còn sống có thể chặn di chuyển. Object nhiều ô có footprint riêng; các ô giữ reference tới cùng dictionary object. Decoration không có footprint gameplay. Khi object bị phá, flags của object không còn hiệu lực và terrain bên dưới tiếp tục có hiệu lực.

`find_path()` dùng Dijkstra với bốn hướng kề nhau. Ô đi được có chi phí 1. Ô chặn di chuyển nhưng phá được có chi phí 7 để enemy có thể chọn đường cần phá vật cản. Vật cản không phá được và vật cản yêu cầu phá thép bị loại khỏi đường đi. Enemy phải phá vật cản trước khi di chuyển qua; đường đi không cho phép xuyên tường.

Destruction thay đổi runtime flags, HP và revision. Renderer dùng cùng grid và object state để xóa cell trong TileMapLayer hoặc ẩn object. Revision cũng làm enemy tính lại đường. Căn cứ và ô tiếp cận được lấy từ marker và ô hợp lệ gần marker; enemy spawns lấy từ scene. Validation từ chối spawn không có đường tới ô tiếp cận căn cứ.

Tile thép mẫu có HP 5 và `steel = true`: đạn thường không trừ HP; `damage_wall(point, true)` hỗ trợ damage được phép phá thép. Hành vi này dùng flags, không dựa vào `kind`. Kind phục vụ artwork damage và hiệu ứng hiển thị.

Kiểm tra map trong `godot_tests/map_refactor.gd`, terrain/AI trong `godot_tests/acceptance.gd`, chạy bằng `make test`.
