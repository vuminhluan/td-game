# Robot Defense

Game 2D top-down dùng Godot 4.7.2, GDScript và renderer Compatibility. Bảo vệ căn cứ qua 5 đợt tấn công; điều khiển bằng WASD/mũi tên và Space, pause bằng P/Escape. Màn hình hẹp có điều khiển cảm ứng.

```sh
godot --path .
make test
```

Bắt đầu đọc tại [mục lục tài liệu](docs/README.md). Hướng dẫn chạy, kiểm thử và Web PWA ở [phát triển dự án](docs/development.md).

- [Resource loadout](docs/features/player-loadout.md): nền tảng socket/geometry và bộ atlas tham chiếu.
- [Chọn nhân vật](docs/features/character-selection.md): Robot/Xe tăng, Body sạch, 7 bộ vũ khí và config gameplay chung.
- [Power-up](docs/features/power-ups.md): 5 vật phẩm, countdown, luật sinh và tuning.
- [Tính năng và kiến trúc](docs/README.md#tính-năng): gameplay, map và rendering robot.
- [Quy trình nâng cấp](docs/README.md#quy-trình): tạo/thay sprite, tích hợp và kiểm tra.
- [Asset đang dùng](docs/README.md#asset): runtime resources, nguồn và geometry.
- [QA và giới hạn](docs/README.md#qa): kết quả generation/kiểm tra và các điểm chưa xác nhận.

Runtime assets nằm trong `assets/sprites/` và `assets/terrain/`; nguồn đang dùng nằm trong `assets/generated/`, được loại khỏi import/export. Quy ước phát triển và tài liệu ở [AGENTS.md](AGENTS.md).

![Map trong game](docs/images/map-art-in-game.png)
