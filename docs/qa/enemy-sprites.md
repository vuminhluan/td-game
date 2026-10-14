# QA và provenance enemy sprites

Các báo cáo generation ở `assets/generated/sprites/enemy_mech/<direction>/qa/` và `assets/generated/sprites/enemy_tank/<direction>/qa/`. Inspect/extraction evidence vẫn là bản ghi generation. Ngày 14/10/2026 đã chạy lại `inspect-motion` bằng engine sprite-gen cho 24 sequence enemy, giữ nguyên ảnh, frame count, duration và anchor; các `source_fingerprints` hiện khớp manifest/atlas. Không sửa hash của báo cáo cũ để giả lập rerun. Hợp đồng runtime/geometry ở [Artwork enemy](../assets/enemy-sprites.md).

Image generation dùng built-in image_gen qua ChatGPT. Sprite-gen 2.43.0 thực hiện prepare, component extraction, compose, contact/GIF, inspect và inspect-motion. Installer chuyển rect từ manifest thành TRES bằng Python stdlib, không xử lý ảnh. Bốn góc được tạo độc lập; idle frame của mỗi hướng là `base-source.png` cho walk/attack của hướng đó. Không mirror, xoay ảnh, sơn frame thủ công hoặc đổi thứ tự frame.

Raw rows được chọn, prompt `*-built-in.txt`, guides, reference và frame manifests được giữ. Hai ảnh dùng làm edit target còn giữ ở `enemy_mech/down/references/walk-color-edit-target.png` và `enemy_tank/up/references/idle-alpha-edit-target.png`; chúng nằm trong reference stack cho correction, dù tên ban đầu từng chứa rejected. Các PNG rejected không còn là dependency đã được xóa; correction prompts và provenance vẫn mô tả các lần tạo lại. Mech DOWN sửa walk; tank DOWN/LEFT/RIGHT sửa walk, tank UP sửa idle/walk/attack.

## Evidence inspect

Tất cả tám hướng có `inspect.ok=true`. Mỗi hướng idle/walk/attack có 4/6/4 frame, exact duplicates bằng 0, visible motion bằng true và không có frame chạm mép. Các warning idle còn lưu:

| Bộ | Hướng | Motion presence | Ngưỡng |
| --- | --- | --- | --- |
| Mech | LEFT | 0,0093 | 0,0100 |
| Tank | DOWN | 0,0059 | 0,0100 |
| Tank | UP | 0,0039 | 0,0100 |

Các hướng còn lại không có warning ở lần inspect nguồn. Không coi giá trị `ok` là chứng nhận locomotion liền mạch.

Raw có RGBA sạch; extractor dùng key/fringe thresholds `0`, fringe delta `0`, fringe-unmix reach `0` và spill-max fraction `0` để giữ RGB giáp đỏ. Default magenta despill từng làm giáp đỏ ngả vàng. Các tùy chọn được giữ trong `frames/frames-manifest.json.extract_args` và provenance để compose/heal tái sử dụng.

## Giới hạn và regression

Không có manual same-foot contact spans hoặc ROI chân riêng: `stride_verified=false`; xích không có biped foot contacts. Motion/contact reports vẫn chưa chứng nhận ground contact, wrap seam hoặc chuyển động liền mạch. Giữ duration nguồn; không đảo frame, xóa frame trùng hoặc đổi tốc độ để che lỗi. Detail/pose AI có thể thay đổi nhẹ.

Tank scale/geometry đã được hiệu chỉnh ở runtime và manifests; test kiểm tra consistency kích thước cùng va chạm nòng. Preview native bao phủ 24 animation và tám hướng trong game, gồm thanh HP khi bị thương. Regression hiện chạy qua `godot_tests/enemy_sprite_asset.gd` trong `make test` và native capture qua `make test-visual`. Native pass không xác nhận bản Web PWA; chưa có QA trình duyệt trong evidence nguồn này.
