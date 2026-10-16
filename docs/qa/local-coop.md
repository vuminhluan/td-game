# QA Local Co-op

Kiểm tra ngày 15/10/2026 bằng Godot 4.7.2 trên macOS, renderer Compatibility. Hành vi và API ở [Local Co-op](../features/local-coop.md).

## Regression tự động

`make test` chạy toàn bộ regression Single Player và bốn suite co-op:

- `godot_tests/local_coop_map.gd`: marker P2 tùy chọn, marker trùng/bị chặn/chồng căn cứ hoặc P1, giữ vị trí Single Player.
- `godot_tests/local_coop_simulation.gd`: spawn/fallback và lỗi không đủ chỗ, hai command, collider không đẩy, pause, lịch bắn/cooldown/barrel theo owner, pickup/buff/shield riêng và base shield chung, friendly fire/self-hit/damage, hồi sinh giữ buff và loadout, loại riêng người hết mạng, thắng/thua đội, chọn mục tiêu enemy và ưu tiên căn cứ.
- `godot_tests/local_coop_selection.gd`: hai loadout/cursor/readiness độc lập, chuột và phím, cần cả hai xác nhận, replay, đổi friendly fire, loadout trùng, lỗi deployment và popup không chiếm input đồng đội. Kiểm tra popup dùng `Input.parse_input_event` thực tế.
- `godot_tests/local_coop.gd`: menu chế độ, khóa co-op trên touch, luồng map/loadout/deploy, input đồng thời qua simulation, focus loss/pause/resume, hai HUD, split landscape/portrait, camera clamp, chuyển đổi tọa độ theo player, replay, phục hồi lỗi spawn và quay lại Single Player.

`make build` export Web/PWA thành công và chuẩn hóa bundle/cache. `make test-web` kiểm tra layout/input mobile, đóng gói PWA và cache/offline/update. Từ 16/10/2026, Web/PWA desktop/laptop cho phép Local Co-op; điện thoại, iPad và tablet vẫn bị chặn. Device policy có 19 profile JavaScript và test Godot handshake/menu/deployment/input.

## Native visual

`godot_tests/local_coop_visual.gd` chạy renderer native và kiểm tra 42 điều kiện, gồm canvas transform thực tế của hai Camera2D khi player ở xa nhau. Cả hai SubViewport dùng một World2D; ảnh từng viewport có nội dung, actor nằm trong góc nhìn tương ứng, split không chồng nhau và HUD đúng owner.

Sáu ảnh tại `/private/tmp/local-coop-{mode,preparation,actors,landscape,portrait,invalid-map}.png` đã được xem trực tiếp: menu chế độ, hai panel và readiness riêng, robot/tank với weapon riêng, nhãn P1/P2, shield P2, split trái/phải ở 1280×720 và trên/dưới ở 720×1000, cùng lỗi map có thể quay lại preparation. Ảnh là artifact kiểm tra tạm, runner tái tạo khi chạy; không phải resource game. `make test-visual` đã bao gồm runner này.

## Giới hạn

Đã kiểm tra native bằng input mô phỏng và regression gameplay. Chưa playtest hai người bằng bàn phím vật lý hoặc xác nhận keyboard rollover trên phần cứng khác. Chưa có network transport, lobby hoặc đồng bộ hai thiết bị; Play with friend vẫn COMING SOON. Device fixtures không chứng nhận nhận diện phần cứng trên mọi tablet hoặc bàn phím thật. Kết quả Web mới nhất ở [QA Web](web-pwa.md).
