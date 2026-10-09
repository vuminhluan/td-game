# Robot Defense

MVP game 2D top-down bằng **Phaser 3 + TypeScript + Vite**. Bảo vệ căn cứ qua 5 đợt robot và xe tăng. Đồ họa được vẽ bằng code, lấy cảm hứng từ concept được cung cấp; chưa phải bộ sprite hoàn thiện từ ảnh concept.

## Chạy game

Cần Node.js 22.12 trở lên.

```sh
npm install
npm run dev
```

Mở địa chỉ mà terminal hiển thị (thường là http://localhost:5173).

```sh
npm test       # kiểm thử luật chơi độc lập với trình duyệt
npm run build # kiểm tra TypeScript và tạo bản phát hành trong dist/
npm run preview # xem bản phát hành
```

## Cách chơi

- WASD hoặc phím mũi tên: di chuyển 4 hướng. Phím được nhấn sau cùng quyết định hướng; không di chuyển chéo.
- Giữ Space: bắn theo hướng đang nhìn. Đạn không giới hạn.
- P hoặc Escape: tạm dừng/tiếp tục. Chuyển sang tab khác tự động tạm dừng.
- Điện thoại: nút điều hướng và nút bắn cảm ứng phía dưới.
- Người chơi có tổng cộng 3 robot, mỗi robot có 5 giáp. Hồi sinh được bảo vệ trong 3 giây.
- Căn cứ chịu được 20 phát đạn địch. Căn cứ bị phá hủy hoặc mất hết robot thì thua; hạ hết 5 đợt thì thắng.
- Gạch: 3 phát để phá, có 3 trạng thái hình ảnh. Cả hai phe đều có thể phá gạch.
- Thép: không thể phá, chặn cả robot và đạn. Nước: chặn robot, đạn bay qua. Cây: đi và bắn xuyên.
- Không có vật phẩm. Đạn của người chơi không làm hại căn cứ.
- Âm thanh tổng hợp tùy chọn, mặc định tắt.

## Cấu trúc để bảo trì

| Tệp | Trách nhiệm |
| --- | --- |
| `src/game/config.ts` | Thông số cân bằng, kích thước bản đồ, kiểu dữ liệu chung |
| `src/game/map.ts` | Tạo bản đồ, kiểm tra di chuyển, Dijkstra tìm đường có tính chi phí phá gạch |
| `src/game/simulation.ts` | Luật chơi độc lập: đợt địch, di chuyển, đạn, sát thương, thắng/thua |
| `src/game/textures.ts` | Vẽ texture một lần lúc khởi tạo, có thể thay bằng atlas sau này |
| `src/game/scene.ts` | Phaser hiển thị mô phỏng và đọc bàn phím |
| `src/main.ts` | Giao diện, điều khiển cảm ứng, radar, âm thanh |
| `tokens.css`, `src/style.css` | Token màu và giao diện responsive |
| `tests/simulation.test.ts` | Kiểm thử hành vi gameplay |

Đổi độ khó tại `RULES` trong `config.ts`; đổi bố cục tại `createMap()`. Địch có thể đi xuyên nhau trong MVP để tránh kẹt đường. Chưa có lưu tiến trình, nhiều màn chơi, animation sprite hoặc multiplayer. Phiên bản Phaser được khóa ở 3.90.0 để dùng API ổn định. Tài liệu chính thức: https://docs.phaser.io/phaser/getting-started/installation

## Kiểm thử trình duyệt

Cài Google Chrome, chạy dev server, rồi chạy `GAME_URL=http://localhost:5173 npm run test:browser` (đổi cổng theo terminal). Script kiểm tra điều khiển, tạm dừng, chơi lại và tràn ngang ở 320/375/414/768px. `npm run format` chuẩn hóa code bằng Prettier.
