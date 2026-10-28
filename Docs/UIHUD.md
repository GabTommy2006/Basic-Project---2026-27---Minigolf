# HUD và giao diện Summer Minigolf

Nhấn **F5** để mở game từ `UI/Main.tscn`. Giao diện dùng tiếng Anh và đúng atlas **SummerUI v2 khung sắt** đã duyệt. Không thêm hình từ bên ngoài; ảnh Aseprite gốc được giữ nguyên.

## Luồng chơi

- Menu: Play/Continue, New Game, Select Course, Settings, How to Play, Quit.
- Chọn 10 màn: hiện khóa, sao, kỷ lục và mục tiêu 3 sao. Hoàn thành màn trước để mở màn tiếp theo.
- HUD: số màn, số gậy, mục tiêu sao, lực kéo, trạng thái bóng, restart và pause.
- Pause: Resume, Restart, Settings, Select Course. Esc bật/tắt pause; mất focus sẽ tự pause.
- Kết quả: sao, số gậy, kỷ lục, Next Course, Play Again, chọn màn hoặc về menu. Màn 10 có thông báo hoàn thành game.
- Settings: âm lượng Music/SFX, fullscreen. Music điều khiển nhạc nền lặp; Sound điều khiển tiếng gameplay và giao diện. Nhạc nhỏ lại khi pause/kết quả và không khởi động lại khi chuyển màn.

HUD bám hai mép trên/dưới; vùng chơi phủ toàn bộ chiều ngang cửa sổ giữa hai dải HUD, không bị bó vào khung 16:9 nhỏ ở giữa. Trong game đầy đủ, cả 10 màn dùng camera tự fit trọn khu vực sân theo kích thước vùng chơi, giữ đúng tỷ lệ hình và không cắt mất mép sân. Camera bám bóng mượt trong phần khung hình còn dư, giữ toàn sân và lỗ trong hình, zoom không đổi khi bóng lăn. Màu nền ngoài TileMap dùng lại màu nền đậm sẵn có của map, bỏ phần nền xám mặc định. Map vẫn giữ camera đã vẽ trong scene khi chạy F6.

Power hiển thị màu vàng theo khoảng kéo khi đang ngắm, trở về rỗng sau khi thả. Vỏ power_frame có lòng màu đục nên chỉ vẽ dưới power_fill; không vẽ lại vỏ phía trên vì sẽ che hết thanh vàng. Cả hai dùng nguyên atlas đã duyệt và lề giãn 2 px.

Khi chuyển trang hoặc đóng popup từ nút bấm, UI ẩn node cũ rồi queue_free ở cuối frame để không xóa nút ngay giữa tín hiệu pressed. Nếu thoát game bị lỗi lưu, Cancel/Esc khôi phục bảng kết quả đang xem; không đưa người chơi trở lại quả bóng đã vào lỗ hoặc phát thưởng hoàn thành lần nữa. Bảng kết quả trễ cũng không thay mất xác nhận thoát.

## Luật sao đã chốt cho bản khởi đầu

Mục tiêu 3 sao của màn 1–10: **2, 3, 3, 4, 5, 4, 5, 5, 6, 7 gậy**.

2 sao: được thêm 2 gậy so với mục tiêu 3 sao. Hoàn thành với nhiều gậy hơn vẫn nhận 1 sao. Số gậy gồm gậy phạt nước. Chỉnh từng màn trong `Game/courses.json` khi cân bằng sau playtest.

Tiến độ lưu trong `user://summer_golf.cfg`: màn đã mở, màn gần nhất, số gậy tốt nhất, sao cao nhất và cài đặt. Có `.bak` dự phòng, kiểm tra checksum và phục hồi bản ghi dở. Chơi lại kém hơn không làm mất kỷ lục/sao. New Game có xác nhận, xóa tiến độ và giữ cài đặt. Xem `Docs/PlayerData.md` để biết đường dẫn Windows và cách khôi phục.

## Tài nguyên

`Assets/UI/SummerUI-v2/` chứa bản sao atlas và các AtlasTexture/StyleBoxTexture cần dùng từ `ArtDrafts/SummerUI-v2/`. Font dùng `Assets/Minecraft.otf` đã có sẵn. Chữ nằm trong Control/Label của Godot; background menu là ảnh tĩnh.

Các map giữ nguyên tile, vị trí bóng/lỗ và vật cản. Map 1 được sửa đường dẫn TileSet đang trỏ nhầm vào bản sao lưu trong `output/`, chuyển về `Assets/TileSetSummer.tres` để chạy ngoài máy làm việc được.

## Kiểm tra

`Tests/game_ui_smoke.gd` kiểm tra menu, khóa màn, kéo-thả từ viewport chính đến bóng, pause/resume, settings, restart, kết quả, mở màn tiếp, lưu/tải tiến độ, biên sao từng màn và nạp đủ 10 scene. Test ghi vào `tmp/ui-check/`, không ghi đè tiến độ người chơi.

`Tests/course_camera_smoke.gd` tiếp tục kiểm tra camera map 4–10. Ảnh render của các trang được giữ trong `Docs/Previews/`.

`Tests/gameplay_framing_smoke.gd` kiểm tra khung HUD thực tế của cả 10 map ở năm kích thước cửa sổ, gồm fullscreen 1080p, màn rộng, 4:3 và dọc. Kiểm tra sân không bị cắt trong lúc camera bám bóng, viewport phủ ngang, HUD không che sân và zoom giữ nguyên khi di chuyển.

`Tests/power_render_smoke.gd` chạy bằng scene QA ngoài bản sao EXE Release: kéo chuột thật ở mức 0/25/50/100%, đo vùng màu vàng trong ảnh render để xác nhận thanh lực hiện và dài dần, rồi thả để xác nhận cú đánh và thanh trở về 0. Không dùng hồ sơ người chơi thật.
