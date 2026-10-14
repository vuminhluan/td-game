# Tạo, thay và tích hợp sprite nhân vật

Đọc source/resource hiện hành trước khi sửa. Gameplay player dùng [Body/vũ khí tách lớp](../assets/characters.md), còn [atlas player-mech](../assets/player-mech.md) là fixture/reference. [Enemy tank/mech](../assets/enemy-sprites.md) dùng resource từng hướng. Các nhánh này có hợp đồng artwork khác nhau.

## Generation và nguồn

1. Xác định nhân vật, vai trò Body/vũ khí hay enemy, tạo mới/thay hướng, reference và trạng thái cần làm từ yêu cầu đã có.
2. Tạo candidate dưới `assets/generated/candidates/<asset>/<role>/`, có `.gdignore` ở thư mục cha. Giữ nguồn runtime/reference đang dùng tới khi bản mới qua QA và binding đã đổi. Sau đó chuyển nguồn được chọn sang thư mục mô tả asset/vai trò, cập nhật manifests/fingerprints và xóa candidate cũ không còn dependency theo [bảo trì](../maintenance.md).
3. Khi cần tạo bitmap bằng AI, đọc skill sprite-gen hiện tại. Generation các bộ hiện có dùng image_gen tích hợp qua ChatGPT; chuẩn bị/extract/compose/QA atlas animation dùng sprite-gen. Không đổi provider/model/defaults hoặc dùng API key nếu không có yêu cầu. Ghi provider, prompts, reference roles, request, correction và output trong provenance.
4. Vẽ riêng DOWN/UP/LEFT/RIGHT: UP nhìn sau, side views có chân/nòng cùng hướng; không xoay/mirror cả ảnh để bù góc thiếu. Với animation atlas, tạo idle từng hướng trước, extract direction anchor rồi tạo walk/attack từ đúng anchor đó. Walk cần contact/lift/passing; attack cần braced/recoil/recovery.
5. Extract qua component pipeline và compose từ manifest chính xác; không tự chia đều grid AI. Nòng sát mép cần đo lại fit/padding (có thể dùng `bbox-center`) rồi inspect. Với raw alpha sạch của atlas enemy hiện có, zero key/fringe/spill giữ RGB giáp đỏ; chỉ dùng sau khi xác nhận RGBA sạch. Ảnh chroma cần keying phù hợp.
6. Lưu raw được chọn, reference cần cho tái tạo, prompts, request, manifests và QA evidence. Không giữ PNG rejected không còn là source/reference. Contact/GIF/inspect-motion không chứng nhận foot contact hoặc seamless motion; ghi giới hạn trung thực, không đảo frame/retime để che lỗi.

## Player hiện hành: Body và vũ khí riêng

`config/player_characters.json` nối character → Body/art ID → vũ khí tương thích/art ID. `assets/sprites/characters/manifest.json` mô tả pose bốn hướng, region/anchor/scale/socket, rear regions, stride/recoil và source fingerprints. Catalog dựng resource từ hai file này; BattleView và UI preview dùng cùng cách ghép. Thay skin export riêng trong BattleView không đổi default player vì `sim.loadout.body` sẽ ghi lại binding.

Body phải sạch và hoàn chỉnh khi tháo vũ khí, không chứa nòng/bệ/flash. Bộ tên lửa là một lựa chọn, có thể có lớp sau/trước theo hướng. Atlas hiện dùng 36 pose tĩnh, bốn frame lặp ở mỗi state; walk/recoil do renderer tạo, không phải animation atlas 4/6/4 của fixture/enemy. Có thể thay bằng artwork mới, nhưng cần giữ hoặc mở rộng hợp đồng resource/renderer rõ ràng.

Khi thêm Body/vũ khí, cập nhật layers, manifest, character/body/weapon IDs và tương thích trong config. Geometry muzzle config tính theo world units từ tâm actor, collider riêng. Khi đổi artwork scale/anchor/socket/nòng, đo và cập nhật config cùng nhau; giữ sync Body/Weapon và thứ tự lớp. Schedule/rest/damage/bullet speed thuộc config gameplay, không suy ra từ FPS artwork. Shot animation mặc định 0,23 giây độc lập nghỉ sau loạt và khóa tới event cuối.

Giữ `source.png` khớp byte runtime PNG và cập nhật `request.json.source_fingerprints`, manifest provenance/reference. QA gồm Body riêng, tất cả loadout/hướng/state, chuyển frame, socket, đúng nòng/bên và đạn sát tường/địch.

## Enemy: thay riêng một hướng

Mỗi thư mục `assets/sprites/enemy_{tank,mech}/` gồm `enemy_skin.tres`, `<direction>.tres`, `<direction>_frames.tres`, PNG và manifest. Hợp đồng hiện hành mỗi hướng idle 4/4 FPS/loop, walk 6/10 FPS/loop, attack 4/12 FPS/one-shot, cell 128×128. SpriteFrames có thể tham chiếu nhiều PNG.

`scripts/install_enemy_direction.py` đọc composed manifest, dùng rect và animation metadata chính xác, chỉ cập nhật direction được chọn. Đo geometry theo ảnh mới hoặc giữ nguyên anchor/scale/muzzle hiện tại khi chỉ thay texture. Đặc biệt tank DOWN/UP có scale đã hiệu chỉnh; giá trị mặc định installer không phù hợp mọi hướng.

Ví dụ thay LEFT, truyền geometry đã đọc/đo từ resource:

```sh
python3 scripts/install_enemy_direction.py \
  --kind mech --direction left \
  --run-dir assets/generated/candidates/enemy_mech/left \
  --anchor 78 52 --scale 0.5 --muzzle 28
```

Các số trên chỉ là ví dụ. PNG mặc định theo tên hướng; `--sheet-name` nhận basename PNG mô tả vai trò nếu cần file khác. Sau khi duyệt, cập nhật `source_run`, source geometry/provenance và xóa texture/resource cũ khi không còn tham chiếu. Có thể thay trực tiếp đúng entry của `EnemySkin.directions`; chỉnh TRES thủ công cần cập nhật manifest cùng lúc.

Raw RGBA sạch của enemy dùng extract:

```sh
sprite-gen extract --run-dir <run> \
  --key-threshold 0 --fringe-key-threshold 0 --fringe-delta 0 \
  --fringe-unmix-reach 0 --spill-max-fraction 0
```

Options lưu trong `frames/frames-manifest.json.extract_args`. Muốn thêm skin cho kind hiện có, đổi `BattleView.enemy_skins`; muốn kind/spawn/gameplay mới, cập nhật simulation/wave có chủ đích. BattleView bind muzzle enemy khi gán sim; simulation trace nòng dài. Enemy khóa hướng/di chuyển trong shot clock 1/3 giây, độc lập cooldown tank 1,3/robot 1,7 giây.

## Fixture player-mech: thay một hướng

Để thay fixture LEFT, cập nhật ba animation `left_idle`, `left_walk`, `left_attack` trong `player_mech_directions.tres`; giữ UP/RIGHT. Dùng AtlasTexture rect từ composed manifest, có thể đặt PNG LEFT riêng. Với layout hiện hành, LEFT ở y=768/896/1024, cell 128×128 và counts 4/6/4; đọc manifest trước mỗi sửa vì layout có thể đổi.

Cập nhật `player_skin.tres.directional_anchors`, sockets, Body/flash exclusions và `assets/weapons/{standard,twin}.tres` regions/anchors/muzzles khi ảnh đổi. Fixture dùng scale chung 0,5; các scale khác theo hướng cần hỗ trợ resource hoặc chuẩn hóa asset. Manifest là provenance; fixture game đọc TRES trực tiếp. Không xóa atlas này vì đang là reference generation nhân vật và dependency regression.

## Kiểm tra và bàn giao

```sh
make import
make test
make test-visual
```

Preview native: `scenes/player_mech_preview.tscn` và `scenes/enemy_sprite_preview.tscn`. Board loadout fixture được tạo bằng `gd/player_loadout_preview.gd` trong visual test. `character_selection_visual.gd` xem Body sạch/bảy loadout; `player_mech_visual.gd` xem board fixture nhưng main-scene capture dùng player hiện hành. Headless kiểm tra logic/resource; native render mới kiểm tra hình thực tế.

Khi thay hợp đồng frame/resource, cập nhật test có chủ đích; giữ kiểm tra hướng, geometry, alpha/crop, pause, respawn, moving fire và đạn sát vật cản. Bàn giao đường dẫn runtime/source, provenance/QA, render, kết quả test và giới hạn. Native pass không xác nhận Web PWA; cần export templates phù hợp và chạy trình duyệt để chứng nhận Web.
