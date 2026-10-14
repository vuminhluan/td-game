# QA map thành phố bỏ hoang

## Phạm vi kiểm tra thiết kế mới

`godot_tests/map_selection.gd` kiểm tra map hợp lệ, cả ba spawn tới căn cứ, đường sáu lane và ngã tư bốn hướng, đường/vạch sơn đi qua được, không có terrain phá hủy hay bụi cỏ. Hai mẫu xe có hướng ngang/dọc; xe và một đến hai đèn đổ chặn toàn footprint nhưng đạn xuyên, không mất HP và không thể bị phá để mở đường. Nắp cống cho phép actor và đạn đi qua.

Kiểm tra art dùng crop alpha có gutter đủ bốn phía; xe và bụi cỏ dùng atlas riêng; resource bụi cỏ vẫn dùng được ngoài map thành phố. Phần thân xe với alpha từ 0.1 trở lên phải phủ ít nhất 75% một chiều của frame, tránh lỗi thu nhỏ xe do alpha nhiễu rất mờ. SHA-256 source/runtime và metadata extraction được đối chiếu với manifest. Luồng chọn map trước chọn nhân vật và replay theo map đã chọn được kiểm tra.

`godot_tests/map_selection_visual.gd` chụp preview native, màn chọn map desktop/mobile, chọn nhân vật, battle desktop và battle điện thoại ngang. Script xác nhận viewport desktop chứa trọn lưới chơi và camera mobile cuộn theo robot. Nhóm `map_camera` kiểm tra camera chung.

## Kết quả

Đã chạy trên Godot 4.7.2, ngày 14/10/2026:

| Kiểm tra | Kết quả |
| --- | --- |
| `godot_tests/map_selection.gd` | 630 checks, 0 failures |
| Camera headless / native | 325 / 81 checks, 0 failures |
| Suite logic `make test` | Pass |
| Toàn bộ script trong `test-visual`, chạy native từng lệnh | Pass |
| `godot_tests/map_selection_visual.gd` native | 3 checks, 0 failures |
| Preview native, reimport, rồi chụp màn chọn map | Pass; thẻ thành phố đọc thumbnail mới |
| Xem overview, battle desktop và hai vị trí mobile | Đủ sáu lane, ngã tư mở, sprite xe giữ đủ đầu/đuôi và kích thước rõ, nhà có alpha, robot hiển thị trong camera |

Các screenshot được chụp khi simulation không tiến thời gian và được xem trực tiếp sau khi lưu. Sau khi di chuyển robot bằng script để kiểm tra camera, actor được queue redraw trước khi chụp để tránh ảnh lưu vị trí cũ.

## Bằng chứng hình ảnh

- `assets/maps/previews/abandoned-city.png`: overview render native và texture cho thẻ chọn map.
- `docs/images/abandoned-city-in-game.png`: battle desktop thấy toàn map.
- `docs/images/abandoned-city-mobile.png`: battle trên điện thoại ngang, camera gần đầu đại lộ.
- `docs/images/map-selection-desktop.png` và `docs/images/map-selection-mobile.png`: chọn map.
- `docs/images/character-selection-desktop.png`: bước chọn nhân vật sau khi xác nhận map.
- `/private/tmp/abandoned-city-mobile-intersection.png`: khung mobile tại ngã tư trong lần chạy visual.

## Giới hạn

Native resize xác minh bố cục và camera, không thay thế kiểm tra cảm ứng hoặc khóa hướng trên thiết bị thật. Kiểm tra alpha gutter phát hiện crop chạm biên; nhận diện nội dung sprite hoàn chỉnh vẫn cần xem ảnh native. Preview là texture tĩnh, phải chụp lại khi sửa scene. Các cảnh test khóa spawn để giữ screenshot ổn định; hành vi chiến đấu đầy đủ được kiểm tra trong suite simulation và acceptance.
