# QA bố cục nhà máy thoáng — 2026-10-13

Thiết kế hiện hành ở [industrial layout](../features/map/industrial-layout.md). Map giữ 21×19 ô, kích thước ô 40 units, vị trí căn cứ/player và ba điểm spawn. Scene vẫn là nguồn layout duy nhất.

## Kết quả

- Terrain được vẽ giảm từ 90 ô xuống 30: 44→18 brick, 24→8 steel, 8→4 water và 14→0 grass.
- Bỏ 8 object lớn lặp ở hai biên và 6 lon rải rác. Thay bằng hai cụm cấp nước có 5 module ống đơn, 2 bơm và 2 lon trong khu bảo trì.
- Ống đặt ngay cột đầu/cuối map, nối đầu-cuối và kết thúc ở inlet của bơm. Bên phải mirror artwork; footprint vẫn đặt theo grid bình thường.
- 345/399 ô (86,5%) không bị terrain/object chặn đi; khu chiến đấu giữa map không có object trang trí. Cả ba spawn vẫn có đường tới base.
- Không xóa grass PNG, sources, TileSet grass hoặc renderer bindings; tile unused được kiểm tra thông qua metadata TileSet.

## Kiểm thử

Godot 4.7.2, macOS Apple M4 Pro, renderer Compatibility. `make test` pass với **2474 checks có bộ đếm**, cộng player mech integration/56 atlas frames. Suite environment có 150 checks, bao gồm nối ống, mirror inlet, các boundary column, phần sàn trống, absence/reuse grass và tất cả catalog definitions (kể cả object không đặt trong map mẫu). Fixture power-up dùng ô sàn hợp lệ mới thay cho ô đã trở thành ống sát biên; kiểm tra overlap và cô lập vùng vẫn được giữ.

Ở lần kiểm tra bố cục đầu tiên, `make test-visual` pass cả 9 suite: environment 13 checks và camera native 82 checks; các suite khác không có failures. Đã xem preview toàn map và native landscape. Các điểm nối trùng tọa độ và tâm map thoáng, nhưng artwork ban đầu vẫn có cổ hút dựng khỏi sàn; kiểm tra tọa độ chưa phát hiện sai hướng này. [Preview](../images/industrial-objects-in-game.png) là fixture zoom 0,75, có weapon pickup mẫu để kiểm tra hình; camera thật vẫn cuộn theo player. Damage/replay, desktop/mobile HUD, pause và asset rendering tiếp tục pass.

Hai PNG mới dùng ImageGen tích hợp; source PNG/request/prompt nằm trong `assets/generated/map/industrial/objects/single_pipe/` và `water_pump/`. Runtime PNG khớp nguồn và SHA-256 trong manifest; biến thể bơm phải dùng cùng texture. Không thay hoặc xóa source/artwork/catalog cũ. `git diff --check` và link tài liệu nội bộ pass.

Đây là kiểm tra gameplay/rendering native, chưa phải đánh giá cân bằng độ khó bằng playtest dài hoặc xác nhận thiết bị thật/Web export.

Đã render thêm [overview không HUD](../images/industrial-layout-overview.png) bằng BattleView trực tiếp, scale 1; ảnh 840×760 cho thấy toàn layout và các đầu nối mà không crop map.

## Kiểm tra bản sửa đầu nối và van

Bản sửa dùng cùng PNG cho hai bơm, với đầu hút nằm dọc mặt sàn, co 90° nối bên hông và một van tay quay đỏ mỗi cụm. Visual rect căn theo socket trong PNG và lồng stub vào mặt bích khoảng 2 units. Footprint, collision flags, số object, terrain và đường đi giữ nguyên.

Chạy lại toàn bộ `make test`: **2474 checks có bộ đếm pass**, cộng player mech integration; suite environment có **150 checks, 0 failures**. Chạy native `environment_objects_visual.gd`: **15 checks, 0 failures**, gồm các checks render hiện có và lưu hai ảnh layout bổ sung. Đã xem [ảnh chi tiết hai cụm](../images/industrial-water-line-detail.png) ở scale 3 và overview scale 1 để xác nhận hướng ống, van và chỗ ghép. Đây là kiểm tra trực quan bổ sung; assertion tọa độ không thay thế việc xem hướng cơ khí của sprite. Source/runtime PNG khớp SHA-256 manifest; source edit giữ các đầu vào cần để truy lại hai bước sửa. Tái chạy installer giữ geometry/flags/connections trong sai số serialization float; 7 source hashes và links tài liệu pass. `git diff --check` pass.
