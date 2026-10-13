# Bố cục map nhà máy cũ

## Thiết kế lại ngày 2026-10-13

Mục tiêu là giảm cảm giác dày đặc và làm các object có lý do tồn tại. Thay các máy, cụm ba ống và xác robot rải đều bằng hai cụm cấp nước ở mép trái/phải. Mỗi cụm có một đường ống đơn dọc, nối liên tục từ biên phía trên xuống đầu hút của mô tơ bơm nước. Bố trí lệch độ dài giữa hai bên để tránh cảm giác lặp một bộ trang trí theo hàng.

Ống có module dọc dùng lại; prefab cụm cấp nước gom các đoạn ống và bơm thành một cụm editor. Ghép module nối đầu-cuối, không rải từng đoạn vào giữa chiến trường. Bơm bên phải đảo artwork theo chiều ngang để đầu hút nằm sát biên phải; footprint gameplay vẫn khai báo riêng, không xoay node collision.

Giảm các cụm tường/thép lặp ở giữa. Giữ một ít cover gạch, hai khoang thép phía trên và rãnh nước gần khoang máy; để trung tâm, vùng trước căn cứ và các đường tiếp cận thoáng. Chỉ có hai lon gần vị trí bảo trì bơm, không có rác rải giữa đường chiến đấu. Xác robot, máy nén và cụm ba ống vẫn giữ trong catalog cho designer/map khác.

Bỏ toàn bộ cell cỏ khỏi scene industrial yard. Không xóa `grass.png`, nguồn generation, binding MapSkin hoặc tile grass trong TileSet. Các map khác vẫn có thể vẽ grass; fixture test lấy metadata từ TileSet để loại tile chưa đặt trên map mẫu vẫn có thể được kiểm tra.

## Invariants bố trí

- Ba spawn địch và spawn player/base giữ hợp lệ; enemy vẫn có đường tới base.
- Ống chặn đi nhưng không chặn đạn; bơm chặn cả hai. Các object cố định không phá được.
- Hai tuyến ống ở cột sát biên, không chồng footprint terrain/object hoặc cắt tuyến giữa map.
- Đầu module ống khớp đầu module kế tiếp và đầu hút bơm ở world space.
- Collision/footprint không lấy từ alpha artwork. Object/scene dùng được trên mọi map, không hạn chế theo theme.

Layout nguồn là `scenes/maps/industrial_yard.tscn`; [object và catalog](environment-objects.md) mô tả cách designer đặt hoặc thay Resource. Kết quả kiểm tra và preview được cập nhật sau khi rendering native.

## Resource và các cụm editor

- `single_pipe.tscn`: một ống thẳng dọc, module dài 160 units, footprint 1×4; nối đầu-cuối khi duplicate.
- `water_pump.tscn` và `water_pump_right.tscn`: bơm footprint 2×1; biến thể phải dùng cùng PNG và mirror hình, không mirror collision node.
- `water_line_west.tscn`: ba module từ y=0 tới y=480, sau đó là bơm. Map đặt ở x=0.
- `water_line_east.tscn`: hai module từ y=0 tới y=320, sau đó là bơm. Map đặt ở x=760; ống ở x=800, ngay cột cuối cùng.

Các prefab nằm trong `scenes/objects/industrial/`. Designer có thể kéo cả cụm hoặc từng object vào map khác. `MapObjectDefinition.connections` lưu các điểm nối trong tọa độ local trước mirror; `connection_point()` áp dụng mirror giống renderer. Chỉnh `flip_h` không thay footprint. Metadata điểm nối không suy từ alpha.

Có 18 ô gạch, 8 ô thép và 4 ô nước; không có ô cỏ. Khoảng 86,5% ô grid không bị terrain/object chặn di chuyển. Trung tâm không có scenery; hai lon nằm trong khu bảo trì ở cạnh bơm. Căn cứ, player spawn và ba enemy spawn giữ vị trí hiện có.

## Artwork và kiểm tra

Hai PNG mới dùng **ImageGen tích hợp**, giữ alpha và file nguồn nguyên byte:

- Ống đơn: [runtime](../../../assets/map_objects/industrial/single_pipe.png), [prompt](../../../assets/generated/map/industrial/objects/single_pipe/prompt.txt), [request](../../../assets/generated/map/industrial/objects/single_pipe/request.json).
- Bơm nước: [runtime](../../../assets/map_objects/industrial/water_pump.png), [prompt](../../../assets/generated/map/industrial/objects/water_pump/prompt.txt), [request](../../../assets/generated/map/industrial/objects/water_pump/request.json).

[Manifest](../../../assets/map_objects/industrial/manifest.json) ghi source, region và SHA-256. Artwork/catalog cũ và toàn bộ asset cỏ được giữ. Pipeline tái xuất vẫn giữ footprint/flags/visual rect đã chỉnh.

`make test` và `make test-visual` pass. Test kiểm tra nối ống tới bơm, vị trí sát biên, phần lớn sàn đi được, grass không được đặt nhưng vẫn có thể dùng từ TileSet, compatibility/collision/pickup, AI tới căn cứ và native rendering. [Preview toàn map](../../images/industrial-objects-in-game.png) dùng fixture zoom 0,75 để thấy bố cục; lúc chơi camera vẫn theo player. Native landscape cũng được kiểm tra bằng runner camera.

[Ảnh toàn cảnh không HUD](../../images/industrial-layout-overview.png) được render trực tiếp bằng BattleView ở scale 1 để xem vị trí ống/bơm và khoảng trống trên map.

## Sửa hướng đầu nối và bổ sung van

Artwork bơm được sửa bằng ImageGen tích hợp: bỏ cổ hút dựng khỏi mặt sàn, thay bằng ống nằm trong mặt phẳng sàn và co 90° rẽ vào bên hông thân bơm. Mỗi bơm có một van tay quay đỏ trước co, nằm trong cùng sprite; không thêm van vào mọi module ống. Bơm phải mirror toàn bộ cụm nên hai phía có cùng cấu trúc nối.

Điểm ghép thật trong PNG là `(531, 166)`, với atlas region `(404, 131, 1178, 679)`. Visual rect được căn theo điểm này: inlet bên trái ở local `(20, 0)`, bên phải sau mirror ở `(60, 0)`. Stub lồng vào mặt bích khoảng 2 world units để phần alpha ở mép crop không tạo khe hở. Sprite giữ tỷ lệ gốc; footprint bơm vẫn 2×1, các flags di chuyển/đạn không đổi. Điểm inlet raw của biến thể mirror có giá trị khác vì visual rect có offset khác; luôn dùng `connection_point()` khi ghép prefab.

Nguồn edit và hai bước sửa được ghi trong [request](../../../assets/generated/map/industrial/objects/water_pump/request.json); các ảnh/prompt đầu vào nằm ở `assets/generated/map/industrial/objects/water_pump/inputs/` và được giữ vì request edit phụ thuộc chúng. Installer seed dùng visual rect đã căn; tái xuất giữ các Resource do designer chỉnh.

[Ảnh hai cụm cấp nước](../../images/industrial-water-line-detail.png) được render bằng BattleView native ở scale 3 để xem co, van và mặt bích. `environment_objects_visual.gd` tái tạo cả ảnh chi tiết lẫn overview. Ngoài kiểm tra tọa độ nối, cần xem ảnh ở tỉ lệ chơi và ảnh chi tiết: tọa độ trùng nhau không chứng minh hướng cơ khí trong artwork đúng.
