# Quy trình tạo, thay và tích hợp sprite robot

Mention file này khi yêu cầu tạo robot player mới, thay một hướng, hoặc thêm sprite enemy. Đây là hướng dẫn cho agent thực hiện công việc; không phải script tự chạy. Đọc cùng `assets/sprites/player_mech/README.md` và code hiện tại trước khi sửa.

## Hợp đồng dự án

- Godot 4.7.2, GDScript, Compatibility; mục tiêu Web PWA.
- Tạo ảnh bằng image_gen tích hợp qua quyền truy cập ChatGPT hiện có. Không dùng API key hoặc dịch vụ trả phí khác nếu chưa được người dùng yêu cầu rõ ràng.
- Dùng skill sprite-gen đã cài để prepare, extract, compose atlas, preview và inspect. Đọc SKILL.md hiện tại trước khi thực hiện. Nếu CLI generation vẫn không hỗ trợ model tài khoản, dùng image_gen tích hợp cho riêng bước generation và ghi rõ provenance; không đổi tài khoản/model hoặc chuyển sang API trả phí.
- Nòng súng, mũi chân và hướng di chuyển phải thống nhất. Bốn góc nhìn được vẽ riêng; không xoay cả ảnh hoặc tự mirror để thay thế góc còn thiếu.
- Giữ bản nguồn và phiên bản cũ cho tới khi kiểm tra bản mới. Không tự lưu provider defaults; curation có thể bỏ qua theo lựa chọn đã có.

## 1. Chốt yêu cầu từ thông tin đã có

Xác định player/enemy, tạo mới hay thay asset, concept/reference, hướng cần làm và animation. Tận dụng thông tin đã được người dùng chốt; chỉ hỏi phần thực sự còn thiếu.

Mặc định kế thừa bộ player: 128x128 mỗi frame, idle 4 frame/4 FPS/loop, walk 6 frame/10 FPS/loop, attack 4 frame/không loop. `shoot` là tên gọi trong yêu cầu; tên resource trong game là `attack`. Bắn trong gameplay đồng bộ với SHOT_COOLDOWN 0.23 giây, khác tốc độ preview attack 12 FPS.

## 2. Tạo ảnh và atlas

1. Tạo thư mục nguồn có phiên bản mới dưới `assets/generated/sprites/` và request JSON chứa frame count, FPS, cell, fit và action. Thư mục nguồn có `.gdignore`; runtime PNG/TRES được đặt dưới `assets/sprites/<robot-id>/`.
2. Dùng base đã được duyệt làm identity ban đầu. Tạo idle từng góc: DOWN nhìn trước, UP nhìn sau, LEFT/RIGHT nhìn bên. Kiểm tra súng và chân trước khi tiếp tục; không duyệt một hình chỉ đổi hướng súng nhưng chân vẫn quay ngược.
3. Extract idle bằng sprite-gen. Lấy frame idle chuẩn của mỗi góc làm direction anchor.
4. Tạo từng hàng walk/attack từ đúng anchor và layout guide của state. Reference của góc đối diện chỉ phục vụ nhịp/scale, không thay identity. Giữ thân, camera và súng ổn định; walk phải có chuyển pha chân, attack có braced/recoil/recovery.
5. Extract bằng pipeline chuẩn, không tự cắt đều ảnh AI thay cho component extraction. Nếu nòng dài bị sát/cắt mép, thử fit `bbox-center` bằng engine rồi kiểm tra lại.
6. Compose atlas và manifest, tạo contact sheets/GIF, inspect và inspect-motion. Kiểm tra mọi frame, các góc, identity, alpha, crop và motion. Tạo lại hàng bị lỗi; không che lỗi bằng đảo frame hay đổi tốc độ. Ghi trung thực phần motion/contact/seam còn chưa xác nhận.
7. Lưu raw, request, prompts, reference stack, corrections và QA notes. Runtime lấy các vùng frame từ manifest, không giả định hàng luôn giữ thứ tự cũ sau compose.

## 3. Thay riêng hướng LEFT của player

Có thể dùng PNG riêng cho LEFT. Không bắt buộc gộp nó vào sheet chung.

1. Đặt PNG mới trong `assets/sprites/player_mech/`, ví dụ `player_mech_left_v2.png`.
2. Mở resource `assets/sprites/player_mech/player_mech_directions.tres` trong Godot. Thay frame texture/atlas regions của ba animation `left_idle`, `left_walk`, `left_attack` để trỏ tới PNG mới. Giữ các animation UP/RIGHT hiện có. SpriteFrames hỗ trợ các frame tham chiếu nhiều PNG khác nhau.
3. Giữ thứ tự frame và cấu hình loop/FPS đúng hợp đồng. Với PNG có layout khác, cập nhật từng AtlasTexture region; không chỉ đổi đường dẫn rồi giữ rect cũ.
4. Cập nhật provenance/runtime manifest để phản ánh vùng và sheet thực tế. Manifest là hồ sơ asset; game đang đọc TRES, không tự dựng animation từ JSON.
5. Nếu hình đổi vị trí thân hoặc độ dài súng, sửa `directional_anchors["left"]` và `muzzle_distances["left"]` trong `player_skin.tres`. Scale hiện dùng chung cả bộ; nếu cần scale riêng cho một góc, phải bổ sung hỗ trợ đó hoặc chuẩn hóa kích thước asset.
6. Kiểm tra trong preview và game, gồm đứng, đi, bắn, vừa đi vừa bắn, đứng sát tường và chuyển hướng.

Cách khác: cập nhật đúng ba hàng LEFT trong PNG chung và giữ layout hoàn toàn giống cũ. Theo manifest hiện tại: left_idle y=768, left_walk y=896, left_attack y=1024; cell 128x128, x lần lượt 0,128,...; counts 4/6/4. PNG chung 768x1152. Các tọa độ này chỉ đúng với phiên bản hiện tại; đọc manifest trước mỗi lần sửa.

## 4. Tạo robot player mới

Tạo thư mục runtime riêng, SpriteFrames cho DOWN (`idle`, `walk`, `attack`) và ba hướng còn lại (`up_*`, `left_*`, `right_*`). Tạo skin Resource dùng `gd/player_skin.gd`, gán `frames`, `directional_frames`, `texture_scale`, `anchor`, `directional_anchors`, `muzzle_distances`. Gán skin mới vào `BattleView.player_skin` trong scene/cấu hình game. Kiểm tra binding mô phỏng khi khởi tạo và chơi lại; BattleView hiện cấp muzzle distances cho simulation khi gán sim.

Skin thay hình ảnh/animation. HP, tốc độ, cooldown, số mạng là dữ liệu gameplay khác; chỉ sửa nếu yêu cầu gồm thay khả năng chiến đấu. Nếu muốn nhiều robot để người chơi chọn, cần thêm luồng chọn robot và lưu lựa chọn; việc tạo sprite chưa tự tạo tính năng đó.

## 5. Tạo hoặc thêm enemy

**Enemy robot/tank đã có hệ skin theo loại và hướng.** Xem [enemy-sprite-workflow.md](enemy-sprite-workflow.md) để thay riêng LEFT/RIGHT hoặc cài một direction atlas từ manifest. Runtime dùng `BattleView.enemy_skins`, `gd/enemy_skin.gd` và `gd/enemy_direction.gd`; nhánh vẽ code chỉ còn fallback cho loại chưa có skin.

Sau khi tạo asset theo bước 1–2:

1. Nếu chỉ đổi hình enemy hiện có, thay resource trong `enemy_skins` theo `actor.kind`, hoặc thay đúng một entry `skin.directions`; giữ collision/gameplay cũ.
2. Nếu thêm loại enemy mới, bổ sung kind, thông số và spawn/wave theo yêu cầu. Không vô tình đổi robot/tank hiện có.
3. Enemy clocks/moving/fire đã được cập nhật trong simulation; skin chọn đúng góc theo enemy.dir. Loại mới có thể cần shot_duration khác; thời lượng animation độc lập cooldown bắn.
4. Anchor/scale/muzzle nằm ở resource từng hướng. BattleView bind muzzle riêng từng loại khi gán sim; simulation trace nòng dài cho cả player và enemy. Kiểm tra geometry của ảnh mới và va chạm sát tường/player.
5. Giữ thứ tự terrain → actors → foliage → bullets/effects, thanh HP, điểm, damage/death và pathfinding.
6. Thêm test phù hợp cho loại mới và chạy lại acceptance/player/render.

## 6. Kiểm tra và bàn giao

```sh
godot --headless --path . --editor --import --quit
make test
godot --path . --script godot_tests/visual_smoke.gd
godot --path . --script godot_tests/player_mech_visual.gd
godot --path . scenes/player_mech_preview.tscn
godot --path . scenes/enemy_sprite_preview.tscn
```

Test player hiện kiểm tra bộ 4/6/4 frame và đường dẫn asset player hiện tại. Khi đổi frame count hoặc chuyển hẳn robot mới, cập nhật test theo hợp đồng mới; vẫn kiểm tra đủ góc, texture selection, không xoay hình, pause/replay và va chạm súng. Không xóa assertion để giấu lỗi. Visual test dùng renderer native; chạy headless không thay thế kiểm tra ảnh thật.

Bàn giao đường dẫn PNG/TRES/skin, prompt/QA notes, ảnh preview, kết quả test và hạn chế thực tế. Native Godot pass không đồng nghĩa Web PWA pass; chỉ xác nhận Web sau khi có export templates và chạy trong trình duyệt.

## Mẫu yêu cầu cho lần sau

- “Theo @docs/sprite-workflow.md, thay hướng LEFT của player bằng ảnh này, gồm idle/walk/attack; giữ nguyên các hướng khác và áp dụng vào game.”
- “Theo @docs/sprite-workflow.md, tạo player robot mới theo concept ..., đủ bốn hướng và đứng/đi/bắn; dùng ChatGPT hiện có, áp dụng và test trong Godot.”
- “Theo @docs/sprite-workflow.md, tạo enemy mới theo concept ..., thông số ..., xuất hiện ở đợt ...; tạo sprite, tích hợp skin enemy và test trong Godot.”
