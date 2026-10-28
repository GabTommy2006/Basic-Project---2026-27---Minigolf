# Gợi ý mã màu UI minigolf trong Aseprite

Toàn bộ mã dưới đây đều có trong 43 màu thực sự dùng ở SummerTile. Đây là gợi ý phối màu để bạn tự vẽ, không tạo thêm asset hoặc thay màu trong game.

Palette đầy đủ có sẵn tại `ArtDrafts/Menu/summertile-used-colors.gpl`. Có thể nạp bằng Load Palette trong Aseprite.

## Bộ màu dùng chung

- Viền gỗ tối: `#54311F`.
- Bóng gỗ: `#7A4C32`.
- Gỗ chính: `#9C6546`.
- Điểm sáng gỗ: `#C7A663`.
- Mặt bảng kem: `#FCE9BD`.
- Vàng dịu: `#F0D69F`.
- Vàng tối: `#E5C687`.
- Vàng nhấn/sao: `#FCE128`.
- Chữ trên nền kem/vàng: `#54311F`; chữ/số cần đậm hơn: `#151D2E`.
- Chữ trên mặt gỗ tối: `#FCE9BD`.
- Xám tối/vừa/sáng: `#484C57`, `#6C717D`, `#A1A1AA`.
- Trắng ngà: `#E4E4E7`.

Với món nhỏ, ưu tiên 3 màu: viền, mặt chính, điểm sáng. Không cần nhồi đủ màu của bảng vào một món. Viền 1 px; nguồn sáng ở trên trái, bóng ở dưới phải. Chữ là Label trong Godot, trừ chữ trong logo.

## 1. Nút chính — button_primary, 88 × 18 px

- Viền ngoài `#54311F`, thành/bóng dưới `#7A4C32`, điểm sáng trên trái `#FCE9BD`.
- Normal: mặt `#F0D69F`.
- Hover/focus: mặt `#FCE9BD`, điểm nhấn viền trong `#FCE128`.
- Pressed: mặt `#E5C687`, hạ mặt nút 1 px, thu bớt điểm sáng.
- Disabled: mặt `#A1A1AA`, viền `#484C57`, thành dưới `#6C717D`, không dùng điểm nhấn vàng.
- Chữ khi ghép trong Godot: `#54311F`; disabled dùng `#484C57`.

## 2. Nút phụ — button_secondary, 88 × 18 px

- Dùng cùng màu viền/thành với nút chính.
- Normal: mặt `#FCE9BD`.
- Hover/focus: mặt `#E4E4E7`, điểm nhấn viền trong `#F0D69F`.
- Pressed: mặt `#E5C687`, hạ 1 px.
- Disabled: cùng bộ xám của nút chính.
- Nút phụ không dùng vàng chói làm mặt toàn bộ, để nút Chơi vẫn nổi bật nhất.

## 3. Nền nút icon — button_icon, 20 × 20 px

- Dùng nguyên bộ màu và trạng thái của nút phụ.
- Để trống tâm cho glyph 12–16 px, không vẽ chữ/icon dính vào nền nút nếu muốn tái sử dụng.

## 4. Khung bảng và HUD — panel, hud_panel

- Mặt bảng `#FCE9BD`.
- Viền ngoài `#54311F`, khung gỗ `#9C6546`.
- Bóng dưới phải `#7A4C32`, sáng trên trái `#C7A663`.
- Chữ `#54311F`, số gậy hoặc thông tin cần nhấn `#151D2E`.
- Dùng cùng bộ này cho tạm dừng, kết quả, cài đặt và cách chơi. Không cần mỗi popup một màu khác.

## 5. Bộ icon thao tác — icons, 16 × 16 px

- Pause, back, restart, home, settings, next, help: nét chính `#54311F`.
- Nếu cần khối/shading: màu phụ `#9C6546`, điểm sáng `#C7A663`.
- Close/X có thể giữ màu nâu để đồng nhất; nếu cần nhấn hành động đóng thì dùng `#B91C1C`, bóng `#7F1D1D`.
- Khi disabled, dùng `#6C717D`.
- Icon đặt trên nền kem. Nếu đặt trực tiếp trên nền gỗ tối, dùng nét sáng `#FCE9BD` thay cho nét nâu.

## 6. Icon âm thanh — audio_icons, 16 × 16 px

- Music on/sound on: `#54311F`, có thể thêm sáng `#9C6546`.
- Music off/sound off: giữ nguyên hình nhận biết, thêm nét gạch chéo `#B91C1C`, bóng gạch `#7F1D1D`.
- Không chỉ đổi màu để thể hiện tắt; cần có dấu gạch để dễ phân biệt.

## 7. Logo — logo, 112 × 32 px

- Chữ chính `#F0D69F`, sáng `#FCE9BD`, bóng `#C7A663`.
- Viền ngoài `#54311F`, bóng đổ sát chữ `#7A4C32`.
- Bóng golf `#E4E4E7`, bóng xám `#A1A1AA`.
- Cờ `#B91C1C`, bóng cờ `#7F1D1D`.
- Nếu có cỏ đi kèm: `#67C794`, `#48A874`, `#2D7D51`.

## 8. Background tĩnh — menu_background, 320 × 180 px

- Cỏ: nền `#67C794`, viền/bóng `#48A874`, chỗ tối `#2D7D51`.
- Gỗ/đất: `#9C6546`, bóng `#7A4C32`, viền `#54311F`.
- Cát: nền `#F0D69F`, bóng `#E5C687`, sáng `#FCE9BD`, mép đậm `#A68545`.
- Nước: nền `#3B95D9`, bóng `#3C8ECD`, sáng `#51A5E6`, mép `#316E8C` hoặc `#468EB3`.
- Cờ: `#B91C1C` và `#7F1D1D`. Cột cờ: `#E4E4E7` và `#A1A1AA`.
- Lỗ golf: `#151D2E`.
- Nếu dùng viền đỏ–trắng: `#B91C1C`, `#7F1D1D`, `#E4E4E7`, `#A1A1AA`.
- Không cần vẽ lại nếu bạn chọn dùng bản v1 đã đổi màu SummerTile.

## 9. Ô level — level_card, 40 × 40 px

- Normal: mặt `#FCE9BD`, khung `#9C6546`, viền `#54311F`.
- Hover/đang chọn: giữ mặt kem, thêm viền trong `#FCE128`; có thể thêm dấu góc nhỏ để trạng thái chọn không chỉ phụ thuộc màu.
- Pressed: mặt `#E5C687`, hạ mặt 1 px.
- Locked: mặt `#A1A1AA`, khung `#6C717D`, viền `#484C57`.
- Số màn trong Godot: `#54311F`; sao và ổ khóa đặt riêng.
- Màn hoàn thành vẫn dùng nền normal, chỉ cập nhật hàng sao.

## 10. Ổ khóa — lock, 12 × 12 px

- Thân khóa `#C7A663`, bóng `#A68545`, viền và lỗ khóa `#54311F`.
- Quai khóa `#A1A1AA`, bóng `#6C717D`, điểm sáng `#E4E4E7`.
- Nếu quá chật, rút còn 3 màu: `#54311F`, `#C7A663`, `#E4E4E7`.

## 11. Sao nhỏ/lớn — star_small, star_large

- Sao đầy: mặt `#FCE128`, viền `#8A7200`, bóng `#D1B008`, sáng `#FCE9BD`.
- Sao rỗng/chưa đạt: mặt `#A1A1AA`, viền `#484C57`, bóng `#6C717D`.
- Sao nhỏ 8 × 8 px: chỉ cần viền + mặt, thêm tối đa 1 pixel sáng nếu đủ chỗ.
- Sao lớn 16 × 16 px: có thể dùng đầy đủ 4 màu của sao đầy.

## 12. Vỏ và ruột thanh lực — power_frame, power_fill

- Vỏ: viền `#54311F`, thành `#9C6546`.
- Rãnh bên trong: `#2A2D36`.
- Ruột: `#FCE128`; nếu có shading, sáng `#FCE9BD`, bóng `#D1B008`.
- Vẽ ruột riêng trên nền trong suốt. Không cần đổi màu theo từng mức lực hoặc vẽ gradient.
- Đây là phần hiển thị tùy nhu cầu; game đã có thao tác kéo và đường ngắm, không cần vẽ lại cơ chế đó.

## 13. Rãnh và phần đầy âm lượng — slider_track, slider_fill

- Rãnh: `#484C57`, mép tối `#2A2D36`.
- Phần đầy: `#F0D69F`; nếu cần sáng hơn dùng `#FCE128`.
- Với ruột cao 2 px, dùng 1 màu là đủ.

## 14. Tay nắm âm lượng — slider_handle

- Viền chung `#54311F`.
- Normal: thân `#9C6546`, điểm sáng `#C7A663`.
- Hover/focus: thân `#C7A663`, điểm sáng `#FCE9BD`.
- Dragging: thân `#7A4C32`, giữ một vạch sáng `#C7A663` để vẫn nhìn rõ tay nắm.

## 15. Checkbox — checkbox, 12 × 12 px

- Nền ô `#FCE9BD`, viền `#54311F`, bóng `#7A4C32`.
- Unchecked: để trống tâm.
- Checked: thêm dấu tích `#2D7D51` trên nền kem.
- Hai trạng thái focus: thêm viền trong `#FCE128`; giữ dấu tích theo checked/unchecked.

## 16. Hình hướng dẫn chuột — mouse_drag_hint (có thể bỏ)

- Vỏ chuột `#E4E4E7`, bóng `#A1A1AA`, viền `#484C57`.
- Nút chuột trái được nhấn: `#B91C1C`.
- Bóng golf `#E4E4E7`, bóng xám `#A1A1AA`.
- Mũi tên kéo `#C7A663`, mũi tên hướng đánh `#B91C1C`. Hai hướng phải đối nhau.
- Chỉ cần nếu muốn hướng dẫn bằng hình; có thể dùng hướng dẫn bằng chữ vì game đã có kéo–thả.

## 17. Bốn món tĩnh tùy chọn

- `check`: nét `#2D7D51`, sáng `#67C794`; dùng trên mặt bảng kem.
- `aim_head`: mặt `#FCE128`, viền `#54311F`; chỉ vẽ thêm nếu muốn thay hình ngắm hiện có.
- `ball_ready_ring`: nét `#FCE9BD`, thêm viền ngoài `#2D7D51` nếu cần nổi trên nền cỏ.
- `result_banner`: mặt `#F0D69F`, sáng `#FCE9BD`, bóng `#C7A663`, viền `#54311F`. Chữ đặt bằng Godot.

## Cách bắt đầu gọn nhất

Vẽ nút và khung bảng bằng bộ nâu + kem trước. Dùng vàng chói `#FCE128` cho sao, lực đánh và dấu chọn; dùng đỏ `#B91C1C` cho cờ hoặc dấu tắt. Không cần dùng các màu tím/cam của portal trong menu nếu không có lý do thiết kế cụ thể.
