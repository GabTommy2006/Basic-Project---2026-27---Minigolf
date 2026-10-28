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

## Giao diện và camera hiện tại

```powershell
godot --headless --path . --script res://Tests/game_ui_smoke.gd
godot --headless --path . --script res://Tests/game_audio_smoke.gd
godot --headless --path . --script res://Tests/course_camera_smoke.gd
```

`game_ui_smoke.gd` kiểm tra luồng menu/chọn màn, kéo-thả qua viewport chính, HUD, pause/resume, settings, restart, kết quả, mở khóa và lưu/tải tiến độ. File lưu test nằm ở `tmp/ui-check/`, không ảnh hưởng dữ liệu người chơi.

`course_camera_smoke.gd` kiểm tra camera các map 4–10 ở ba kích thước cửa sổ và 30/60/144 FPS.

`game_audio_smoke.gd` kiểm tra tài nguyên âm thanh, nhạc lặp, cue từ cú đánh thật, chống phát dồn, pause/resume, kết quả/sao, âm lượng và việc nhạc không khởi động lại khi chuyển màn. File lưu test nằm trong `tmp/ui-check/`, không ảnh hưởng dữ liệu người chơi.

## Toàn bộ game và dữ liệu người chơi

Chạy `Tools/run_tests.ps1` để kiểm tra 13 nhóm hiện tại, gồm cơ chế vật lý, UI, audio, camera, dữ liệu và 80 phiên thử trên 10 map, mỗi phiên tối đa 4 cú đánh liên tiếp ở các góc khác nhau. Thêm `-CheckRestart` để kiểm tra thêm 8 bước bằng nhiều tiến trình game độc lập với hồ sơ QA trong AppData:

```powershell
./Tools/run_tests.ps1 -CheckRestart
```

Nếu Godot nằm ở vị trí khác, truyền `-GodotPath 'đường dẫn Godot.exe'`. Log ở `tmp/test-results/`. Runner kiểm tra cả mã thoát, marker kết quả và lỗi GDScript, tránh coi trường hợp assert/parse error kết thúc do timeout là thành công.

`player_data_smoke.gd` kiểm tra save/recovery/migration/New Game. `surfaces_smoke.gd` kiểm tra cỏ/cát/nước, bốn hướng mũi tên, toàn bộ bóng vào tile mới tăng tốc một lần, và ngưỡng lỗ nhận bóng 160 px/s.

`gameplay_framing_smoke.gd` kiểm tra cả 10 map trong viewport của HUD ở năm kích thước cửa sổ: phủ ngang, HUD bám mép không che sân, thấy trọn sân và lỗ, camera bám mượt trong khoảng dư và không zoom nhấp nhô.

`ui_edge_cases_smoke.gd` nhấn/thả chuột qua GUI thật để kiểm tra menu, pause, Settings, restart, kết quả và màn cuối. Tạo lỗi ghi có kiểm soát để kiểm tra hủy thoát vẫn quay lại kết quả, không lặp thưởng và không bị bảng kết quả trễ thay mất xác nhận thoát.

`shot_stress.gd` chạy 80 sân vật lý độc lập, đánh tiếp khi bóng đã dừng, bỏ qua bóng đã vào lỗ/chìm nước. Mỗi lượt chạy báo số cú đánh thực tế; kiểm tra vị trí/vận tốc hữu hạn và bóng không lọt ra ngoài biên map. Runner giới hạn FPS để bộ đếm khung hình không dừng bài thử trước khi đủ nhịp vật lý.

## Mười sân hiện tại

```powershell
godot --headless --path . --script res://Tests/courses_smoke.gd
```

`courses_smoke.gd` đọc trực tiếp `Maps/Courses/Map1.tscn` tới `Map10.tscn` theo thứ tự hiện tại. Kiểm tra điểm xuất phát/lỗ, va chạm vật cản, nối cổng hai chiều, đường nối ô sân gồm portal và cú đánh một gậy thật ở màn 1. Hole.png đã có ô cỏ riêng nên không bắt buộc TileMap phải có tile phía dưới lỗ. Script không dùng bố cục/metadata từ bản dựng cũ và không ghi đè map.
