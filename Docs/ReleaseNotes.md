# Minigolf 1.0.0 — Windows, chốt ngày 28/10/2026

Đã chốt phát hành 1.0 theo xác nhận của người dùng. Tên ứng dụng và thư mục lưu giữ nguyên; phiên bản project/Product Version là 1.0.0, Windows File Version là 1.0.0.0.

Đã sửa lỗi crash khi nhấn nút chuyển trang hoặc đóng popup: node giao diện trước đây bị xóa ngay trong lúc phát tín hiệu pressed. Trang, popup và sân cũ giờ được ẩn/ngừng xử lý rồi giải phóng ở cuối frame.

Đã sửa luồng hủy thoát khi file lưu không ghi được. Nếu đang ở kết quả, Cancel/Esc trả lại kết quả và giữ các nút chuyển màn; không quay lại sân với quả bóng đã vào lỗ. Khôi phục kết quả không phát lại thưởng. Khi đang chờ hiện kết quả, bảng kết quả không thay mất xác nhận thoát.

Giữ các bản vá trước: vùng chơi phủ ngang, camera giữ trọn sân và bám bóng trong khoảng dư, Power vàng theo lực kéo, tự lưu tiến độ/sao/kỷ lục, dự phòng dữ liệu và New Game có xác nhận.

## Xác minh

- Bộ hồi quy gồm 13 nhóm và 8 bước thoát/mở lại qua tiến trình độc lập.
- 10 map ở 5 kích thước cửa sổ; 80 phiên vật lý với tối đa 4 lượt đánh liên tiếp mỗi phiên. Lượt kiểm tra mở rộng đạt 301 cú đánh, không phát hiện bóng thoát biên hoặc vị trí/vận tốc không hợp lệ.
- Kiểm tra thêm 64 hướng ra của portal trong các map hiện tại; không chồng vào vật cản.
- EXE Release chạy bằng D3D12 mặc định: mở đủ 10 màn ở fullscreen, thắng thật màn 1, lưu/mở lại, New Game/Cancel, các nút GUI và trường hợp lỗi ghi dữ liệu.
- Thanh Power được đo từ ảnh render thực tế ở 0/25/50/100%; thanh vàng tăng đúng và trở về 0 sau khi thả.

Kiểm tra dùng hồ sơ QA riêng. Bản phát hành không chứa dữ liệu người chơi, scene QA, override.cfg hoặc tài nguyên thử nghiệm. Hình ảnh người dùng và bố cục map được giữ nguyên trong lượt rà soát này.

File chạy: `output/Windows/SummerMinigolf.exe`. Gói gửi đi: `output/SummerMinigolf-Windows-x64.zip`.
