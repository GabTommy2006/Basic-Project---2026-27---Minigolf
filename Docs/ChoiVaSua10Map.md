# Bộ mười sân SummerTile

Các sân nằm trong `Maps/Courses/`, mỗi file là một scene độc lập đã có TileMap, Camera2D,
Ball và Hole. Có thể chơi thử ngay và chỉnh bố cục bằng editor; không cần sinh sân lúc chạy.

## Mở và chơi

1. Trong FileSystem của Godot, mở `Maps/Courses/Map01.tscn` hoặc map muốn thử.
2. Nhấn **F6** để chạy scene đang mở.
3. Kéo rồi thả chuột ở bóng để đánh. Nhấn **R** để chơi lại sân bất kỳ lúc nào.

F5 chạy scene chính đang cấu hình trong project. Muốn bắt đầu game ở bộ sân này,
nhấp phải `Map01.tscn` → **Set as Main Scene**.

Mười sân hiện chơi độc lập. Chưa gắn HUD, menu chọn sân hoặc tự chuyển màn;
các phần đó sẽ làm ở bước bạn yêu cầu sau. Root mỗi sân có tín hiệu `course_completed`
báo số màn và số gậy để kết nối giao diện về sau.

## Ý tưởng từng sân

- **Map01 — Cú đánh đầu tiên:** sân cỏ trống, bóng và lỗ cùng hàng cách bảy ô.
  Chỉ tập kéo/thả để đánh vào lỗ; không có cát, nước, mũi tên hoặc vật cản bên trong.
- **Map02 — Vòng quanh đảo cát:** đi vòng khối tường giữa sân, chọn đường cỏ hoặc qua bãi cát.
- **Map03 — Qua hai hồ:** đi giữa hai hồ lệch nhau; luôn có đường cỏ khô nối tới lỗ.
- **Map04 — Zigzag và ba mũi tên:** các mũi tên đưa bóng theo đường gấp khúc; có cát gần đích.
- **Map05 — Ngã tư thanh xoay:** thanh xám ngắn quay ở giữa sân chữ thập, có chỗ dừng trước nó.
- **Map06 — Hai cửa chờ nhịp:** hai cửa vàng chặn hai cửa phòng, có phòng cỏ và cát để chờ giữa chúng.
- **Map07 — Hành lang qua lại:** hai khối xám chạy ngang hai nhánh của sân chữ H.
- **Map08 — Bật bóng qua khúc cua:** bumper tròn và hai tam giác ở sân chữ L;
  vẫn có đường cỏ đi vòng để sửa cú đánh, và bãi cát hãm tốc trước green đặt lỗ.
- **Map09 — Hai đảo dịch chuyển:** nước chia hai nửa sân; dùng cặp cam–xanh đã nối hai chiều.
- **Map10 — Vòng hồ và cánh cửa cuối:** đi quanh hồ rồi canh cửa vàng;
  có cặp cổng làm đường tắt, vẫn đi được bằng đường cỏ bình thường.

## Sửa bằng Godot

Chọn **TileMap** rồi vẽ/sửa trực tiếp bằng TileSetSummer đã gắn nhãn.
Kéo **Ball**, **Hole**, hoặc các node vật thể để đổi vị trí. Chọn node gốc của từng vật thể
để chỉnh tốc độ quay, nhịp ẩn/hiện, thời gian di chuyển hoặc lực bật như trước.

Với Map07, node **LeftPatrol/EndPoint** và **RightPatrol/EndPoint** đã cho phép chỉnh riêng.
Kéo marker để đổi điểm cuối đường chạy. Với cổng, giữ **Destination** hai chiều;
chừa khoảng cỏ ở đầu ra và tránh đặt lỗ sát nơi bóng vừa được bumper tăng tốc.

**Camera2D** đang đặt để thấy trọn khung 24×14 ô, mỗi ô 16 pixel. Nếu mở rộng sân,
chỉnh Position/Zoom của camera để nhìn hết đường bóng.

## Xem ảnh toàn bộ sân

Mở `Tools/Courses/PreviewCourses.tscn` rồi F6 để xem mười sân cùng lúc.
Công cụ xuất ảnh tại `output/courses_overview.png`; scene này chỉ phục vụ xem bố cục.

## Công cụ dựng bố cục gốc

Ba file JSON trong `Tools/Courses/` giữ bản phác ô ban đầu và đường tham khảo.
`build_courses.gd` đã dùng chúng để tạo ra mười scene. Chơi và sửa các scene không cần chạy lại công cụ.

Công cụ mặc định dừng nếu đã có scene để giữ những chỉnh sửa bằng tay.
Cờ `-- --rebuild` cho phép ghi đè toàn bộ mười scene từ JSON, vì vậy chỉ dùng khi thật sự
muốn bỏ bố cục đã sửa và quay lại bản gốc.
