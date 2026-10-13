# Robot Defense

Game 2D top-down dùng Godot 4.7.2, GDScript và renderer Compatibility. Bảo vệ căn cứ qua 5 đợt tấn công; điều khiển bằng WASD/mũi tên và Space, pause bằng P/Escape. Map biên soạn bằng scene Godot; camera theo player, HUD và điều khiển cảm ứng nằm trên màn hình.

```sh
godot --path .
make test
```

Bắt đầu đọc tại [mục lục tài liệu](docs/README.md). Hướng dẫn chạy, kiểm thử và Web PWA ở [phát triển dự án](docs/development.md).

- [Resource loadout](docs/features/player-loadout.md): nền tảng socket/geometry và bộ atlas tham chiếu.
- [Chọn nhân vật](docs/features/character-selection.md): Robot/Xe tăng, Body sạch, 7 bộ vũ khí và config gameplay chung.
- [Power-up](docs/features/power-ups.md): 5 vật phẩm, countdown, luật sinh và tuning.
- [Bố cục nhà máy cũ](docs/features/map/industrial-layout.md): hai tuyến ống dọc nối bơm, chiến trường thoáng và không đặt cỏ.
- [Object môi trường và weapon pickup](docs/features/map/environment-objects.md): artwork nhà máy cũ, collision độc lập và catalog dùng trên mọi map.
- [Biên soạn map](docs/features/map/authoring.md): TileMapLayer, object, marker, validation và map công nghiệp mẫu.
- [Phạm vi refactor map](docs/features/map/refactor-plan.md): kiến trúc và tiêu chí đã triển khai; giới hạn kiểm thử thiết bị được ghi riêng.
- [Tính năng và kiến trúc](docs/README.md#tính-năng): gameplay, map và rendering robot.
- [Quy trình nâng cấp](docs/README.md#quy-trình): tạo/thay sprite, tích hợp và kiểm tra.
- [Asset đang dùng](docs/README.md#asset): runtime resources, nguồn và geometry.
- [QA và giới hạn](docs/README.md#qa): kết quả generation/kiểm tra và các điểm chưa xác nhận.

Runtime assets nằm trong `assets/sprites/` và `assets/terrain/`; nguồn đang dùng nằm trong `assets/generated/`, được loại khỏi import/export. Quy ước phát triển và tài liệu ở [AGENTS.md](AGENTS.md).

![Map trong game](docs/images/map-art-in-game.png)
