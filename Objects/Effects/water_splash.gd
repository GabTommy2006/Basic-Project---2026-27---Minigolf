# Gợn nước và giọt bắn được vẽ bằng code, không cần thêm ảnh hay particle texture.
# Node này chỉ tạo hình ảnh tại điểm rơi, không điều khiển bóng hay cộng gậy phạt.
extends Node2D

## Thời gian tồn tại của hiệu ứng, tính bằng giây; có thể đặt trước khi thêm node vào scene.
## Script bóng có thể đặt thời gian khác mặc định 0.65 này khi tạo hiệu ứng.
@export var duration: float = 0.65

# Thời gian đã chạy từ khi tạo node, tính bằng giây và bắt đầu từ 0.
# Cả gợn nước lẫn giọt bắn đều đọc đồng hồ này để chuyển động đồng bộ.
var _elapsed: float = 0.0

## Được Godot gọi khi node đã vào cây scene; chuẩn bị thời gian và lần vẽ đầu tiên.
func _ready() -> void:
	# maxf chọn số lớn hơn: thời gian thực tế luôn ít nhất 0.05 giây.
	# Điều này tránh chia cho 0 và tránh hiệu ứng có thời gian bằng 0 hoặc số âm.
	duration = maxf(duration, 0.05)
	# Yêu cầu Godot gọi _draw() để hiển thị hình ảnh ban đầu.
	queue_redraw()

## Cập nhật đồng hồ ở mỗi khung hình; delta là số giây kể từ khung hình trước.
func _process(delta: float) -> void:
	# Cộng thời gian trôi qua; minf giữ đồng hồ không vượt quá thời lượng hiệu ứng.
	_elapsed = minf(_elapsed + delta, duration)
	# Các hình vẽ trong _draw() cần được yêu cầu vẽ lại khi thời gian thay đổi.
	queue_redraw()
	# Hiệu ứng tự dọn node khi kết thúc, kể cả khi bóng đã hồi về sân.
	# queue_free() lên lịch xóa an toàn, thay vì xóa node ngay trong lúc đang cập nhật.
	if _elapsed >= duration:
		queue_free()

## Vẽ lại mọi gợn và giọt theo thời gian hiện tại, trong tọa độ local của node hiệu ứng.
func _draw() -> void:
	# Đổi thời gian thành tiến độ: 0 là vừa bắt đầu, 0.5 là nửa chặng, 1 là kết thúc.
	# maxf bảo vệ mẫu số; clampf giới hạn kết quả trong đoạn 0..1.
	var progress := clampf(_elapsed / maxf(duration, 0.05), 0.0, 1.0)
	# Độ rõ giảm từ 1 xuống 0, dùng làm alpha để hình ảnh mờ dần rồi biến mất.
	var fade := 1.0 - progress
	# Tạm đổi hệ tọa độ VẼ: hạ gốc xuống 1 pixel, không xoay và giữ nguyên chiều ngang.
	# Chiều dọc còn 55% làm vòng tròn thành elip, trông như gợn nằm trên mặt nước.
	# Lệnh này chỉ ảnh hưởng các nét vẽ tiếp theo, không di chuyển node hay quả bóng.
	draw_set_transform(Vector2(0.0, 1.0), 0.0, Vector2(1.0, 0.55))
	# Vòng ngoài lấy tâm (0,0); lerpf làm bán kính tăng đều từ 2 đến 10 pixel.
	# Góc 0..TAU là một vòng đầy đủ (TAU = 2 * PI); 32 điểm dùng để xấp xỉ đường tròn.
	# Màu cyan nhạt có alpha tối đa 0.9 rồi giảm theo fade; nét rộng 0.8 pixel.
	# false tắt khử răng cưa để nét hợp với hình ảnh pixel của sân.
	draw_arc(
		Vector2.ZERO, lerpf(2.0, 10.0, progress), 0.0, TAU, 32,
		Color(0.72, 0.96, 1.0, fade * 0.9), 0.8, false
	)
	# Vòng thứ hai chờ đến khi hiệu ứng chạy được 18%, tạo thêm một đợt sóng.
	# Trừ 0.18 để bắt đầu từ 0; chia 0.82 (= 1 - 0.18) để phần còn lại chạy đến 1.
	# clampf giữ tiến độ riêng này trong 0..1, kể cả trong lúc vòng chưa xuất hiện.
	var inner_progress := clampf((progress - 0.18) / 0.82, 0.0, 1.0)
	if progress >= 0.18:
		# Vòng trong tăng bán kính từ 1.5 đến 7 pixel, dùng 28 điểm và nét rộng 0.7.
		# Màu xanh đậm hơn vòng ngoài; alpha từ 0.75 về 0 theo tiến độ riêng của vòng.
		draw_arc(
			Vector2.ZERO, lerpf(1.5, 7.0, inner_progress), 0.0, TAU, 28,
			Color(0.35, 0.8, 1.0, (1.0 - inner_progress) * 0.75), 0.7, false
		)
	# Đưa hệ tọa độ vẽ về mặc định: không dịch, không xoay, tỉ lệ (1,1).
	# Nhờ vậy các giọt bên dưới không bị ép dẹt hay lệch 1 pixel như gợn nước.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Tạo tám giọt; index chạy lần lượt từ 0 đến 7.
	for index in range(8):
		# Chia một vòng TAU thành tám hướng cách đều nhau; float bảo đảm phép chia thực.
		var angle := TAU * float(index) / 8.0
		# Vận tốc ngang cos(angle) * 17 làm giọt văng trái/phải, tối đa 17 pixel/giây.
		# Vận tốc dọc sin(angle) * 7 - 17 nằm trong khoảng -24..-10: tất cả bay lên trước.
		# Trong tọa độ Godot 2D, Y âm là hướng lên và Y dương là hướng xuống.
		var velocity := Vector2(cos(angle) * 17.0, sin(angle) * 7.0 - 17.0)
		# Điểm xuất phát lệch ngang tối đa 1.5 pixel; vận tốc * thời gian cho độ dịch chuyển.
		var droplet := Vector2(cos(angle) * 1.5, 0.0) + velocity * _elapsed
		# Cộng độ rơi tỉ lệ với thời gian bình phương để giọt cong xuống như có trọng lực.
		# 38 là hệ số tạo hình cho đường bay, không phải cấu hình vật lý của quả bóng.
		droplet.y += 38.0 * _elapsed * _elapsed
		# index % 2 kiểm tra chẵn/lẻ: giọt chẵn cạnh 1 pixel, giọt lẻ cạnh 0.75 pixel.
		var size := 1.0 if index % 2 == 0 else 0.75
		# Giọt chẵn màu gần trắng; alpha fade khiến mọi giọt mờ đi theo thời gian.
		var tint := Color(0.88, 0.98, 1.0, fade)
		if index % 2 != 0:
			# Giọt lẻ dùng màu xanh sáng để tạo xen kẽ màu thay vì tám giọt giống hệt nhau.
			tint = Color(0.45, 0.86, 1.0, fade)
		# round() làm tròn tâm giọt về tọa độ pixel; trừ nửa cạnh để hình vuông cân quanh tâm.
		# Rect2 nhận góc trên trái và kích thước; Vector2.ONE * size tạo hình vuông cùng cạnh.
		draw_rect(Rect2(droplet.round() - Vector2.ONE * size * 0.5, Vector2.ONE * size), tint)
