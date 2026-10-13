# Terrain và đường đi của enemy

`gd/battle_map.gd` tạo grid terrain và kiểm tra vị trí có thể chiếm. Logic này độc lập với [hình ảnh map](art.md).

`find_path()` dùng Dijkstra với bốn hướng kề nhau. Ô gạch có chi phí 7 để enemy có thể chọn đường cần phá tường khi phù hợp; các ô đi được khác có chi phí 1. Thép và nước không được đưa vào đường đi, còn vị trí ngoài map bị loại.

Việc gạch xuất hiện trong đường đi không có nghĩa robot có thể đi xuyên gạch: `can_occupy()` vẫn chặn gạch, thép và nước. Enemy phải phá gạch trước khi di chuyển qua ô đó. Khi gạch bị phá, simulation chuyển kind thành `floor`, tăng revision và xóa target hiện tại của enemy để đường đi được cập nhật.

Giữ sự khác biệt giữa chi phí tìm đường và va chạm khi sửa map. Kiểm tra luật terrain và hành vi enemy bằng `godot_tests/acceptance.gd`, chạy trong `make test`.

Thép có 5 HP nhưng đạn thường không trừ HP. `damage_wall(point, true)` hỗ trợ luật damage cho phép phá thép về sau; dùng chung revision, cập nhật đường đi và [rơi power-up](../power-ups.md) với gạch.
