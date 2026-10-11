# Bảo trì tài liệu và asset

## Nơi đặt tài liệu

Tập trung Markdown trong `docs/`. Gốc repository chỉ giữ `README.md` làm điểm bắt đầu và `AGENTS.md` để agent tự đọc quy ước. Không đặt thêm README hoặc QA Markdown bên cạnh PNG/TRES/raw.

| Thư mục | Vai trò |
| --- | --- |
| `docs/features/<feature>/` | Hành vi, trách nhiệm code, invariants và quyết định thiết kế |
| `docs/workflows/` | Các bước tạo/thay/tích hợp/kiểm tra |
| `docs/assets/` | Resource, animation, geometry và nguồn của bộ đang dùng |
| `docs/qa/<asset>/` | Bằng chứng generation, giới hạn và kết quả kiểm tra lịch sử |
| `docs/images/` | Ảnh minh họa/preview dùng trong tài liệu |

Tính năng nhỏ có thể dùng một file trong `docs/features/`; tính năng lớn như map hoặc robot dùng thư mục riêng. Cập nhật [mục lục](README.md) khi thêm tài liệu. Dùng link tương đối giữa tài liệu; đường dẫn code/asset trong nội dung tính từ gốc repository. Giữ một nơi mô tả chi tiết mỗi chủ đề, các nơi khác dẫn link tới đó.

## Nguồn hiện hành và ứng viên

Tên thư mục nguồn mô tả asset và vai trò, thay vì chuỗi thử nghiệm v1/v2/v3/v4. Ví dụ `player_mech/down/` và `player_mech/directions/`. ID generation trong JSON/prompt có thể giữ phiên bản lịch sử để không mất provenance; ID đó không phải đường dẫn runtime.

Giữ các nguồn đang tạo ra bộ runtime: raw, prompts, request, base/anchors, extracted frames, composed manifest và reports. Chúng cần cho việc thay một hướng hoặc tái xuất, dù game không trực tiếp load thư mục nguồn. Cả `assets/generated/` được loại khỏi import/export bằng `.gdignore`.

Tạo bản thay thế trong `assets/generated/candidates/<asset-id>/` và dùng file/runtime resource ứng viên riêng trong lúc so sánh. Khi đã duyệt và test pass, chuyển nguồn sang thư mục hiện hành, cập nhật `source_run`/`source_request`, resource runtime và tài liệu asset. Không sửa geometry bằng giá trị mặc định khi chỉ đổi texture.

## Khi nào có thể xóa

1. Kiểm tra toàn bộ tham chiếu từ code, scene, TRES, manifest và workflow. Chỉ không được load trực tiếp bởi game chưa đủ để kết luận nguồn là dư.
2. Xác nhận bản thay thế bằng hash hoặc vùng atlas, cùng frame count/geometry. Nguồn dùng làm base/reference phải có bản giữ lại trước khi xóa bản cũ.
3. Xóa run đã bị thay thế, file loose trùng nguồn đã giữ và request thử nghiệm không dùng. Git lưu lịch sử thay vì giữ mọi phiên bản ngay trong checkout.
4. Cập nhật đường dẫn metadata và link Markdown. Nếu di chuyển report chứa `source_fingerprints`, giữ hash và kiểm tra hash vẫn khớp file tại đường dẫn mới; không biến report cũ thành kết quả kiểm tra mới.
5. Chạy `make test`, kiểm tra liên kết và `git diff --check`. Chạy render native khi đổi PNG, rect, geometry hoặc lớp vẽ.

## Lần dọn hiện tại

Đã xóa player-mech-v1/v2 và các file base/request loose không còn cần; 54 file, khoảng 10.6 MiB. Hai atlas của player-mech-v3/v4 khớp byte với PNG runtime đang dùng, nên nguồn được giữ và chuyển thành `player_mech/down` và `player_mech/directions`. Nguồn enemy và map cũng được đổi sang tên asset hiện hành.

Runtime PNG/TRES, code GDScript và scenes giữ nguyên nội dung. Các chi tiết kỹ thuật của lần dọn nằm trong `cleanup-summary.json`.
