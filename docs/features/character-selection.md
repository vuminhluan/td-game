# Chọn và tùy biến nhân vật trước trận

Đã triển khai ngày 12/10/2026: màn hình chọn Robot/Xe tăng, Body, một vũ khí tương thích, config chung, lịch bắn và artwork thân sạch/vũ khí riêng. Tài liệu này là nguồn hành vi hiện hành. [Resource loadout](player-loadout.md) mô tả nền tảng và bộ atlas cũ được giữ làm reference/regression.

## Quy trình và phạm vi

Mỗi lần mở game, người chơi thực hiện lại quy trình chọn nhân vật → chọn Body → chọn vũ khí → vào trận. Không lưu lựa chọn giữa các lần mở game. Robot, Xe tăng và mọi vũ khí tương thích đều mở sẵn; chưa có cơ chế mua hoặc mở khóa.

Mỗi nhân vật hiện có một Body. Dữ liệu cần hỗ trợ nhiều Body trong tương lai. Mỗi nhân vật chỉ được trang bị một loại vũ khí tại một thời điểm. Cặp tên lửa trái/phải là một bộ vũ khí; không lắp đồng thời với súng.

Triển khai thân sạch và các lớp vũ khí riêng cùng đợt với màn hình chọn nhân vật và gameplay này. Đây là yêu cầu đã chốt, không còn là đề xuất nâng cấp về sau.

## Nhân vật

Giáp chống chịu chính là HP của nhân vật. Sát thương trừ trực tiếp HP, không có thanh giáp riêng hoặc cơ chế giảm sát thương.

| Nhân vật | Body ban đầu | HP | Tốc độ di chuyển (world units/giây) | Vũ khí tương thích |
| --- | --- | --- | --- | --- |
| Robot hai chân | Một Body từ robot hiện tại | 5 | 150 | Một nòng dài trên đầu, Gatling trên đầu, hai nòng trên đầu, tên lửa hai bên |
| Xe tăng | Một Body xe tăng | 10 | 100 | Một nòng, hai nòng, ụ tên lửa trái/phải |

## Vũ khí và nhịp bắn cơ bản

Thời gian nghỉ được tính từ viên cuối của loạt hiện tại đến viên đầu của loạt tiếp theo. Mốc thời gian trong bảng tính từ lúc bắt đầu loạt.

| Vũ khí | Sát thương mỗi viên/quả | Chuỗi bắn | Thời gian nghỉ |
| --- | --- | --- | --- |
| Một nòng | 3 HP | Một viên tại 0 giây | 1 giây |
| Gatling, chỉ Robot | 1 HP | Sáu viên tại 0; 0,1; 0,2; 0,3; 0,4; 0,5 giây | 0,8 giây |
| Hai nòng | 1 HP | Hai viên song song, đồng thời tại 0 giây | 0,6 giây |
| Tên lửa | 3 HP | Bên phải tại 0 giây, bên trái tại 0,3 giây | 1,5 giây |

Súng hai nòng của Robot và Xe tăng đều gây 1 HP cho mỗi viên. Hai viên có va chạm riêng; cả hai trúng cùng mục tiêu thì gây tổng cộng 2 HP.

Đạn và tên lửa bay thẳng, gây sát thương cho đối tượng chạm đầu tiên rồi biến mất. Không xuyên mục tiêu, không tự tìm mục tiêu, không gây sát thương diện rộng. Enemy và Brick nhận sát thương theo từng viên. Steel chặn đạn và tên lửa nhưng không mất HP.

## Rule chung cho một loạt bắn

- Loạt đã bắt đầu phải bắn hết dù người chơi thả nút bắn.
- Khi còn viên chưa bắn trong loạt, nhân vật không được di chuyển hoặc đổi hướng. Vì vậy vị trí và hướng bắn giữ nguyên trong loạt.
- Mở khóa di chuyển và đổi hướng ngay sau viên cuối; người chơi được di chuyển trong thời gian nghỉ.
- Một nòng và hai nòng hoàn tất loạt cơ bản tức thời, không có thời gian đứng yên bổ sung hoặc khóa theo animation.
- Giữ nút bắn sẽ tự bắt đầu loạt tiếp theo khi hết thời gian nghỉ.

Gatling cơ bản khóa di chuyển trong 0,5 giây; tên lửa cơ bản khóa trong 0,3 giây.

## Power-up

Giữ Rapid Fire và Double Shot, cho phép kết hợp cả hai.

### Rapid Fire

Giảm một nửa thời gian nghỉ giữa các loạt. Không thay đổi thời điểm bắn trong loạt hoặc thời gian khóa di chuyển.

| Vũ khí | Nghỉ khi có Rapid Fire |
| --- | --- |
| Một nòng | 0,5 giây |
| Gatling | 0,4 giây |
| Hai nòng | 0,3 giây |
| Tên lửa | 0,75 giây |

### Double Shot

Nhân đôi số viên trong loạt, giữ nguyên sát thương mỗi viên và thời gian nghỉ cơ bản. Khoảng cách giữa hai lần bắn bổ sung của một nòng, hai nòng và từng bên tên lửa là 0,08 giây.

| Vũ khí | Chuỗi bắn khi có Double Shot | Mở khóa di chuyển |
| --- | --- | --- |
| Một nòng | Một viên tại 0 giây, một viên tại 0,08 giây | Sau viên tại 0,08 giây |
| Hai nòng | Một cặp tại 0 giây, một cặp tại 0,08 giây; tổng cộng bốn viên | Sau cặp tại 0,08 giây |
| Gatling | 12 viên liên tiếp trong cùng 0,5 giây của loạt cơ bản | Sau viên cuối tại 0,5 giây |
| Tên lửa | Phải tại 0 và 0,08 giây; chờ 0,3 giây sau quả phải thứ hai; trái tại 0,38 và 0,46 giây | Sau quả tại 0,46 giây |

Gatling Double Shot cần tăng nhịp bắn để giữ nguyên thời lượng loạt. Nếu phân bố đều cả 12 viên, khoảng cách là `0,5 / 11` giây, với viên đầu tại 0 và viên cuối tại 0,5 giây.

Khi cả hai power-up cùng hoạt động, áp dụng chuỗi bắn Double Shot và giảm một nửa thời gian nghỉ bằng Rapid Fire.

## Config chung hiện hành

`config/player_characters.json` là nguồn thông số gameplay cho màn hình chọn nhân vật và cả `Simulation.new()` độc lập. `gd/character_catalog.gd` đọc, kiểm tra và tạo resource Body/Weapon/Loadout; có thể truyền loadout tùy chỉnh để chạy regression hoặc thử nghiệm. Export Web bao gồm config JSON và manifest artwork.

File cần chứa:

- ID, tên nhân vật, HP và tốc độ di chuyển.
- Danh sách Body, Body mặc định và liên kết resource hình ảnh qua ID.
- Danh sách vũ khí tương thích và vũ khí mặc định.
- Sát thương mỗi viên, tốc độ đạn, vị trí nòng, số viên và thời điểm bắn trong loạt.
- Thời gian nghỉ và thông số biến đổi của Rapid Fire/Double Shot, gồm khoảng cách 0,08 giây.

Sprite và animation tiếp tục dùng resource hình ảnh riêng. Tách thông số gameplay khỏi resource artwork để chỉnh HP, tốc độ hoặc nhịp bắn mà không phải sửa code hay sprite.

Khi tải config, kiểm tra ID, tham chiếu, tính tương thích và giá trị số; lỗi cần chỉ rõ mục cấu hình sai. Khi chạy từ source, chỉnh config rồi khởi động lại game để áp dụng. Bản game đóng gói cần xuất lại để chứa config mới. Chưa yêu cầu nạp lại config trong lúc chơi.

## Màn hình chuẩn bị

- Hai thẻ chọn nhân vật: Robot và Xe tăng, kèm HP và tốc độ.
- Phần chọn Body; hiện có một lựa chọn cho mỗi nhân vật.
- Phần chọn một vũ khí trong danh sách tương thích.
- Hình xem trước cập nhật theo Body/vũ khí, với nút bốn hướng và đứng/di chuyển/bắn. Preview pose bắn minh họa recoil; nhịp bắn thực tế được kiểm tra trong simulation.
- Thông tin sát thương, số viên, thời lượng loạt và thời gian nghỉ.
- Nút “Vào trận” sử dụng cấu hình vừa chọn.

Màn hình dùng ScrollContainer: desktop và mobile có đủ nút vào trận; màn hình nhỏ có thể cuộn. Sau thắng/thua hiển thị kết quả và cho chọn lại; giữ lựa chọn cũ khi chơi lại nếu không đổi. Mỗi lần mở game khởi tạo lựa chọn mặc định từ config.

## Artwork bắt buộc: thân sạch và vũ khí riêng

### Body độc lập với vũ khí

Chuẩn bị một bộ sprite Body sạch cho Robot và một bộ cho Xe tăng. Body không chứa súng, nòng, bệ tên lửa hoặc chớp nòng của vũ khí. Phần đầu, giáp, khung gầm và bề mặt tại điểm lắp phải hoàn chỉnh để bản thân Body không có khoảng hở khi tháo vũ khí.

Giữ nhận diện và phong cách Robot hiện tại khi tạo Body sạch. Có thể dùng artwork hiện có làm nguồn tham chiếu hoặc chỉnh sửa, nhưng resource Body runtime cuối cùng phải sử dụng hình thân đã hoàn thiện. Không tiếp tục phụ thuộc vào việc bỏ vùng súng khỏi atlas cũ và vẽ tấm giáp bù để tạo thân sạch lúc runtime.

### Các bộ vũ khí

| Nhân vật | Bộ artwork vũ khí cần có |
| --- | --- |
| Robot | Một nòng dài, Gatling, hai nòng, bộ tên lửa trái/phải |
| Xe tăng | Một nòng, hai nòng, ụ tên lửa trái/phải |

Vũ khí nằm trong resource/lớp hình riêng, gồm phần bệ hoặc ụ thuộc vũ khí. Cặp tên lửa có thể gồm các lớp trái/phải để ghép đúng chiều sâu và kích hoạt hiệu ứng từng bên, nhưng vẫn là một lựa chọn trang bị. Chỉ tái sử dụng artwork giữa hai nhân vật nếu phù hợp kích thước, góc nhìn và điểm lắp.

### Hợp đồng ghép hình

- Body và vũ khí phải hỗ trợ đủ bốn hướng up/down/left/right và các trạng thái idle/walk/attack được game sử dụng.
- Khai báo anchor, scale, socket lắp và tọa độ đầu nòng theo từng hướng. Nếu animation làm điểm lắp dịch chuyển, dữ liệu phải mô tả offset tương ứng theo frame.
- Ghép vũ khí theo socket của Body; xác định thứ tự vẽ theo hướng để bộ tên lửa hai bên nằm đúng trước/sau thân.
- Giữ animation thân và vũ khí đồng bộ, không để vũ khí trượt hoặc nhảy khỏi điểm lắp khi đổi frame hoặc hướng.
- Chớp nòng và hiệu ứng phóng gắn với từng lần phát đạn thực tế, đúng nòng và đúng bên. Thời lượng hiệu ứng không kéo dài khóa di chuyển sau viên cuối.
- Màn hình xem trước và chiến trường dùng cùng dữ liệu và cách ghép Body/Weapon.
- Geometry đầu nòng cho simulation phải khớp vị trí hình đã ghép; collider nhân vật được cấu hình riêng, không suy ra từ alpha của sprite.

### Nguồn và chuyển đổi

Giữ generation sources trong các thư mục mô tả nhân vật và vai trò như thân/vũ khí. Lưu nguồn tham chiếu, manifest và thông tin anchor/socket để có thể tạo lại hoặc sửa từng hướng.

Chỉ gỡ resource và nguồn atlas cũ sau khi bộ mới đã tích hợp, kiểm tra đầy đủ dependency runtime/source/reference và xác nhận không còn nơi sử dụng. Cập nhật manifest, tài liệu asset và đường dẫn fingerprint QA khi thay hoặc chuyển nguồn. Thực hiện theo [quy định bảo trì](../maintenance.md).

## Kiến trúc và tính khả thi

Tính năng khả thi và đã mở rộng từ resource Body/Weapon/Loadout, socket, lựa chọn trước trận và va chạm từng viên. Các phần tích hợp:

1. Đọc và kiểm tra config chung, tạo dữ liệu nhân vật và loadout tương thích.
2. Lấy HP/tốc độ từ cấu hình thay cho hằng số player; HUD tính phần trăm HP theo HP tối đa của nhân vật.
3. Dùng chuỗi bắn có thời điểm cho mọi vũ khí; quản lý khóa di chuyển đến viên cuối và cooldown sau loạt.
4. Áp dụng biến đổi chuỗi bắn và cooldown cho hai power-up.
5. Dựng màn hình chuẩn bị và truyền cấu hình vào simulation khi vào trận.
6. Tạo Body sạch cho Robot/Xe tăng và các bộ vũ khí riêng theo hợp đồng artwork ở trên; thay cách ghép dùng vùng cắt atlas cũ bằng Body hoàn chỉnh và lớp vũ khí độc lập.

Không xóa nguồn artwork hiện tại trước khi kiểm tra dependency runtime và nguồn/reference.

## Kiểm chứng và các điểm cần hoàn thiện khi triển khai

Kiểm tra HP/tốc độ cho hai nhân vật; giới hạn một vũ khí; tương thích Body/Weapon; sát thương từng viên lên Enemy/Brick; Steel chặn mọi loại đạn; nhịp bắn và thời gian nghỉ; thả/giữ nút bắn; khóa và mở khóa di chuyển; Rapid Fire/Double Shot riêng và kết hợp.

Cần giữ pause đóng băng loạt đang chờ và hủy loạt của nhân vật đã chết để tránh đạn xuất hiện sau khi hồi sinh, theo hành vi nền hiện tại. Kiểm tra mở game bắt đầu lại quy trình chọn, bố cục desktop/mobile và geometry nòng ở bốn hướng.

QA artwork phải xem Body riêng và mọi cấu hình Body/Weapon ở đủ bốn hướng, các trạng thái idle/walk/attack và các frame chuyển tiếp. Xác nhận không còn hình súng cũ trên Body, không hở giáp, không sai thứ tự lớp, không lệch socket và không chớp nòng sai bên. Kiểm tra đầu nòng sát Brick/Steel/Enemy để đạn không sinh xuyên vật cản. Chụp render native cho màn hình chuẩn bị và chiến trường; chỉ hoàn tất đợt triển khai khi cả artwork thân sạch và gameplay đã được kiểm chứng.

## Quyết định triển khai cho các điểm còn mở

- Tên lửa bay thẳng 300 world units/giây; súng 410. Mỗi viên chạm đối tượng đầu tiên rồi mất, không homing/AoE.
- Chốt Rapid Fire và Double Shot tại lúc bắt đầu loạt. Hết hiệu lực giữa loạt không đổi chuỗi đã chốt hoặc thời gian nghỉ; nhặt giữa loạt áp dụng từ lần kích hoạt sau. Power-up và thời gian còn lại vẫn giữ khi hồi sinh, nhưng hủy toàn bộ viên chưa bắn của actor cũ.
- Sau thắng/thua mở lại màn hình chọn, giữ cấu hình đang dùng làm lựa chọn mặc định. Vào trận tạo simulation mới. Không lưu ra đĩa.
- Artwork dùng 36 pose tách lớp trong atlas mới, với bốn hướng được vẽ riêng. Animation đi được tạo bằng chuyển động phần chân/xích dưới thân; torso/socket cố định. Recoil vũ khí đọc shot clock, flash/phóng đọc từng sự kiện projectile. Idle giữ pose tĩnh. Đây là quyết định artwork của đợt triển khai, không phải yêu cầu ban đầu về số frame.

## Resource và invariants thực thi

`gd/character_selection.gd` và `gd/battle_view.gd` dùng chung hàm ghép hình. `gd/character_art.gd` tạo SpriteFrames từ vùng/anchor/socket khai báo trong `assets/sprites/characters/manifest.json`; không cắt súng khỏi thân hoặc vẽ giáp bù. Tên lửa ở góc nhìn ngang có vùng phía sau thân và vùng phía trước thân. Geometry từng nòng nằm trong config, collider riêng cho từng nhân vật (bán kính 14), độc lập alpha.

`gd/player_weapon.gd` tạo schedule `{time, barrels}`. Một nòng/hai nòng bắt đầu và hoàn tất tức thời; Gatling/tên lửa giữ hàng đợi đến viên cuối. Cooldown tổng ở actor bằng thời lượng loạt cộng thời gian nghỉ đã chốt. Mỗi update xử lý các event đến hạn trước; chỉ di chuyển phần thời gian còn lại sau khi khóa kết thúc. Pause không tiến hàng đợi/clock. Sai số thời điểm hiển thị tối đa một bước simulation (tối đa 0,05 giây); không bỏ viên khi nhiều event đến hạn cùng bước.

Đạn player quét đoạn từ trục tâm collider đến đầu nòng, giữ offset ngang riêng của từng viên, theo bước tối đa 2 units. Đạn đã sinh tiếp tục quét bước tối đa 5 units. Override `player_muzzle_distances` dịch phần chiều dài chung, giữ vị trí tương đối giữa các nòng. Điều này chặn trường hợp đầu nòng nằm qua tường/địch sát thân.

Nguồn, prompt và fingerprint: [Artwork nhân vật](../assets/characters.md). Atlas cũ còn là reference và được các test resource cũ dùng; không xóa.

## Kết quả QA triển khai

`make test` đạt 914 kiểm tra character selection, 392 loadout, 39 power-up, 234 acceptance, 264 enemy, 24 map và player asset/integration, không lỗi.

`godot_tests/character_selection.gd` kiểm tra cả 7 loadout ở bốn hướng, stats, khả năng tương thích, config sai, geometry nòng, damage/steel, chuỗi bắn theo thời điểm, release/hold, khóa/hết khóa, pause, chết/hồi sinh và mọi tổ hợp Rapid Fire/Double Shot. Bao phủ pickup/expiry giữa loạt và delay Double Shot lấy từ config. `make test` còn chạy toàn bộ regression loadout, power-up, acceptance và asset player/enemy/map; các fixture legacy truyền resource cũ rõ ràng.

`godot_tests/character_selection_visual.gd` chụp renderer native ở 1280×1000, 390×844 và 320×568, chiến trường Xe tăng/tên lửa, Body riêng và 7 bộ ghép trong bốn hướng × ba trạng thái, thêm bốn frame chuyển tiếp. Chấm xanh trên ô attack là marker geometry nòng phục vụ QA, không phải flash gameplay. Animation chân/xích dùng chuyển động procedural nhỏ; chất lượng locomotion có thể tiếp tục cải thiện bằng các pose riêng về sau. Web PWA chưa được chạy trong trình duyệt ở đợt này.

![Màn hình chuẩn bị desktop](../images/character-selection-desktop.png)

![Body sạch và các bộ vũ khí: mỗi hướng gồm đứng/di chuyển/bắn](../images/character-selection-layers.png)
