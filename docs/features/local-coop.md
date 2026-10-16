# Local Co-op và luật nhiều người chơi

Tài liệu này ghi lại phạm vi đã thống nhất cho Local Co-op và các ràng buộc gameplay cần giữ khi mở rộng luật hai người chơi. Local Co-op đã được triển khai; tài liệu mô tả luật gameplay và hợp đồng implementation hiện hành. Chế độ hiện hỗ trợ chơi hai người trên cùng thiết bị. Về sau, luật simulation cần dùng lại được khi hai thiết bị cùng chơi, dù mỗi thiết bị chỉ cần hiển thị camera của người chơi tại đó.

## Phạm vi chế độ

Menu đầu trận có Single Player, Local Co-op và Play with friend. Play with friend hiển thị nhãn “COMING SOON” và bị vô hiệu hóa cho tới khi tính năng kết nối hai thiết bị được triển khai.

Local Co-op hiển thị trên native desktop và bản Web/PWA của desktop/laptop có bàn phím vật lý. Mobile, iPad và tablet không được vào chế độ này, kể cả khi gắn bàn phím hoặc mở desktop website. Kích thước cửa sổ nhỏ không tự vô hiệu hóa co-op. Giới hạn này thuộc giao diện/chế độ chơi, không phải giới hạn của luật simulation hai người. Cấu trúc luật nên độc lập với nguồn input và cách trình bày camera để có thể nối input mạng và dùng một góc nhìn trên mỗi thiết bị về sau.

Luồng Local Co-op: chọn map → hai người chọn loadout → mỗi người xác nhận Sẵn sàng → triển khai khi cả hai đã sẵn sàng. Màn hình chọn loadout chia cho hai player. Mỗi người chọn character, Body và weapon độc lập; loadout trùng nhau được phép.

## Điều khiển và camera

| Người chơi | Di chuyển | Bắn | Xác nhận lựa chọn/sẵn sàng |
| --- | --- | --- | --- |
| P1 | W, A, S, D | Space | Space |
| P2 | Phím mũi tên | Shift | Shift |

Mỗi player điều khiển panel loadout của mình bằng cùng bộ phím tương ứng. Hai nút Sẵn sàng hoạt động độc lập; trận không bắt đầu cho đến khi cả hai xác nhận.

Trong trận local, mỗi player có camera riêng theo vị trí của mình. Battlefield chia trái/phải ở landscape và trên/dưới ở portrait. Camera được clamp theo biên map. Trên hai thiết bị trong tương lai, mỗi thiết bị chỉ cần hiển thị góc nhìn của player tương ứng; không dùng split-screen giữa hai thiết bị.

HUD cá nhân (HP, mạng, weapon) nằm trong viewport của player. Wave, điểm và trạng thái căn cứ là thông tin chung của đội.

Nhãn P1/P2 vẽ trên nhân vật trong 10 giây đầu sau khi triển khai. Mỗi lần player hồi sinh, nhãn của người đó hiện lại trong 3 giây.

## Trạng thái và luật trận đấu

| Trạng thái | Phạm vi |
| --- | --- |
| HP, mạng sống, loadout, power-up | Riêng từng player |
| Wave, căn cứ, điểm số, chiến dịch | Dùng chung |
| Thắng | Hoàn tất chiến dịch và bảo vệ được căn cứ |
| Thua | Căn cứ bị phá hủy hoặc cả hai player hết mạng |

Hết mạng loại riêng player đó khỏi trận; đồng đội còn mạng vẫn tiếp tục. Khi hồi sinh, player trở lại với HP đầy, giữ loadout và các power-up cá nhân còn hiệu lực, đồng thời nhận khoảng miễn thương hồi sinh hiện hành. Thời gian của power-up tiếp tục trôi trong trận.

Weapon pickup chỉ thay weapon của người nhặt. Power-up cá nhân chỉ tác động lên người nhặt; `base_shield` bảo vệ căn cứ chung. Các luật này cần được thực thi theo owner của actor/pickup, không qua một loadout player toàn cục.

Player-player collision chặn chuyển động như vật cản, không đẩy actor. Kiểm tra vị trí mới phải bảo đảm collider hai người không giao nhau, đồng thời tiếp tục tôn trọng collision map và căn cứ.

## Friendly fire

Friendly fire là tùy chọn trong bước chuẩn bị Local Co-op và mặc định tắt.

- Khi tắt, đạn player xuyên qua player đồng đội mà không gây sát thương.
- Khi bật, đạn player gây sát thương cho player đồng đội đầu tiên trúng phải rồi biến mất.
- Đạn không gây sát thương lên người bắn.

Đạn cần giữ định danh chủ sở hữu để áp dụng luật teammate/self-hit. Miễn thương và trạng thái sát thương phải theo từng player để một người không vô tình bảo vệ hoặc chặn sát thương của người kia.

## Enemy và mục tiêu căn cứ

Mục tiêu chính của enemy vẫn là đi tới và phá hủy căn cứ. Chúng không được chia cứng cho từng player lúc spawn và không đổi đường đi để truy đuổi người chơi. Trên đường đi, enemy có thể dừng bắn player nằm trong điều kiện ngắm hiện tại; nếu cả hai player đều đủ điều kiện, chọn người gần enemy nhất. Nếu player đó bị hạ, chỉ player còn sống là mục tiêu hợp lệ.

Hành vi hiện tại của enemy ưu tiên tình huống căn cứ ở gần; nhánh bắn player kiểm tra khoảng cách và thẳng hàng theo trục, rồi đạn chịu collision của map. Chưa có kiểm tra line-of-sight riêng trước khi enemy khai hỏa. Local Co-op giữ hành vi này: vật cản chặn đạn nhưng không thêm luật tầm nhìn mới.

## Spawn hai player

Map có thể khai báo marker spawn P2 riêng. P1 tiếp tục dùng player spawn hiện tại. Nếu map không có marker P2, Local Co-op tự chọn ô hợp lệ gần spawn P1, cùng khu vực xuất phát nếu có thể. Vị trí phải đủ khoảng cách để collider P1/P2 không giao nhau, đồng thời không bị map hoặc căn cứ chặn.

Nếu không tìm được ô hợp lệ cho P2, map không thể triển khai Local Co-op và cần báo lỗi rõ ràng thay vì đặt hai actor chồng lên nhau. Việc thêm marker P2 không làm thay đổi spawn của Single Player.

## Kiến trúc implementation

`gd/simulation.gd` sở hữu `players`: mỗi phần tử chứa `id` ổn định, `actor`, `loadout`, `lives`, `invulnerable`, `active_power_ups`, `pending_shots`, `muzzle_distances`, `spawn_position` và `label_remaining`. ID player bắt đầu từ 1; index API bắt đầu từ 0. Hồi sinh thay actor và actor ID, nhưng giữ player ID, loadout, power-up và spawn ban đầu. Không thay tạm trạng thái P1 để xử lý P2. Các thuộc tính cũ `player`, `loadout`, `lives`, `invulnerable`, `pending_shots`, `active_power_ups` và muzzle là alias của P1 để giữ tương thích với Single Player và fixture.

Constructor nhận `configuration`, `scene`, `configurations`. Mảng loadout quyết định các player tham gia; `update_players(delta, commands)` nhận một command `{direction, shooting}` theo index player. `update(delta, direction, shooting)` là wrapper Single Player. `equip_weapon`, `activate_power_up`, `power_up_active`, `compatible_weapons` và `hit_player` nhận index player tùy chọn. Cấu trúc này cho phép adapter input mạng gọi cùng luật simulation về sau; đồng bộ mạng, snapshot, reconnect và lobby chưa thuộc phạm vi hiện hành.

Actor player có `player_id`; projectile có `owner_id` (0 cho enemy). Friendly fire dựa trên ID ổn định này và dùng damage của weapon. Player hết mạng bị loại khỏi di chuyển, pickup, collision và tập mục tiêu enemy. `base_shield` được truy vấn trên tất cả player, còn buff khác chỉ truy vấn owner. Drop weapon dùng hợp các vũ khí tương thích của player còn sống; việc nhặt vẫn kiểm tra loadout riêng. Periodic pickup tìm ô có thể tới từ ít nhất một player còn sống.

`find_player_spawn` tìm theo breadth-first trong vùng có thể đi từ spawn, tôn trọng collider loadout, map, căn cứ và các đồng đội còn sống. P2 dùng marker `player_two` nếu có; thiếu marker sẽ tìm gần P1. Không tìm được chỗ lúc triển khai trả `invalid` với lỗi P2 rõ ràng. Nếu đồng đội chiếm vị trí hồi sinh, tìm ô lân cận; nếu tạm thời không có chỗ, actor chờ và thử lại mỗi tick, không mất thêm mạng. Buff tiếp tục hết hạn trong thời gian chờ. Các map hiện tại dùng fallback, không cần sửa spawn Single Player.

`gd/player_input.gd` chuyển phím giữ thành command độc lập. `gd/coop_selection.gd` quản lý hai loadout, cursor và readiness; W/S hoặc ↑/↓ chọn hàng, A/D hoặc ←/→ đổi lựa chọn, Space/Shift xác nhận hàng rồi Sẵn sàng. Đổi loadout hủy readiness của chủ sở hữu; đổi friendly fire hủy readiness cả hai. Popup selector chuyển phím điều khiển trở lại panel đúng player. Triển khai và replay cần hai xác nhận mới. Lỗi spawn được hiển thị trong preparation và vẫn cho quay lại chọn map/chế độ.

Web shell gửi capability `localCoop` qua `RobotDefenseWeb.metrics`, tách khỏi cờ `touch` dùng cho giao diện Single Player. Desktop có UA nhận diện được và primary pointer chính xác được phép; các UA/hint mobile, iPad UA Macintosh kèm multi-touch, thiết bị có primary pointer coarse và thiết bị chưa nhận diện đều bị chặn. Laptop cảm ứng có chuột/trackpad vẫn được phép. Godot mặc định khóa co-op Web cho tới khi nhận capability hợp lệ; callback chọn chế độ và triển khai đều kiểm tra cùng policy. Chi tiết và giới hạn nhận diện ở [Web PWA](web-pwa.md).

`gd/main.gd` chỉ nối chế độ, input, preparation và presentation. Hai SubViewport dùng chung `World2D` và một `BattleView`, nhưng mỗi viewport có Camera2D và `gd/player_status_hud.gd` riêng. Camera follow/clamp theo player tương ứng; chuyển đổi screen/world nhận index player. `gd/battle_view.gd` lấy body, weapon, miễn thương, shield và thời gian nhãn từ state của actor đang vẽ. `gd/power_up_hud.gd` nhận player index để hiện đúng timer. Thông tin wave, điểm, enemy và căn cứ dùng chung bên ngoài hai viewport.

Mất focus hoặc vào nền pause toàn trận và xóa cả hai bộ input. Pause đóng băng simulation, buff và nhãn. Thay đổi kích thước cửa sổ sắp lại split-screen và xóa input đang giữ theo hành vi hiện có. Khi một player hết mạng, camera giữ vị trí cuối và HUD báo hết mạng; người còn sống tiếp tục chiến dịch.

## Kiểm thử

`make test` bao gồm test co-op cho simulation, marker/map, selection và integration UI/camera; tiếp tục chạy toàn bộ regression Single Player. `make test-web` kiểm tra layout mobile và Web/PWA. `make test-visual` có runner native `godot_tests/local_coop_visual.gd`; bằng chứng và giới hạn ở [QA Local Co-op](../qa/local-coop.md).

Tài liệu liên quan: [Chọn nhân vật](character-selection.md), [Combat](combat.md), [Pickup/power-up](power-ups.md), [Camera/input](map/camera.md) và [Biên soạn map](map/authoring.md).
