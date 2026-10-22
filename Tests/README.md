# Kiểm thử các cơ chế SummerTile

Các script chạy bằng SceneTree trong chế độ headless, tạo sân thử trong bộ nhớ.
Chúng không thay đổi map người chơi hoặc ảnh/TileSet gốc.

Chạy từ thư mục project bằng Godot 4.7.x:

```powershell
godot --headless --path . --script res://Tests/obstacles_smoke.gd
godot --headless --path . --script res://Tests/bumper_smoke.gd
godot --headless --path . --script res://Tests/portal_smoke.gd
godot --headless --path . --script res://Tests/portal_effects_smoke.gd
```

Nếu chưa có lệnh `godot` trong PATH, thay bằng đường dẫn đầy đủ tới Godot console .exe,
và thêm `&` phía trước đường dẫn trong PowerShell.
Trong môi trường hạn chế quyền ghi thư mục user, thêm `--log-file` với đường dẫn log trong project.

- `obstacles_smoke.gd`: quay và va chạm thật, đường chạy/pause/quay về, gate mờ/hiện/co nhẹ,
  không chặn khi còn mờ, và chờ bóng ra mới đóng.
- `bumper_smoke.gd`: góc phản xạ và mức tăng tốc của cả hai hình, giới hạn lực, một lần mỗi tiếp xúc,
  cú đánh mới khi bóng đã đứng tựa vào bumper; bốn góc tam giác có cạnh chéo phản xạ đúng
  và không chặn nửa ô trong suốt.
- `portal_smoke.gd`: nối cổng rõ ràng, giữ/đổi hướng vận tốc, khóa chống lặp, điểm ra,
  từ chối bóng đang chìm/đã vào lỗ, và hủy yêu cầu an toàn khi đích bị xóa.
  Kiểm tra cả chiều xanh → cam, đi ngược lại sau lượt trước, và scene PortalPair dùng ngay.
  Kiểm tra cả việc không quét nhầm mũi tên/hình lăn qua đoạn teleport,
  và đầu ra nằm trong nước vẫn chìm, hồi bóng, tính phạt đúng một lần.
- `portal_effects_smoke.gd`: hiệu ứng lóe ở cả nguồn/đích cho hai chiều cam–xanh,
  ảnh dư ở nguồn tự dọn, Sprite bóng hiện dần rồi khôi phục đúng scale/màu/vị trí gốc.
  Kiểm tra cả baseline tùy chỉnh, parent xoay/scale, tắt từng lớp hiệu ứng vẫn giữ vật lý,
  các chấm lăn không bị scale tween làm quay sai, và nước/lỗ tiếp quản mà tween cổng không giành lại.
  Xóa sân giữa hiệu ứng hoặc xóa cổng đích khi yêu cầu còn chờ không để ảnh dư mồ côi/burst giả.

Mỗi script in kết quả PASS/FAIL và thoát với mã khác 0 nếu có lỗi.

## Bộ mười sân mới

```powershell
godot --headless --path . --script res://Tests/courses_smoke.gd
```

`courses_smoke.gd` đọc trực tiếp `Maps/Courses/Map01.tscn` tới `Map10.tscn`,
kiểm tra tường kín và có va chạm, điểm đặt bóng/lỗ không bị vật cản đè,
tuyến tham khảo tránh nước/tường và khả năng nối đường giữa điểm đầu với lỗ.
Màn 9 phải cần cổng mới nối được hai đảo; các cổng phải nối Destination hai chiều.
Kiểm tra thực tế gồm cú đánh một gậy ở màn 1, báo hoàn thành mà không tự chuyển màn,
dịch chuyển qua cổng ở màn 9 không làm bóng rơi nước hoặc tính thêm gậy,
cửa vàng chặn đúng khe và EndPoint của vật cản màn 7 vẫn chuyển động sau khi lưu scene.
Script chỉ chạy các scene trong bộ nhớ, không dựng lại hoặc ghi đè map.
