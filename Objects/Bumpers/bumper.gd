# Các scene bumper dùng chung script này: hình tròn tím và bốn góc tam giác sọc cam/trắng.
# StaticBody2D giữ vật đứng yên; phần bóng đọc group golf_bumpers khi va chạm,
# lấy hướng pháp tuyến rồi gọi get_bounce_velocity để nhận cú bật có tăng tốc.
# Ảnh luôn lấy từ SummerTile.png bằng Region, không tạo hoặc sửa ảnh gốc.
extends StaticBody2D

## Hệ số nhân tốc độ lúc chạm. Ví dụ 120 * 1.65 = 198 pixel/giây trước khi giới hạn.
@export_range(0.0, 4.0, 0.05) var speed_multiplier: float = 1.65
## Tốc độ bật tối thiểu: bóng chạm rất chậm vẫn được đẩy đủ rõ, mặc định 180 pixel/giây.
@export_range(0.0, 500.0, 5.0) var minimum_bounce_speed: float = 180.0
## Chặn cú bật quá mạnh để bóng không tăng tốc vô hạn khi gặp nhiều bumper liên tiếp.
@export_range(0.0, 1000.0, 5.0) var maximum_bounce_speed: float = 300.0
## Khoảng nghỉ trước khi cùng bumper được đẩy bóng lần nữa, tính bằng giây.
## Phần bóng dùng thông số này cùng trạng thái tiếp xúc để không đẩy lặp mỗi frame.
@export_range(0.0, 2.0, 0.01) var cooldown_seconds: float = 0.12

# Tween nháy sáng đang chạy; lưu lại để cú chạm mới có thể thay thế hiệu ứng trước.
var _hit_tween: Tween
# Lấy sprite sau khi các node con sẵn sàng; script dùng được cho cả hai hình bumper.
@onready var _sprite: Sprite2D = $Sprite2D
# Ghi màu gốc để hiệu ứng luôn trở về đúng màu đã chỉnh trong scene/Inspector.
@onready var _rest_modulate: Color = _sprite.modulate

## Trả vận tốc mới trong tọa độ thế giới, không trực tiếp sửa thân vật lý của bóng.
func get_bounce_velocity(incoming_velocity: Vector2, outward_normal: Vector2) -> Vector2:
	# Normal chỉ cho hướng ra khỏi bề mặt; chuẩn hóa để không làm sai góc phản xạ.
	var normal := outward_normal.normalized()
	if normal == Vector2.ZERO:
		# Dự phòng khi không lấy được normal: bật ngược hướng tới, hoặc sang phải nếu đứng yên.
		normal = -incoming_velocity.normalized() if incoming_velocity != Vector2.ZERO else Vector2.RIGHT
	var outgoing_direction := incoming_velocity.normalized()
	if outgoing_direction == Vector2.ZERO:
		# Nếu vật chuyển động khác đẩy bóng đang đứng yên vào bumper, vẫn có hướng thoát ra.
		outgoing_direction = normal
	elif incoming_velocity.dot(normal) < 0.0:
		# Dot âm nghĩa là bóng còn đi vào bề mặt: phản xạ theo đúng cạnh đã chạm.
		# Với tam giác, cạnh chéo có normal chéo nên bóng bật đúng góc, không luôn hướng từ tâm.
		outgoing_direction = incoming_velocity.bounce(normal).normalized()
	# Nếu dot không âm thì solver đã cho bóng bật ra; giữ hướng đó để không phản xạ ngược lần hai.
	# Chặn các giá trị âm hoặc minimum lớn hơn maximum nếu bị đổi từ script bên ngoài Inspector.
	var speed_cap := maxf(maximum_bounce_speed, 0.0)
	var speed_floor := minf(maxf(minimum_bounce_speed, 0.0), speed_cap)
	var boosted_speed := incoming_velocity.length() * maxf(speed_multiplier, 0.0)
	var outgoing_speed := clampf(maxf(boosted_speed, speed_floor), 0.0, speed_cap)
	return outgoing_direction * outgoing_speed

## Nháy sáng ngắn khi đẩy bóng, giúp người chơi thấy rõ bumper vừa được kích hoạt.
func play_hit_effect() -> void:
	# Lệnh phản hồi chỉ chạy khi node đã vào scene; không tạo tween cho một resource chưa được đặt.
	if not is_inside_tree():
		return
	# Dừng tween cũ trước khi tạo tween mới để nhiều cú chạm không tranh nhau chỉnh màu.
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	_sprite.modulate = _rest_modulate * Color(1.5, 1.5, 1.5, 1.0)
	# Tween theo nhịp vật lý giống chuyển động bóng; chỉ đổi màu, không đổi hình va chạm.
	_hit_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_hit_tween.tween_property(_sprite, "modulate", _rest_modulate, 0.14)
