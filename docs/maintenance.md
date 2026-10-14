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
5. Chạy `make check` cho resource/link/heading/hash/naming, rồi `make test` và `git diff --check`. Chạy render native khi đổi PNG, rect, geometry hoặc lớp vẽ.

## Dọn source ngày 14/10/2026

Runtime terrain công nghiệp dùng đường dẫn `assets/terrain/industrial/`; code, scene, skin của hai map và atlas builder cùng tham chiếu đường dẫn này. Không đổi PNG, rect hoặc gameplay geometry. Hai ảnh đầu vào correction được giữ dưới tên reference theo vai trò; chỉ xóa rejected rows không thuộc reference chain. Log ImageGen đã được bỏ sau khi giữ generation IDs trong provenance. Screenshot trùng byte dùng một đường dẫn canonical.

Tài liệu kế hoạch đã hoàn thành được gỡ; kiến trúc map nằm trong authoring, quy trình sprite dùng một workflow, QA map/enemy/player được gom theo phạm vi. Đã bỏ 43 file source/output trùng (khoảng 7,4 MiB) và gom 13 Markdown cũ thành các tài liệu hiện hành. Chi tiết số file và dependency audit ở [cleanup-summary.json](cleanup-summary.json). Giữ source/runtime copies và atlas fixture khi còn được generator, reference, catalog, preview hoặc regression dùng.

Checker rebases đường dẫn tuyệt đối trong fingerprint reports về đường dẫn project theo vai trò để clone ở thư mục khác vẫn kiểm tra cùng nội dung nguồn. Generation/schema IDs trong metadata là provenance, không phải tên file có version.
