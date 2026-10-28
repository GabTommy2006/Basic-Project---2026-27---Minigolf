# SummerUI v1

Bộ pixel art được vẽ theo yêu cầu của bạn, dựa trên các mẫu UI đã thống nhất và chỉ dùng màu thực sự có trong SummerTile. Chưa thay tài nguyên hoặc scene đang chạy trong game.

## Nội dung

- **24 nhóm asset**, **55 PNG** ở kích thước gốc 1×; nền trong suốt trừ background.
- `SummerUI-v1.aseprite`: master sheet 512 × 512, 55 layer đặt tên theo nhóm/trạng thái.
- `SummerUI-v1.png`: cùng master sheet, nền trong suốt, khoảng đệm ít nhất 2 px giữa các vùng.
- `SummerUI-v1.json`: tọa độ, kích thước, đường dẫn PNG và gợi ý lề NinePatch cho từng vùng.
- `sources/`: 24 file Aseprite, mỗi nhóm một file. Nhóm nhiều trạng thái dùng các frame được đặt tag; đây là hình chọn theo thao tác, không phải hoạt ảnh tự chạy.
- `png/`: các ảnh riêng đã tách, không trim làm lệch vị trí neo.
- `SummerTile.gpl`: đủ 43 màu đang được dùng trong SummerTile gốc.
- `previews/`: ảnh ghép xem trước menu, chọn màn, HUD, tạm dừng, kết quả, cài đặt và cách chơi. Chữ và số trong các ảnh này chỉ minh họa, không nằm trong PNG nền nút/bảng.
- `validation.txt`: kết quả kiểm tra màu, kích thước trạng thái, đối chiếu file Aseprite với PNG và vùng atlas không chồng lấn.

## Dùng và chỉnh sửa

1. Muốn sửa từng món: mở file tương ứng trong `sources/`. Chọn frame/tag normal, hover, pressed, disabled… nếu có.
2. Muốn xem toàn bộ cùng một tile: mở `SummerUI-v1.aseprite`. Mỗi hình/trạng thái có một layer riêng.
3. Muốn tích hợp: dùng PNG riêng trong `png/`, hoặc lấy vùng atlas theo JSON. Kích thước đều là pixel gốc; dùng nearest filtering và scale nguyên.
4. `panel`/`hud_panel` có lề 4 px. Nút và ô level cũng có lề 4 px; thanh lực và rãnh âm lượng có lề 2 px. Không scale méo góc khi đổi kích thước.
5. Chữ “Chơi”, “Tiếp tục”, số màn, số gậy, kỷ lục… cần hiển thị bằng Label/font trong Godot. Chỉ logo MINIGOLF chứa chữ vẽ sẵn.

## Các nhóm

- Dùng chung: button_primary, button_secondary, button_icon, panel, icons, audio_icons.
- Menu: logo, menu_background.
- Chọn màn: level_card, lock, star_small, star_large.
- HUD: hud_panel, power_frame, power_fill.
- Cài đặt/hướng dẫn: slider_track, slider_fill, slider_handle, checkbox, mouse_drag_hint.
- Bốn món phụ: check, aim_head, ball_ready_ring, result_banner.

Thanh lực, hình hướng dẫn chuột, đầu ngắm và vòng bóng đều có thể bỏ nếu muốn giữ HUD tối giản. Game đã có cơ chế kéo–thả và đường ngắm; bộ hình này không làm lại hoặc thay đổi cơ chế đó.

Background là bản v1 đã đổi sang màu SummerTile mà bạn vừa chọn. File nguồn background giữ 8 layer và chỉ có một frame tĩnh.

## Phạm vi

Bộ asset nằm trong ArtDrafts, được `.gdignore` của thư mục cha loại khỏi import Godot. Các scene, script gameplay và tài nguyên đang dùng vẫn giữ nguyên. Ảnh xem trước là bố cục ghép để duyệt hình, không phải ảnh chụp tính năng UI đã được lập trình.
