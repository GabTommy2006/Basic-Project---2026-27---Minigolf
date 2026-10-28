# Checklist vẽ UI minigolf trong Aseprite

Checklist theo phương án background menu tĩnh hoàn toàn, không có hoạt ảnh trang trí. Dùng cho menu chính, chọn 10 màn, HUD, tạm dừng, kết quả, cài đặt và cách chơi. Đây là thông số thiết kế để bắt đầu vẽ, chưa phải các asset đã có trong project.

Checklist có **20 mục chính và 4 mục tĩnh tùy chọn**. Mỗi bộ icon được tính là một mục; đây không phải số lượng PNG hay số hình khi tính đủ trạng thái. Khung HUD có thể dùng lại panel để giảm một mục cần vẽ riêng.

Mã hex cho từng món và các trạng thái: xem [Gợi ý màu UI trong Aseprite](MauUIAseprite.md). Tất cả màu gợi ý đều lấy từ SummerTile.

**Bộ hình đã vẽ theo yêu cầu:** [SummerUI v1](../ArtDrafts/SummerUI-v1/README.md), gồm file Aseprite tổng, 24 file nguồn theo từng nhóm và 55 PNG trạng thái. Các ô bên dưới vẫn để trống để bạn dùng nếu muốn tự vẽ/chỉnh lại. Bộ này chưa được tích hợp vào game.

**Bản mới nhất:** [SummerUI v2 — khung sắt, lưới 16 px](../ArtDrafts/SummerUI-v2/README.md). Bản v2 thay kích thước cũ trong checklist bằng canvas bội số 16, viền ngoài 1 px + bevel 1 px, có sẵn AtlasTexture/StyleBoxTexture và TileSet 16 px đã kiểm tra trong Godot. Khi dùng bộ mới, theo kích thước và lề trong README/JSON v2.

## Quy chuẩn

- Mọi kích thước dưới đây là pixel gốc, theo bản phác bố cục 320 × 180 px. Khi hiển thị ở 1280 × 720, phóng nguyên 4 lần.
- Project hiện dùng viewport 1280 × 720; quy chuẩn trên không tự thay đổi cấu hình Godot. Cần bố trí hoặc scale UI tương ứng khi tích hợp.
- Nền trong suốt cho mọi asset trừ background. Viền chính 1 px, ánh sáng từ trên trái, cùng một bảng màu.
- Phong cách: gỗ nâu đỏ, mặt bảng kem, điểm nhấn vàng, đồng bộ tileset sân.
- Các trạng thái của cùng một asset phải có cùng kích thước canvas và cùng vị trí neo. Hiệu ứng nhấn dịch mặt nút 1 px trong canvas, không đổi kích thước ảnh.
- Hover và focus bàn phím dùng chung một hình. Normal/hover/pressed/disabled là các hình tĩnh được chọn theo thao tác, không phải hoạt ảnh chạy liên tục. Giữ những trạng thái này để người chơi nhận biết nút có phản hồi.
- Chữ, số màn, số gậy, kỷ lục, phần trăm âm lượng và thông báo dùng Label/font trong Godot. Chọn font có đủ dấu tiếng Việt.
- Chỉ tích hợp tài nguyên do bạn vẽ hoặc cung cấp. Nếu thiếu hình/trạng thái, báo bạn bổ sung; không tự tạo, lấy asset khác hoặc thêm hình tạm khi chưa được bạn đồng ý.

## A. Bộ dùng chung — làm trước

- [ ] `button_primary.aseprite` — **88 × 18 px mỗi trạng thái**. Nút vàng cho Chơi, Vào sân, Tiếp tục, Màn tiếp. **4 trạng thái:** normal, hover/focus, pressed, disabled.
- [ ] `button_secondary.aseprite` — **88 × 18 px mỗi trạng thái**. Nút kem/gỗ cho Chọn màn, Cài đặt, Cách chơi, Chơi lại, Về menu, Đóng, Thoát nếu cần. **4 trạng thái:** normal, hover/focus, pressed, disabled. Có thể tạo bằng đổi màu từ nút chính.
- [ ] `button_icon.aseprite` — **20 × 20 px mỗi trạng thái**. Nền chung cho nút vuông. **4 trạng thái:** normal, hover/focus, pressed, disabled. Glyph đặt riêng phía trên.
- [ ] `panel.aseprite` — **32 × 32 px**. Khung gỗ, mặt kem, **1 trạng thái**. Chừa viền 4 px mỗi cạnh, giữa ít họa tiết để dùng NinePatchRect. Đây là mẫu kéo giãn, không phải kích thước cuối.
- [ ] `icons.aseprite` — mỗi glyph nằm trong **16 × 16 px**, vùng hình khoảng 12 × 12 px. Vẽ pause, back, restart, home, settings, close, next, help. Mỗi glyph **1 hình**; trạng thái tương tác do nền nút thể hiện.
- [ ] `audio_icons.aseprite` — **16 × 16 px** mỗi hình. Music on/off và sound on/off: **4 hình**. Có thể dùng trong cài đặt; nút nền vẫn dùng chung.

Kích thước hiển thị dự kiến của panel: tạm dừng **112 × 112 px**, kết quả **160 × 136 px**, chọn màn **240 × 136 px**, cài đặt/cách chơi **224 × 136 px**. Không cần vẽ riêng từng panel nếu khung NinePatch dùng được.

## B. Menu chính và background tĩnh

- [ ] `logo.aseprite` — **112 × 32 px**, **1 hình tĩnh**. Chữ cách điệu kết hợp bóng/cờ. Logo có thể chứa chữ vì đây là hình nhận diện; các nhãn nút vẫn tách riêng.
- [ ] `menu_background.aseprite` — **320 × 180 px**, **1 hình tĩnh**, xuất một PNG hoàn chỉnh. Vẽ sân cỏ, hố golf, cờ, cát, nước và các chi tiết trang trí trực tiếp trong cùng bức nền. Giữ vùng giữa ít chi tiết cho logo và các nút; không vẽ chữ menu hay nút dính vào nền.

Không cần file cờ bay, gợn nước hoặc các sprite trang trí riêng. Cờ, nước, cỏ, hoa, đá nếu có đều đứng yên trong background. Logo là ảnh tĩnh riêng để dễ bố trí. Menu dùng lại hai mẫu nút; không vẽ một bộ nút riêng cho từng dòng chữ.

## C. Chọn level và sao

- [ ] `level_card.aseprite` — **40 × 40 px mỗi trạng thái**. **4 trạng thái:** normal, hover/focus, pressed, locked. Khung đang chọn có thể dùng lại hover/focus để giữ lựa chọn. Chừa phần trên cho số màn, phần dưới cho ba sao.
- [ ] `lock.aseprite` — **12 × 12 px**, **1 hình**; ghép lên ô bị khóa.
- [ ] `star_small.aseprite` — **8 × 8 px mỗi trạng thái**. **2 hình:** empty, full. Dùng trên ô level. Ba sao cộng khoảng cách 2 px chiếm 28 px, vừa trong ô 40 px.
- [ ] `star_large.aseprite` — **16 × 16 px mỗi trạng thái**. **2 hình:** empty, full. Dùng ở bảng kết quả. Vẽ chỉnh riêng cho rõ nét, tránh thu nhỏ tự động từ sao lớn để làm sao nhỏ.
- [ ] `check.aseprite`, tùy chọn — **8 × 8 px**, **1 hình** nếu muốn dấu hoàn thành ngoài hàng sao.

Bố cục: 5 cột × 2 hàng; khoảng cách ngang 4 px, dọc 8 px. Cả lưới rộng 216 px, cao 88 px, vừa panel 240 × 136 px. Vùng thông tin kỷ lục và nút Vào sân có thể đặt ở màn xem chi tiết sau khi bấm ô; tránh nhồi cả lưới, thông tin dài và nút vào một panel chật.

Ô hoàn thành dùng cùng nền ô thường, ghép sao đầy/rỗng theo thành tích. Sao hiển thị tĩnh, không cần hiệu ứng lấp lánh hoặc hoạt ảnh nhận sao. Không cần vẽ 10 ô khác nhau; số màn là Label.

Luật sao đề xuất, xử lý bằng code: đặt mốc T riêng cho mỗi màn. Số gậy ≤ T: 3 sao; T+1 đến T+2: 2 sao; từ T+3 trở lên: 1 sao khi hoàn thành. Tính cả gậy phạt; lưu thành tích sao tốt nhất. Màn dễ có thể bắt đầu T=3, màn khó T=4–5 rồi điều chỉnh sau khi chơi thử. Text mục tiêu hiển thị rõ, ví dụ “3 sao: ≤3 gậy”.

## D. HUD trong game

- [ ] `hud_panel.aseprite` — **80 × 24 px**, **1 hình**. Vùng ghi màn và số gậy, góc trên trái. Có thể dùng panel NinePatch thay vì vẽ thêm nếu cùng phong cách.
- [ ] `power_frame.aseprite` — **80 × 10 px**, **1 hình**. Vỏ và nền thanh lực, viền 2 px.
- [ ] `power_fill.aseprite` — **76 × 6 px**, **1 hình**. Ruột vàng tách riêng, nằm bên trong khung. Godot cắt vùng hiển thị từ 0–100%, không kéo méo các hạt trang trí. Không cần vẽ 100 mức lực.
- [ ] `aim_head.aseprite`, tùy chọn — **8 × 8 px**, **1 hình** đầu mũi tên. Có thể thay bằng hình vẽ bằng code hiện có; xoay theo hướng đánh trong Godot, không cần vẽ đủ mọi góc.
- [ ] `ball_ready_ring.aseprite`, tùy chọn — **16 × 16 px**, **1 hình tĩnh** viền nhận biết bóng có thể đánh. Đặt dưới bóng, chỉ hiện khi bóng sẵn sàng; không nhấp nháy.

Nút pause dùng button_icon + glyph pause. Thanh lực chỉ hiện khi kéo; gợi ý thao tác và “+1 gậy” khi xuống nước là Label. Đường ngắm là hình vẽ bằng code, không cần xuất một ảnh dài. Không thêm thanh máu/mana vào bộ UI này.

## E. Tạm dừng, kết quả, cài đặt và cách chơi

- [ ] `slider_track.aseprite` — **80 × 6 px**, **1 hình** cho thanh âm lượng.
- [ ] `slider_fill.aseprite` — **76 × 2 px**, **1 hình**, nằm trong viền 2 px của track; cắt chiều dài bằng code.
- [ ] `slider_handle.aseprite` — **8 × 12 px mỗi trạng thái**, **3 trạng thái:** normal, hover/focus, dragging. Giữ cùng vị trí neo giữa các trạng thái.
- [ ] `checkbox.aseprite` — **12 × 12 px mỗi trạng thái**, **4 hình:** unchecked, checked, unchecked-focus, checked-focus. Dùng cho toàn màn hình nếu có tùy chọn này.
- [ ] `mouse_drag_hint.aseprite` — **48 × 24 px mỗi hình**, **3 hình tĩnh:** nhấn giữ, kéo ngược hướng, thả. Dùng cho màn Cách chơi, đặt cạnh nhau hoặc xếp dọc với mô tả bằng Label; không cần chạy thành hoạt ảnh.
- [ ] `result_banner.aseprite`, tùy chọn — **112 × 24 px**, **1 hình** băng rôn trống. Chữ “Hoàn thành” đặt bằng Godot; bỏ nếu tiêu đề trên panel đã đủ rõ.

Tạm dừng dùng panel + nút chung. Kết quả dùng panel + sao lớn + nút chung. Cài đặt dùng panel + slider + checkbox + icon âm thanh. Cách chơi dùng panel + ba hình hướng dẫn. Nền tối phía sau popup dùng ColorRect trong Godot, không cần vẽ PNG.

## Thứ tự làm

1. Hai mẫu nút, nền nút icon, panel, các icon thao tác.
2. Sao nhỏ/lớn, ô level và ổ khóa.
3. HUD, thanh lực.
4. Logo và một background menu tĩnh hoàn chỉnh.
5. Slider, checkbox, hình hướng dẫn thao tác.
6. Các món tĩnh tùy chọn nếu muốn: dấu hoàn thành, đầu mũi tên, vòng báo bóng sẵn sàng, băng rôn kết quả.

## Lưu và xuất

- Giữ file `.aseprite` gốc. Mỗi món có layer nền/viền/highlight tách rõ nếu cần chỉnh màu.
- Đặt tên trạng thái: `normal`, `hover`, `pressed`, `disabled`; `empty`, `full`; `on`, `off`.
- Xuất PNG ở kích thước gốc 1×; không phóng 4× ngay trong file xuất. Background là ảnh nền hoàn chỉnh; các asset còn lại có nền trong suốt.
- Với asset nhiều trạng thái: xuất từng PNG đặt tên theo trạng thái hoặc một sprite sheet có các ô cùng kích thước, ghi rõ thứ tự. Bộ này không cần FPS, thời lượng frame hay file hoạt ảnh.
- Các frame cùng asset có cùng canvas, không trim riêng từng frame làm mất vị trí neo.
- Dùng nearest filtering, scale nguyên và căn vị trí theo pixel khi tích hợp.
- Kiểm tra chữ có dấu tiếng Việt và bố cục thật trước khi thêm nhiều texture trang trí; nền nút 88 × 18 px cần nới nếu nhãn thực tế không vừa.
