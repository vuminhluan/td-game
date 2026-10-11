# Enemy tank và mech: thay riêng từng hướng

Enemy hiện có `tank` và `robot` dùng hai skin riêng. `robot` được bind tới `enemy_mech`; HP, collider, tốc độ, cooldown, wave và pathfinding vẫn do simulation quản lý.

## Cấu trúc runtime

Mỗi thư mục `assets/sprites/enemy_tank/` và `assets/sprites/enemy_mech/` gồm:

- `enemy_skin.tres`: map `down`, `up`, `left`, `right` → resource riêng từng hướng.
- `<direction>.tres`: `gd/enemy_direction.gd`, chứa SpriteFrames, anchor, scale, muzzle distance.
- `<direction>_frames.tres`: idle/walk/attack, có thể tham chiếu một hoặc nhiều PNG.
- `<direction>.png`: atlas của đúng một hướng, mỗi cell 128×128.
- `<direction>_manifest.json`: rect chính xác, cấu hình animation, geometry và provenance.

Mỗi hướng có idle 4 frame/4 FPS/loop, walk 6/10 FPS/loop và attack 4/12 FPS/one-shot. Tổng cộng 56 frame mỗi loại, 112 frame cả hai. Không xoay hoặc mirror sprite trong runtime. Hướng là chữ thường trong resource; LEFT/RIGHT trong yêu cầu tương ứng `left`/`right`.

## Thay LEFT bằng một bộ mới

1. Tạo run có phiên bản mới, ví dụ `assets/generated/sprites/enemy-mech-v2/left/`, có `.gdignore` ở thư mục cha. Theo [sprite-workflow.md](sprite-workflow.md): vẽ idle, extract, lấy direction anchor, tạo walk/attack từ anchor, extract bằng component pipeline, compose và QA. Mỗi row là một lần generation; không cắt đều một grid AI.
2. Cài đúng hướng bằng script chuyển manifest thành SpriteFrames (stdlib Python, không tạo hoặc xử lý ảnh):

```sh
python3 scripts/install_enemy_direction.py \
  --kind mech --direction left \
  --run-dir assets/generated/sprites/enemy-mech-v2/left \
  --sheet-name left-v2.png \
  --anchor 78 52 --scale 0.5 --muzzle 28
```

Các giá trị geometry trên là ví dụ: đo trên asset mới trước khi dùng. Script cập nhật `left.tres`, `left_frames.tres` và `left_manifest.json`; giữ nguyên resource UP/DOWN/RIGHT và skin đã có. `left-v2.png` giữ PNG cũ để đối chiếu. Đọc rect từ composed manifest, không giả định thứ tự hàng.

3. Hoặc chỉnh `left.tres` trực tiếp trong Godot: gán SpriteFrames mới, anchor/scale/muzzle. Có thể trỏ `enemy_skin.tres.directions.left` sang resource có tên phiên bản riêng để chuyển bộ nhanh. Cập nhật manifest khi sửa thủ công.
4. Mở `scenes/enemy_sprite_preview.tscn` xem cả 24 animation, rồi chạy `make test` và `make test-visual`.

Không chạy lại installer với geometry mặc định khi chỉ muốn đổi texture và giữ geometry đã tinh chỉnh; truyền lại các giá trị từ resource hiện tại.

Với raw PNG có alpha thật như bộ này, dùng extractor để giữ RGB gốc (cleanup magenta mặc định có thể làm giáp đỏ ngả vàng):

```sh
sprite-gen extract --run-dir <run> \
  --key-threshold 0 --fringe-key-threshold 0 --fringe-delta 0 \
  --fringe-unmix-reach 0 --spill-max-fraction 0
```

Các tùy chọn được lưu trong `frames/frames-manifest.json.extract_args` để các bước compose/heal tái sử dụng. Đây vẫn là component extraction của engine. Chỉ dùng cấu hình này sau khi xác nhận ảnh có nền alpha sạch; ảnh nền chroma cần keying phù hợp.

## Thêm loại enemy khác

Tạo skin mới dùng `gd/enemy_skin.gd`, đủ bốn direction resources; thêm binding trong `BattleView.enemy_skins` theo `actor.kind`. Nếu muốn thêm gameplay kind/spawn mới, sửa simulation/wave có chủ đích. Đổi hình cho `tank`/`robot` hiện có chỉ cần thay binding resource.

Enemy animation lấy clock từ simulation. Di chuyển thật mới tăng move clock; đứng yên bắn phát one-shot trong `shot_duration` (1/3 giây), độc lập cooldown 1.3/1.7 giây. Khi vừa đi vừa bắn, chân/bánh xích tiếp tục walk và muzzle effect do simulation vẽ. Pause đóng băng các clock, damage flash dùng hurt clock. BattleView bind muzzle riêng từng loại khi gán simulation và khi replay. Nòng dài được trace từ collider cũ tới muzzle để tránh bỏ qua tường/player gần.

## Nguồn và QA

Nguồn có phiên bản ở `assets/generated/sprites/enemy-tank-v1/` và `enemy-mech-v1/`, chia tiếp theo hướng. Giữ raw rows, prompts, layout guides, frames, manifest, contact/GIF, inspect và inspect-motion reports. Generation dùng image_gen tích hợp; các bước prepare/extract/compose/QA dùng sprite-gen. Không dùng API key, không lưu provider defaults.

Kiểm tra native Godot không xác nhận Web PWA. Motion/contact hoặc seam chưa được chứng nhận sẽ được ghi trung thực trong QA notes; không đảo frame hoặc chỉnh tốc độ để che lỗi.
