# Minigolf Basic Project

Game minigolf 2D với đồ họa pixel, được xây dựng bằng **Godot và GDScript** cho Basic Project 2026–2027. Người chơi kéo và thả chuột để đưa bóng vào lỗ với ít gậy nhất, đồng thời tính toán lực đánh, mặt sân và các chướng ngại vật.

> **Trạng thái: Bản chơi 10 màn, đang cân bằng và hoàn thiện.** F5 mở menu chính với HUD, chọn màn, pause, kết quả, sao và lưu tiến độ. Nhạc nền và hiệu ứng âm thanh đã được tích hợp; chưa đóng gói bản phát hành.

## Tính năng hiện có

- Đánh bóng bằng thao tác kéo/thả, có vạch ngắm và giới hạn lực đánh.
- Đếm số gậy và hiển thị thông báo khi hoàn thành lỗ ở sân chính.
- Mặt cỏ và cát có mức giảm tốc khác nhau.
- Rơi xuống nước sẽ hồi bóng về vị trí trước cú đánh và cộng gậy phạt.
- Ô mũi tên đổi hướng lăn của bóng.
- Bumper tròn và tam giác phản xạ, tăng tốc bóng.
- Chướng ngại vật xoay, di chuyển qua lại và cửa ẩn/hiện theo chu kỳ.
- Cặp cổng dịch chuyển cam–xanh và hiệu ứng khi bóng đi qua cổng.
- Menu tiếng Anh và HUD dùng atlas SummerUI v2 đã duyệt; chọn 10 màn, pause, kết quả và cài đặt.
- Mở khóa màn, lưu số gậy tốt nhất và sao theo ngưỡng riêng từng màn.
- Continue mở lại màn gần nhất; New Game có xác nhận, giữ cài đặt. Hồ sơ có bản dự phòng và tự khôi phục file ghi dở/hỏng khi còn bản hợp lệ.

## Yêu cầu

- **Godot 4.7** theo cấu hình trong [project.godot](project.godot).
- Project dùng **GDScript** và renderer **Forward+**; không cần bản Godot .NET.
- Git nếu tải source bằng lệnh clone; cũng có thể dùng **Code → Download ZIP** trên GitHub rồi giải nén.

## Tải và chạy game

1. Tải project:

   ```sh
   git clone https://github.com/GabTommy2006/Basic-Project---2026-27---Minigolf.git minigolf
   cd minigolf
   ```

2. Mở Godot, chọn **Import** và chọn file `project.godot` trong thư mục vừa tải.
3. Mở project và chờ Godot import tài nguyên.
4. Mở [Maps/TestMap.tscn](Maps/TestMap.tscn), rồi nhấn **F6** để chạy sân chơi thử.

**F5** mở menu chính `UI/Main.tscn` để chơi bộ 10 màn với HUD và lưu tiến độ.

Để thử các chướng ngại vật và cổng dịch chuyển, mở [Maps/MechanicsPlayground.tscn](Maps/MechanicsPlayground.tscn) rồi nhấn **F6**. Sân này có các khu riêng, mỗi khu có bóng để thử cơ chế tương ứng.

## Cách chơi

1. Chờ bóng dừng lại.
2. Nhấn giữ **chuột trái** gần tâm bóng.
3. Kéo chuột **ngược hướng muốn đánh**; kéo càng xa thì lực càng lớn, tới giới hạn cho phép.
4. Thả chuột để đánh bóng.

Đưa bóng vào miệng lỗ với tốc độ đủ chậm để hoàn thành. Bóng đi quá nhanh có thể lăn qua lỗ.

- Trong **TestMap**, nhấn **R sau khi đưa bóng vào lỗ** để chơi lại.
- Trong **MechanicsPlayground**, nhấn **R bất cứ lúc nào** để đặt lại toàn bộ sân thử.
- Trong Godot, nhấn **F8** để dừng chạy game và quay lại editor.

## Cấu trúc project

```text
Assets/           Hình ảnh, font và TileSet
Maps/             Sân chơi thử và sân thử cơ chế
  Courses/        10 sân chơi đã vẽ và xếp thứ tự
UI/               Menu, chọn màn, HUD, pause, kết quả và cài đặt
Game/             Danh mục màn, luật sao và lưu tiến độ
Objects/          Bóng, lỗ, bumper, vật cản và cổng dịch chuyển
Tools/Courses/    Bố cục JSON và công cụ hỗ trợ dựng/xem sân
Tests/            Script kiểm thử các cơ chế
Docs/             Tài liệu hướng dẫn chỉnh sửa project
project.godot     Cấu hình project Godot
```

Các thư mục `.godot/`, `tmp/` và `output/` được bỏ qua trong Git vì chứa cache, file tạm và kết quả xuất cục bộ.

## Phần đang phát triển

- Các scene `Maps/Courses/Map1.tscn` đến `Map10.tscn` là 10 sân hiện tại. F5 mở `UI/Main.tscn`; F6 vẫn chạy scene sân độc lập.
- Công cụ và tài liệu bộ sân còn tham chiếu tên `Map01.tscn`–`Map09.tscn`; script dựng sân còn cần `Maps/Courses/course.gd`, hiện chưa có trong repo. Phần này cần hoàn thiện trước khi dùng công cụ dựng/xem hoặc bài kiểm thử bộ sân.
- Menu, chọn sân, chuyển màn qua nút kết quả, sao và lưu tiến độ đã có. Cần playtest/cân bằng và cấu hình export bản phát hành.

Để chơi bản hiện tại, nhấn F5. `TestMap.tscn` và `MechanicsPlayground.tscn` vẫn dùng để thử cơ chế riêng bằng F6.

## Tài liệu và kiểm thử

- [Hướng dẫn đặt và chỉnh các vật thể trên map](Docs/DatVatTheLenMap.md).
- [Hướng dẫn chạy các script kiểm thử cơ chế](Tests/README.md).
- [HUD, giao diện, lưu tiến độ và luật sao](Docs/UIHUD.md).
- [Dữ liệu người chơi, New Game và khôi phục hồ sơ](Docs/PlayerData.md).
- [Bộ âm thanh CC0 đã tích hợp và cách nghe thử](Docs/AudioSelection.md).

Các script kiểm thử nằm trong `Tests/` và chạy bằng Godot ở chế độ headless. Chúng phục vụ kiểm tra cơ chế; không cần chạy để mở và chơi thử game.
