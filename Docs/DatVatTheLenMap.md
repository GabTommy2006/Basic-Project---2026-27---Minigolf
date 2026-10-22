# Đặt 5 cơ chế SummerTile lên map

Các scene đã lấy hình trực tiếp từ SummerTile.png. Chỉ cần kéo scene vào map,
không phải tạo lại Region, va chạm hoặc script cho mỗi lần đặt.

## Chơi thử trước

Mở [MechanicsPlayground.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Maps/MechanicsPlayground.tscn>) trong Godot rồi nhấn **F6** để chạy riêng sân thử.
F5 vẫn chạy sân chính đã chọn trong project.

Sân thử chia thành 5 khu có nhãn và có bóng riêng. Giữ chuột trái gần một quả bóng,
kéo ra sau rồi thả để đánh. **R** đặt lại cả sân. Có thể đánh lực nhẹ để thử vào lỗ.

## Đặt một đồ vật vào sân của bạn

1. Mở scene sân, ví dụ TestBeta, rồi chọn node gốc của sân trong Scene Tree.
2. Trong FileSystem, tìm scene đồ vật ở các thư mục Objects/Obstacles,
   Objects/Bumpers hoặc Objects/Portal.
3. Kéo file .tscn từ FileSystem vào khung 2D. Đồ vật nên là node con của sân,
   cùng cấp với Ball và TileMap.
4. Di chuyển đồ vật tới vị trí muốn đặt. Bên dưới vẫn có thể vẽ cỏ, cát hoặc nước bằng TileMap.
5. Chọn node gốc của instance vừa đặt, rồi chỉnh các thông số script trong Inspector.
6. Lưu scene và nhấn F6 để thử sân đang mở.

Dùng Ctrl+D để nhân bản một instance. Mỗi instance có thông số riêng.
Trong sân hiện tại, Ball tự tìm node TileMap cùng cấp để đọc cát, nước và mũi tên.
Nếu đổi cấu trúc node, hãy gán lại Surface Tile Map trên Ball bằng TileMap của sân.

## 1. Chướng ngại vật xoay màu xám

Các scene:

- [RotatingBar.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/RotatingBar.tscn>): thanh xám ngắn.
- [RotatingLongBar.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/RotatingLongBar.tscn>): thanh xám dài.
- [RotatingDiamond.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/RotatingDiamond.tscn>): khối xám hình thoi.

Chọn node gốc của đồ vật:

- **Angular Speed Degrees**: tốc độ quay, tính bằng độ/giây; 90 là một phần tư vòng mỗi giây.
- **Clockwise**: bật để quay theo chiều kim đồng hồ, tắt để quay ngược.
- **Enabled**: bật/tắt chuyển động; tắt vẫn giữ va chạm.
- **Transform → Rotation**: góc xuất phát khi bắt đầu chơi.

Đồ vật quay quanh tâm node gốc. Hình ảnh và collider cùng quay, nên có thể đập bóng thật.
Script: [rotating_obstacle.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/rotating_obstacle.gd>).

## 2. Thanh vàng hiện/ẩn

Kéo [BlinkingGate.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/BlinkingGate.tscn>) vào map.

- **Visible Duration**: số giây hiện và chặn bóng, mặc định 1.5.
- **Hidden Duration**: số giây ẩn và cho bóng xuyên qua, mặc định 1.0.
- **Start Hidden**: bật để bắt đầu ở trạng thái ẩn.
- **Start Delay**: giữ trạng thái ban đầu thêm một khoảng trước khi chạy chu kỳ.
- **Fade Duration**: thời gian mờ/hiện mỗi lượt, mặc định 0.2 giây; giảm để chuyển nhanh hơn.
- **Transform → Rotation = 90°**: đặt thanh đứng dọc thay vì nằm ngang.

Cửa mờ dần và bóp nhẹ trước khi biến mất; khi hiện thì sáng dần và trở về kích thước gốc.
Trong lúc chuyển cảnh, collider luôn tắt. Chỉ khi cửa đã hiện đầy đủ và vùng đóng không có bóng,
va chạm mới được bật. Nếu bóng đi vào lúc đang hiện, cửa mờ ra và chờ bóng rời vùng rồi thử lại.
Visible Duration chỉ tính lúc đã hiện đủ; Hidden Duration chỉ tính lúc đã ẩn hẳn.
Script: [blinking_gate.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/blinking_gate.gd>).

## 3. Vật cản di chuyển

Kéo [MovingObstacle.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/MovingObstacle.tscn>) vào map.

1. Đặt node gốc **MovingObstacle** tại đầu đường chạy.
2. Trong Scene Tree, nhấp phải instance đó và bật **Editable Children**.
3. Mở cây con, chọn **EndPoint** rồi kéo dấu marker tới đầu đường còn lại.
4. Chọn lại node gốc để chỉnh **Travel Duration** và **Pause Duration**.

- **Travel Duration**: số giây đi một chiều. Giảm xuống thì chạy nhanh hơn; tăng lên thì chậm hơn.
- **Pause Duration**: thời gian dừng ở mỗi đầu trước khi quay lại.
- **Start Delay**: thời gian chờ trước khi bắt đầu.
- **Enabled**: tắt để giữ vật cản đứng tại vị trí hiện tại.

Đường chạy mặc định dài 48 pixel sang phải. Muốn đi dọc, đặt EndPoint tại X=0, Y=48;
muốn đi chéo, ví dụ X=48, Y=32. Tọa độ marker là tọa độ local so với node gốc.
Trong sân thử, EndPoint đã được mở quyền chỉnh sẵn.

Node **Body** là phần đang chạy. **EndPoint** đứng yên để làm đích.
Script: [moving_obstacle.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Obstacles/moving_obstacle.gd>).

## 4. Bumper làm bóng bật mạnh

Các scene dùng chung cơ chế:

- [RoundBumper.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Bumpers/RoundBumper.tscn>): hình tròn tím.
- [TriangleTopLeft.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Bumpers/TriangleTopLeft.tscn>): tam giác góc trên trái.
- [TriangleTopRight.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Bumpers/TriangleTopRight.tscn>): tam giác góc trên phải.
- [TriangleBottomLeft.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Bumpers/TriangleBottomLeft.tscn>): tam giác góc dưới trái.
- [TriangleBottomRight.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Bumpers/TriangleBottomRight.tscn>): tam giác góc dưới phải.

Bốn tam giác lấy đúng bốn hình trong SummerTile, có va chạm theo từng góc.
Scene TriangleBumper cũ vẫn dùng được và tương ứng góc trên trái.

Chọn node gốc để chỉnh:

- **Speed Multiplier**: hệ số nhân tốc độ lúc chạm, mặc định 1.35.
- **Minimum Bounce Speed**: tốc độ bật tối thiểu, mặc định 150 pixel/giây.
- **Maximum Bounce Speed**: giới hạn tốc độ bật, mặc định 240 pixel/giây.
- **Cooldown Seconds**: thời gian ngắn chống tăng lực lặp ở cùng mép, mặc định 0.12 giây.

Muốn bật nhẹ hơn, giảm Minimum Bounce Speed và/hoặc Speed Multiplier.
Nếu chỉ giảm hệ số mà mức tối thiểu vẫn là 150 thì cú chạm chậm vẫn bật ở mức 150.

Bóng phản xạ theo đúng cạnh đã chạm. Tam giác chỉ có va chạm ở phần hình tam giác,
không chặn phần trong suốt của ô 16x16. Xoay node gốc 90°, 180° hoặc 270° để đổi hướng đặt.
Bumper nháy sáng ngắn khi nhận cú chạm; một tiếp xúc kéo dài không liên tục nhân lực.
Script: [bumper.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Bumpers/bumper.gd>).

## 5. Hai cổng dịch chuyển đặt độc lập

Cổng cam và xanh là hai scene riêng. Kéo từng cổng vào sân rồi đặt ở vị trí muốn dùng.
Không cần một node nhóm chung hoặc bật Editable Children để di chuyển cổng.

1. Kéo [PortalOrange.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Portal/PortalOrange.tscn>) và
   [PortalBlue.tscn](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Portal/PortalBlue.tscn>) vào cùng sân.
2. Chọn cổng cam, tìm **Destination** trong Inspector rồi chọn node cổng xanh trong Scene Tree.
3. Chọn cổng xanh và gán **Destination** ngược lại tới node cổng cam.
4. Đặt cả hai ở nơi có khoảng trống cho bóng đi ra.

Trong sân thử, PortalOrange và PortalBlue là hai node cùng cấp với Ball và TileMap,
đã gán Destination hai chiều. Có thể chọn từng cổng rồi kéo trực tiếp trong khung 2D.

Destination là **node cổng đã đặt trên sân**, không phải file .tscn trong FileSystem.
Nếu có nhiều cặp, gán từng cặp rõ ràng; màu không tự quyết định cổng nào nối với cổng nào.
Cổng chưa có đích sẽ hiện cảnh báo cấu hình trong editor và chưa dịch chuyển bóng.

Các thông số:

- **Exit Distance**: khoảng đặt bóng cách tâm cổng đích, mặc định 12 pixel.
  Script tự chừa ít nhất đủ chỗ để bóng nằm ngoài vòng nhận của cổng đích.
- **Redirect Exit Direction**: mặc định tắt để giữ tốc độ và hướng đi vào.
  Bật tại cổng nguồn để bóng ra theo hướng X dương của cổng đích.
- **Travel Cooldown**: thời gian khóa nhận lại tối thiểu tại cổng, mặc định 0.2 giây;
  còn phải chờ bóng rời vùng cổng trước khi nhận lượt tiếp theo.

Ví dụ muốn cam đưa bóng ra xanh theo hướng lên: bật Redirect Exit Direction ở cổng cam,
rồi đặt Rotation của cổng xanh bằng -90°. Để mặc định thì cổng giữ nguyên hướng lăn vào.

Cổng không phải vật chắn. Tâm bóng đi vào vùng nhận thì dịch chuyển; không cộng thêm gậy.
Giữ điểm ra và hướng ra tránh tường hoặc đồ vật khác; Exit Distance chỉ chừa khoảng cách
khỏi vòng cổng, không tự tìm đường xuyên qua vật cản.
Script: [portal.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Portal/portal.gd>).

### Hiệu ứng của hai cổng

Các cổng đã đặt từ scene PortalOrange/PortalBlue tự nhận hiệu ứng mới khi chạy lại sân.
Không cần đặt lại cổng hoặc nối lại Destination.

- Khi chờ: nét sáng xoay và nhấp nhô nhẹ theo đúng màu cam/xanh của SummerTile.
- Khi bóng qua: cổng nguồn hút sáng vào, cổng đích phát vòng sáng và tia nhỏ ra ngoài.
- Ảnh bóng ở nguồn thu nhỏ vào tâm cổng; bóng ở đầu ra hiện dần trong **0.16 giây**.
  Đây là hiệu ứng hình ảnh: thân bóng vẫn dịch chuyển ngay và giữ vận tốc đang có.
- Nếu đầu ra là nước hoặc lỗ, hiệu ứng cổng nhường cho hiệu ứng chìm/vào lỗ.

Chọn **Ball** trên sân để chỉnh **Portal Effect Duration** (thời gian thu/hiện hình bóng)
hoặc tắt **Portal Effects Enabled** (chỉ tắt hiệu ứng trên bóng).

Muốn chỉnh ánh sáng của cổng, mở scene PortalOrange hoặc PortalBlue rồi chọn node **PortalVisual**:

- **Effects Enabled**: bật/tắt toàn bộ ánh sáng của cổng đó; cổng vẫn dịch chuyển bình thường.
- **Ambient Enabled**: bật/tắt phần xoáy lúc chờ, vẫn giữ hiệu ứng khi có bóng qua.
- **Effect Color**: màu ánh sáng và màu nhuộm nhẹ lên ảnh bóng khi qua cổng.

Hai scene vẫn tách riêng; chỉnh cổng cam không đổi màu hoặc vị trí cổng xanh.
Code hiệu ứng có chú thích tại
[portal_visual.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Portal/portal_visual.gd>) và
[ball_portal_effect.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Ball/ball_portal_effect.gd>).

## Các cơ chế đang có vẫn dùng chung

Cỏ, cát, nước và mũi tên vẫn được vẽ trên TileMap bằng TileSet đã gắn nhãn.
Đồ vật mới là scene đặt lên lớp nền, không cần vẽ lại chúng như tile trang trí bên dưới.
Tốc độ cú đánh mặc định là 120; ngưỡng nhận bóng của lỗ là 70.
Qua cổng giữ điểm xuất phát cú đánh để nếu sau đó rơi nước, bóng vẫn hồi về đúng điểm trước cú đánh.

Những phần mới trong [ball.gd](</C:/Users/Phuc Hung/Documents/minigolf-basic-project/Objects/Ball/ball.gd>) xử lý cú bật bumper
và dịch chuyển trong bước vật lý. Lịch sử mũi tên và hình bóng lăn được đặt lại ở điểm ra,
để không coi đoạn nối hai cổng là quãng đường bóng đã lăn trên sân.
