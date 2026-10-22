# Vẽ vài chấm xám trên bóng 6x6 để người chơi nhìn thấy chuyển động lăn.
# Node này nằm dưới Sprite2D: cùng thu nhỏ, hạ xuống và mờ đi khi bóng vào nước/lỗ.
extends Node2D

## Bật/tắt các chấm thể hiện bóng lăn; chỉ ảnh hưởng hình vẽ.
@export var show_roll_marks: bool = true:
	set(value):
		show_roll_marks = value
		# Vẽ lại ngay cả khi đang đứng yên hoặc vừa tắt, để xóa các chấm đã vẽ trước đó.
		queue_redraw()
## Bán kính lăn, mặc định 3 pixel giống hình va chạm của bóng.
## Đi một quãng bằng chu vi 2*PI*bán kính thì mặt bóng quay đủ một vòng.
## Tăng bán kính để hình lăn chậm hơn; tốc độ di chuyển của bóng vẫn giữ nguyên.
@export_range(0.5, 10.0, 0.5) var rolling_radius: float = 3.0
## Màu chấm xám; alpha nhỏ giúp nhìn nhẹ trên nền trắng, không lấn át viền đen.
@export var mark_color: Color = Color(0.55, 0.60, 0.68, 0.8):
	set(value):
		mark_color = value
		# Đổi màu trong Inspector lúc game chạy cũng được cập nhật ngay trên bóng.
		queue_redraw()

# Sáu điểm đối nhau trên mặt cầu đơn vị; chỉ những điểm ở nửa trước mới được vẽ.
# Khi mặt cầu lăn, chấm cũ đi ra mép rồi khuất, chấm phía sau đi lên thay thế.
const SURFACE_POINTS := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP,
	Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
# Chỉ vẽ trong phần trắng của sprite; không dùng bán kính vật lý 3 để vẽ đè lên viền.
const MARK_SURFACE_RADIUS := 1.4
# Xoay nhẹ ban đầu để các chấm không nằm hết trên cùng một hàng/cột.
var _orientation := Quaternion.from_euler(Vector3(0.4, 0.2, 0.3))
# Lưu vị trí THÂN bóng, không lấy vị trí node này vì Sprite2D có thể đang chạy tween.
var _previous_position := Vector2.ZERO
# Mẫu đầu tiên chỉ làm mốc, không coi khoảng cách từ (0,0) tới bóng là chuyển động.
var _has_previous_position := false

## Bắt đầu lấy mẫu ở vị trí mới, dùng khi tạo bóng hoặc hồi từ nước.
func reset_motion(world_position: Vector2) -> void:
	_previous_position = world_position
	_has_previous_position = true

## Quay mặt bóng theo quãng đường THỰC SỰ đã lăn trong bước vật lý vừa qua.
func advance_to(world_position: Vector2, is_rolling: bool = true) -> void:
	if not _has_previous_position:
		reset_motion(world_position)
		return
	var world_movement := world_position - _previous_position
	# Luôn cập nhật mốc, kể cả khi đang chìm/đã vào lỗ, để không cộng dồn đoạn tween.
	_previous_position = world_position
	if not is_rolling or not show_roll_marks or world_movement.is_zero_approx():
		return
	# Đổi về local để bán kính và quãng đường dùng cùng đơn vị, kể cả khi bóng được scale.
	var movement := global_transform.affine_inverse().basis_xform(world_movement)
	# Trục quay vuông góc hướng lăn: sang phải quay quanh Y, đi xuống quay quanh -X.
	# Quaternion lưu hướng mặt cầu, nên đổi hướng hoặc bật tường vẫn lăn nối tiếp tự nhiên.
	var axis := Vector3(-movement.y, movement.x, 0.0).normalized()
	# Góc = quãng đường / bán kính. Bóng chậm lại trên cát thì hình cũng lăn chậm theo.
	# Chặn bán kính quá nhỏ và bỏ các vòng quay trọn để không tích lũy góc rất lớn.
	var angle := fposmod(movement.length() / maxf(rolling_radius, 0.5), TAU)
	_orientation = (Quaternion(axis, angle) * _orientation).normalized()
	queue_redraw()

## Chiếu các chấm từ mặt cầu xuống sprite, giữ đúng nét pixel của ảnh bóng gốc.
func _draw() -> void:
	if not show_roll_marks:
		return
	# Hai điểm có thể chiếu vào cùng một pixel; chỉ vẽ một lần để không bị đậm hơn.
	var drawn_pixels: Array[Vector2] = []
	for surface_point in SURFACE_POINTS:
		var point: Vector3 = _orientation * surface_point
		# Z dương là phía nhìn thấy; chấm gần mép được làm mờ rồi khuất phía sau.
		if point.z <= 0.15:
			continue
		var projected := Vector2(point.x, point.y) * MARK_SURFACE_RADIUS
		# Sprite 6x6 có tâm nằm giữa các pixel; căn chấm vào tâm pixel để không bị nhòe.
		var pixel_center := projected.floor() + Vector2(0.5, 0.5)
		# Các pixel trắng của ảnh nằm trong hình thoi này; bỏ điểm trên viền đen.
		if absf(pixel_center.x) + absf(pixel_center.y) > 2.0 or pixel_center in drawn_pixels:
			continue
		drawn_pixels.append(pixel_center)
		var color := mark_color
		color.a *= smoothstep(0.15, 0.65, point.z)
		# Một ô vuông 1x1 đúng bằng một pixel gốc, phóng theo camera cùng toàn bộ quả bóng.
		draw_rect(Rect2(pixel_center - Vector2(0.5, 0.5), Vector2.ONE), color)
