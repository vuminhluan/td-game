# QA và provenance atlas player-mech

Atlas này hiện là fixture/reference; gameplay mặc định dùng [artwork nhân vật tách lớp](../assets/characters.md). [Asset contract](../assets/player-mech.md) ghi đường dẫn runtime, geometry và dependency. Inspect/extraction bên dưới là evidence generation. Ngày 14/10/2026 đã chạy lại inspect-motion cho ba walk sequence UP/RIGHT/LEFT, giữ ảnh, timing và anchor; fingerprint nguồn được kiểm tra lại.

## Nguồn DOWN

`assets/generated/sprites/player_mech/down/` giữ identity từ ảnh mech người dùng và base DOWN được duyệt. Idle/attack tái sử dụng rows đã được duyệt; walk gồm sáu pose riêng được image_gen chỉnh để cải thiện chuyển pha chân, giữ nhận diện thân và hướng nòng/mũi chân. Built-in image_gen tạo raster; sprite-gen 2.43.0 prepare/extract/cleanup/compose/preview/inspect. Không đổi provider/account, không dùng API key, không sơn hoặc đảo frame thủ công.

Atlas DOWN RGBA 768×384, cell 128×128, 14 vùng (idle/walk/attack 4/6/4). Inspect nguồn trả ok, không lỗi/warning. Đã kiểm tra orientation, đủ chi và alpha; variation nhẹ vẫn còn. Giai đoạn đầu từng xoay một view cho các hướng; resource hiện hành chỉ dùng sheet này cho DOWN và có UP/LEFT/RIGHT riêng.

## Nguồn UP/RIGHT/LEFT

`assets/generated/sprites/player_mech/directions/` dùng base DOWN đã duyệt làm identity ban đầu cho idle từng góc. UP được vẽ lại vì shin/toe ban đầu còn nhìn trước; hình được chọn có rear vents/pistons/heel. RIGHT/LEFT vẽ riêng. Mỗi action row dùng idle frame-0 của chính hướng đó. LEFT action thêm RIGHT raw row làm reference nhịp/scale; không mirror hoặc dùng nó thay identity.

UP walk được tạo lại để thêm passing phases giữa các contact poses. PNG rejected đã được dọn; raw được chọn, corrections/prompts, reference anchors và provenance giữ lại. Frame không bị sơn, đổi thứ tự hoặc retime sau extraction.

Nòng LEFT từng sát mép khi centroid alignment; pipeline được chạy lại với `bbox-center` để giữ padding đầy đủ. Atlas RGBA 768×1152, 42 vùng (ba hướng × 4/6/4), cộng DOWN thành 56 frame. Extract/compose/inspect đều trả ok không lỗi/warning cho chín state; contact sheet được xem để xác nhận UP nhìn sau và side views có nòng/chân cùng hướng.

## Motion và phạm vi kiểm tra

Inspect-motion ghi frame walk thực sự thay đổi, không exact duplicates. Không khai báo stance/isolated-foot ROI nên ground contact chưa xác nhận; `needs-review` được giữ. Foot stability, wrap seam và locomotion liền mạch chưa được chứng nhận. Idle/action có variation nhẹ; attack có braced/flash/recovery poses.

Các regression `player_mech_asset.gd`/`player_loadout.gd` load fixture và kiểm tra đủ 56 frame, chọn hướng thật/rotation zero, moving fire, stationary attack, sát tường/địch, pause, damage, respawn và geometry nòng. Constructor simulation tính geometry từ loadout và trace nòng dài trước khi tạo projectile.

Preview `player_mech_preview.tscn`/board native hiển thị 12 animation fixture. Các capture main-scene trong `player_mech_visual.gd` hiện dùng player từ character config nên kiểm tra integration game hiện hành; board vẫn dùng fixture. Native test/render không xác nhận bản Web PWA. Không lưu provider defaults; generation evidence này không có QA trình duyệt.
