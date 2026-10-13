# Artwork nhân vật và vũ khí tách lớp

Bộ hiện hành có 36 pose: hai Body sạch và bảy bộ vũ khí, mỗi bộ đủ DOWN/UP/LEFT/RIGHT. Raster được tạo bằng built-in `imagegen`, tham chiếu robot olive/beige cũ, rồi sửa riêng để đóng giáp mái và bỏ mọi nòng khỏi Body/bộ tên lửa.

Runtime dùng `assets/sprites/characters/layers.png` (836×1882, RGBA). `manifest.json` ghi vùng từng hướng, anchor, scale 0,25, socket roof, vùng missile phía sau thân, tham số stride/recoil, nguồn và reference. Vùng frame lấy theo alpha thực tế, không giả định các hàng generation đều cao bằng nhau. Body là ảnh hoàn chỉnh; không cắt súng cũ hoặc vẽ giáp bù ở runtime.

Nguồn hiện hành nằm ở `assets/generated/sprites/characters/body-weapons/`:

- `source.png`: khớp byte PNG runtime.
- `reference-sheet.png`: kết quả generation đầu dùng làm input cho lượt sửa.
- `generate-prompt.txt`, `correct-prompt.txt`: prompt đã gửi vào built-in tool.
- `request.json`: provider, input, output, generation ID và dấu vân tay.

Robot cũ tại `assets/generated/sprites/player_mech/` và PNG runtime cũ vẫn được giữ vì là reference cho bộ mới và fixture resource/regression. Không xóa chúng chỉ vì màn hình chính đã chuyển sang atlas mới.

`gd/character_art.gd` cung cấp SpriteFrames cho ba trạng thái và bốn hướng. Idle dùng pose tĩnh. Walk chuyển động nhỏ phần chân/xích dưới torso cố định; attack dùng recoil weapon từ shot clock. Socket không dịch theo chân nên Body/Weapon không trượt nhau. Vùng missile phía sau được vẽ trước Body, phần còn lại sau Body ở góc nhìn ngang. Flash và hiệu ứng phóng dùng sự kiện projectile của simulation, có tọa độ riêng cho từng bên.

Geometry gameplay trong `config/player_characters.json` tính bằng world units từ tâm actor và được `CharacterCatalog` đổi sang offset socket. Collider radius cấu hình riêng, không đọc alpha. Khi đổi scale/anchor/socket/vùng nòng, phải cập nhật geometry trong config và chạy cả test/render native.

QA hiện tại: `make test` đạt 914 kiểm tra character selection và toàn bộ regression. Native render đã kiểm tra desktop 1280×1000, mobile 390×844, màn hình nhỏ 320×568, trận tank/missile và Body/loadout ở bốn hướng × ba trạng thái × bốn frame chuyển tiếp. Chấm xanh trong atlas QA đánh dấu geometry, không mô phỏng flash. Animation procedural vẫn có thể được nâng cấp thành các pose locomotion riêng; bản Web PWA chưa được kiểm tra trong trình duyệt.

![Body riêng và các loadout](../images/character-selection-layers.png)

## Sửa bàn chân UP — 13/10/2026

Body UP trước đây có torso phía sau nhưng bàn chân giống mặt trước của DOWN. Đã tạo gót ngắn và khớp cổ chân phía sau bằng built-in imagegen, rồi ghép riêng rectangle `(209,145,209,92)` qua `scripts/assemble_robot_heel_fix.gd`. Mọi pixel ngoài vùng sửa được giữ nguyên, gồm torso/socket và tất cả vũ khí. Nguồn reference, ảnh tool, prompt và revision được giữ trong `assets/generated/sprites/characters/body-weapons/up-heels/` và `request.json`; fingerprint runtime/source đã cập nhật.

QA sau sửa: `make test` đạt, character selection 914 kiểm tra; đã xem render native Body UP/DOWN ở đủ loadout/trạng thái. So sánh pixel xác nhận vùng thay đổi chỉ nằm trong rectangle chân UP; fingerprint runtime/source/reference đều khớp.
