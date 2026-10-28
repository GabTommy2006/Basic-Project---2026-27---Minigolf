# Chơi và sửa mười sân SummerTile

Các sân hiện tại là `Maps/Courses/Map1.tscn` tới `Map10.tscn`, theo thứ tự đã sắp xếp trong game. Mỗi scene chứa TileMap, Camera2D, Ball, Hole và các vật thể của sân.

## Chạy game

Nhấn **F5** để mở `UI/Main.tscn`: menu, Continue, New Game, chọn sân, cài đặt và hướng dẫn. Hoàn thành sân sẽ lưu số sao/kỷ lục và mở sân tiếp theo. **Esc** mở hoặc đóng bảng pause; **R** trong lúc chơi mở xác nhận chơi lại.

Để thử riêng bố cục, mở một scene Map rồi nhấn **F6**. Cách này chạy riêng sân; dùng F5 khi kiểm tra HUD, chuyển màn và dữ liệu người chơi. Giữ `UI/Main.tscn` làm scene chính của project.

Khi bóng đứng yên, nhấn vào bóng, kéo ngược hướng muốn đánh rồi thả. Trong game đầy đủ, thanh Power hiển thị lực kéo.

## Sửa sân trong Godot

Chọn **TileMap** để vẽ bằng TileSetSummer hiện tại. Di chuyển **Ball**, **Hole** hoặc các node vật thể để đổi vị trí. Hole.png có sẵn ô cỏ riêng; không bắt buộc phải vẽ tile dưới lỗ.

Các thuộc tính ở node gốc của vật thể điều khiển tốc độ quay, chu kỳ gate, đường chạy và lực bật. Với vật thể di chuyển, chỉnh marker EndPoint theo scene thực tế. Với portal, giữ Destination nối hai chiều và chừa khoảng trống an toàn ở đầu ra.

Map 4–10 dùng `Maps/course_follow_camera.gd`: lấy khung sân, theo bóng và xét vị trí lỗ. Khi mở rộng sân, kiểm tra lại camera bằng F5 vì HUD có vùng hiển thị sân riêng. Không mặc định mọi sân có cùng kích thước 24×14 ô.

## Sao và lưu dữ liệu

Ngưỡng sao từng sân nằm trong `Game/courses.json`. Ngưỡng 3 sao của màn 1–10 lần lượt là **2, 3, 3, 4, 5, 4, 5, 5, 6, 7 gậy**. Ngưỡng 2 sao thêm 2 gậy; hoàn thành với nhiều gậy hơn được 1 sao.

Xem `Docs/PlayerData.md` để biết vị trí file lưu, Continue, New Game và khôi phục dữ liệu.

## Công cụ cũ và kiểm tra

JSON và trình dựng trong `Tools/Courses/` là bản phác ban đầu, không phản ánh toàn bộ bố cục đã sửa tay và thứ tự hiện tại. Không dùng chúng để dựng lại các map đang chơi trừ khi chủ động muốn thay bố cục.

Chạy `Tools/run_tests.ps1 -CheckRestart` để kiểm tra các cơ chế, UI, camera và lưu dữ liệu. Kiểm tra trực quan từng sân trong Godot vẫn cần thiết khi thay bố cục.
