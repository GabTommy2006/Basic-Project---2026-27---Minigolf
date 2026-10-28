# Dữ liệu người chơi và New Game

Game tự tạo hồ sơ ở lần chạy đầu, lưu sau khi bắt đầu một màn, hoàn thành màn, đổi cài đặt và trước khi thoát.

## Những gì được giữ sau khi thoát

- Màn đã mở khóa.
- Số gậy tốt nhất của từng màn: chơi lại kém hơn không ghi đè kỷ lục.
- Số sao cao nhất của từng màn: không bị giảm khi chơi lại.
- Màn gần nhất để nút Continue mở lại.
- Âm lượng Music/Sound và chế độ fullscreen.

Continue mở lại từ đầu màn gần nhất, không khôi phục vị trí/vận tốc bóng giữa một cú đánh. Hoàn thành màn đưa Continue tới màn tiếp theo; màn 10 giữ ở màn 10.

## Vị trí file

Đường dẫn trong Godot: `user://summer_golf.cfg`.

Trên Windows của project hiện tại:

```text
%APPDATA%\Godot\app_userdata\Minigolf Basic Project\summer_golf.cfg
```

Không lưu vào `res://`, thư mục project hoặc cạnh file EXE. Dữ liệu vẫn giữ khi đóng game, mở lại hoặc chuyển thư mục project. Đổi tên ứng dụng trong cấu hình Godot có thể đổi thư mục `user://`; cần di chuyển hồ sơ nếu đổi tên khi phát hành.

## Ghi file và khôi phục

Game ghi vào `.tmp`, kiểm tra checksum, rồi mới thay file chính. `.bak` giữ bản dữ liệu đã ghi thành công gần nhất. Khi mở game, hệ thống kiểm tra file chính, dự phòng và bản tạm; chỉ nhận dữ liệu hợp lệ, chọn phiên bản mới nhất. Nếu file chính hỏng mà còn bản dự phòng/tạm hợp lệ, game tự khôi phục và thông báo.

Hồ sơ cũ dạng ConfigFile chưa có metadata được nâng cấp, giữ các kỷ lục hợp lệ và khôi phục sao/mở khóa còn thiếu. Giá trị sai kiểu không làm game lỗi ép kiểu. Hồ sơ của định dạng mới hơn không bị bản game cũ ghi đè.

Nếu không đọc được cả ba file, game giữ nguyên chúng và thông báo; New Game chỉ thay hồ sơ sau xác nhận. Khi không ghi được file, tiến độ vẫn ở bộ nhớ trong phiên chơi, nhưng không hứa đã lưu khi thoát. Menu thoát sẽ hiển thị cảnh báo phù hợp.

## New Game

Chọn **New Game** ở menu rồi xác nhận để bắt đầu lại màn 1. Thao tác xóa màn mở khóa, sao, kỷ lục và cập nhật cả bản dự phòng, đồng thời giữ cài đặt âm thanh/màn hình. Cancel không thay đổi dữ liệu. Nếu thao tác ghi thất bại, dữ liệu trong phiên được trả lại trạng thái trước khi reset.

## Kiểm tra

- `Tests/player_data_smoke.gd`: tạo hồ sơ, đọc lại, giữ kỷ lục, khôi phục file hỏng/ghi dở, nâng cấp hồ sơ cũ, xử lý giá trị sai và New Game.
- `Tests/game_ui_smoke.gd`: nút Continue/New Game/Cancel, khóa màn, kết quả, pause, chuột/bàn phím và khung camera thực tế bên trong HUD.
- `Tests/profile_restart_worker.gd`: nhiều tiến trình Godot độc lập, kiểm tra thắng thật màn 1, thoát từ menu/pause/kết quả, đọc lại và New Game trong thư mục AppData bằng file `qa_profile_*.cfg` riêng. Không dùng file lưu thật của người chơi.

Chạy cả bộ bằng `Tools/run_tests.ps1 -CheckRestart`. Kết quả nằm trong `tmp/test-results/`.
