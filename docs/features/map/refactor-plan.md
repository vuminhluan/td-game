# Kế hoạch refactor hệ thống map

Tài liệu này ghi lại phạm vi và quyết định của refactor map, đã triển khai ngày 2026-10-13. Hướng dẫn hiện hành ở [biên soạn map](authoring.md), [camera và input](camera.md), [pickup](../power-ups.md) và [QA refactor](../../qa/map-refactor.md). Chế độ tấn công chỉ được tính đến trong kiến trúc; lần refactor này chưa triển khai chế độ đó. Kiểm tra khóa landscape/safe area/touch trên export handheld thật chưa được xác nhận; kiểm thử native resize và input mô phỏng đã được thực hiện.

## Mục tiêu và đầu ra

- Cho designer tạo và chỉnh sửa map trực quan trong Godot.
- Hỗ trợ nhiều map có kích thước khác nhau; giữ kích thước ô gameplay là 40 world units.
- Dùng một map công nghiệp mẫu có thể chơi được để kiểm tra sau refactor, dựa trên phong cách hiện tại.
- Bổ sung object trang trí hợp chủ đề công nghiệp, chẳng hạn cụm máy, đường ống, thùng hoặc thiết bị nhà máy. Object trang trí không được vô tình tham gia collision hay pathfinding.
- Chuẩn bị cấu trúc dùng lại cho một vùng đất liên tục của chế độ tấn công trong tương lai, nhưng không thêm luật chơi của chế độ đó trong lần này.
- Xóa hẳn layout hard-code và renderer map cũ khi đường mới đã thay thế; không để hai hệ thống map song song.

## Kiến trúc dự kiến

### Scene map làm nguồn layout

Mỗi map là một scene có metadata về ID, chế độ được hỗ trợ, kích thước và TileSet. Tile size của gameplay giữ ở 40 units; số hàng/cột do scene map quyết định.

- Dùng `TileMapLayer` cho nền và địa hình dạng ô, để designer vẽ bằng Godot editor.
- Địa hình định nghĩa thuộc tính gameplay như đi được, chặn đạn, phá được và HP ban đầu. Những thuộc tính này gắn với loại tile, không được chép sang một bảng luật hard-code độc lập.
- Dùng node/scene riêng cho object đặt trên map. Object trang trí có thể đặt tự do; vật cản có collision, footprint và luật gameplay được khai báo rõ. Footprint có thể chiếm nhiều ô.
- Dữ liệu runtime được tạo từ scene map. Simulation sở hữu trạng thái thay đổi trong trận như HP, bị phá, pickup đã nhặt và thời gian tồn tại; renderer đọc cùng trạng thái runtime đó.
- Tránh đồng bộ thủ công giữa layout editor, collision, pathfinding và ảnh hiển thị. Không suy ra luật gameplay từ alpha của sprite.

### Vị trí gameplay và validation

- Căn cứ và ít nhất một điểm spawn địch là bắt buộc ở map thủ thành.
- Điểm spawn player là tùy chọn. Nếu thiếu, game đặt player ở vị trí hợp lệ gần căn cứ.
- Marker spawn có icon trong editor để kéo thả và không hiển thị trong trận.
- Designer có thể đặt nhiều điểm spawn địch; luật đợt lấy các điểm này từ map thay vì dùng tọa độ cố định trong code. Chính sách phân phối giữa các điểm sẽ được chốt khi triển khai gameplay.
- Map sai yêu cầu cần được chỉ rõ khi kiểm tra, không âm thầm dùng các tọa độ cũ trong code.
- Kiểm tra thêm vùng đặt căn cứ/player/spawn, kích thước map, footprint object và tổng power-up đặt sẵn so với giới hạn runtime.

### Object trên map

Object được phân loại rõ để designer không phải dựa vào tên sprite để suy ra hành vi:

- Đồ trang trí: chỉ hiển thị, đặt tự do, không chặn di chuyển/đạn và không tham gia pathfinding.
- Vật cản cố định: có collision/gameplay flags theo cấu hình, không bị phá.
- Vật cản phá được: có HP, footprint, hiệu ứng khi phá và luật rơi pickup.
- Pickup: power-up hoặc weapon, đặt sẵn trong map hoặc được tạo trong lúc chơi.

Object nhiều ô khai báo footprint gameplay riêng với rect hình ảnh. Hình ảnh có thể lớn hơn footprint, nhưng collision và pathfinding phải dùng dữ liệu rõ ràng, không kích thước texture.

## Pickup và luật mặc định

Giá trị mặc định đặt ở một cấu hình chung, có thể ghi đè ở cấp map; vật cản cụ thể có thể chọn item cố định hoặc ghi đè luật rơi. Nếu designer không chỉnh pool/trọng số, các loại hợp lệ trong pool được chọn ngang nhau.

### Vật cản phá được

- Luật rơi bật mặc định cho tất cả vật cản phá được.
- Mỗi lần phá có 40% cơ hội rơi một pickup.
- Khi có pickup, xác suất danh mục là 70% weapon và 30% power-up.
- Weapon rơi ngẫu nhiên chỉ được chọn trong số weapon mà character hiện tại dùng được.
- Designer có thể gán power-up/weapon cụ thể cho một vật cản hoặc giữ lựa chọn ngẫu nhiên. Gán cụ thể không bị lọc khỏi map chỉ vì weapon không hợp character; character không tương thích thì không nhặt được pickup đó.

### Sinh power-up định kỳ

- Luồng này chỉ sinh power-up, không sinh weapon.
- Designer có thể bật/tắt, đổi khoảng thời gian, số lượng mỗi lần, pool và trọng số.
- Mặc định giữ nhịp hiện tại: mỗi 5 giây thử sinh 1–2 power-up.
- Một giới hạn chung là tối đa 10 power-up đồng thời. Tính cả món đặt sẵn, món sinh định kỳ và món rơi từ vật cản. Khi đủ giới hạn, không tạo thêm; có chỗ trống thì lần thử tiếp theo có thể sinh lại.
- Map có số power-up đặt sẵn vượt giới hạn phải báo lỗi validation.

### Thời gian tồn tại và thay weapon

- Mọi pickup mặc định tồn tại 20 giây kể từ lúc xuất hiện.
- Designer có thể đặt thời gian riêng theo từng loại power-up hoặc weapon trong cấu hình map.
- Weapon không có giới hạn số lượng tồn tại đồng thời trên map.
- Nhặt weapon tương thích thay weapon hiện tại ngay lập tức. Weapon mới giữ đến khi nhặt weapon khác hoặc kết thúc lượt, kể cả khi player hồi sinh. Khởi động lượt mới dùng lại loadout đã chọn trước trận.
- Pickup weapon không tương thích có thể xuất hiện nếu designer đặt/gán rõ, nhưng character không thể nhặt nó.

## Camera và thiết bị

- Player di chuyển liên tục theo hướng nhấn; lưới chỉ dùng để dựng địa hình, footprint và tính gameplay.
- Camera cuộn theo player và bị giới hạn trong biên map. Map nhỏ hơn vùng nhìn được căn giữa; map lớn chỉ lộ phần quanh player.
- Giữ tile size nhất quán trong world units. Tỉ lệ trình bày thích ứng viewport ngang thay vì yêu cầu mọi map phải fit toàn màn hình.
- Chế độ handheld khóa landscape. Dự án hiện đã khai báo hướng handheld; lần refactor cần xác nhận lại trên export chạy thật.
- HUD và nút cảm ứng nằm ở lớp màn hình, không di chuyển cùng camera. Tính toán input phải chuyển đúng giữa screen space và world space.
- Cần bố trí HUD cho nhiều độ phân giải/tỉ lệ ngang và vùng an toàn của thiết bị; không giả định một kích thước điện thoại duy nhất.

## Phạm vi không làm trong lần refactor

- Không triển khai chế độ tấn công, AI/đối tượng căn cứ địch hay objective riêng của chế độ đó.
- Không thêm hệ thống inventory nhiều weapon; pickup chỉ thay weapon đang dùng.
- Không giữ đường fallback đọc layout hard-code cũ sau khi map scene mới hoạt động.

## Tiêu chí hoàn thành

- Có ít nhất một map công nghiệp mẫu, dùng phong cách map hiện tại và object trang trí công nghiệp mới, có thể chạy và chơi được.
- Designer có thể mở scene trong Godot, vẽ terrain, đặt object/marker, lưu scene và thấy kết quả trong game mà không sửa tọa độ trong script.
- Map có kích thước khai báo riêng; camera theo player, dừng đúng ở biên và hoạt động trong layout ngang trên nhiều tỉ lệ màn hình.
- Căn cứ, spawn địch bắt buộc; spawn player tùy chọn và fallback gần căn cứ hoạt động.
- Địa hình, object nhiều ô, collision, pathfinding, phá hủy và renderer cùng phản ánh một trạng thái runtime nhất quán.
- Pickup áp dụng đúng pool, trọng số, giới hạn đồng thời, lifetime và luật tương thích weapon đã nêu.
- Tất cả map/object sai cấu hình có thông báo validation hữu ích.
- Layout procedural cũ, hằng số kích thước map toàn cục và renderer cũ được gỡ bỏ hoặc chuyển hoàn toàn; cập nhật tài liệu, index và kiểm tra liên quan.
