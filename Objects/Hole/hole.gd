# Vùng nhận bóng của lỗ golf; chỉ hoàn thành khi tâm bóng lọt vào miệng lỗ đủ chậm.
extends Area2D

## Báo cho scene/HUD biết lỗ đã hoàn thành, ví dụ để hiện thông báo chiến thắng.
signal completed

## Vận tốc tối đa để lỗ nhận bóng, tính bằng pixel thế giới/giây.
## Bóng nhanh hơn mức này vẫn có thể lăn qua miệng lỗ mà chưa bị hút vào.
## Tăng ngưỡng để bóng dễ vào lỗ hơn; giảm ngưỡng sẽ yêu cầu bóng phải chậm hơn nữa.
@export var max_capture_speed: float = 70.0

# Ghi nhớ đã nhận bóng để không hoàn thành nhiều lần; tải lại scene sẽ đặt lại false.
var _completed := false

# Đợi node con sẵn sàng rồi lấy polygon mô tả đúng hình dạng miệng lỗ.
@onready var _mouth: CollisionPolygon2D = $Mouth

## Kiểm tra tâm bóng có nằm trong miệng lỗ, thay vì chỉ chạm vào vùng bao quanh.
func contains_ball_center(world_position: Vector2) -> bool:
	# Chỉ phần miệng tối màu được tính là lỗ; nền cỏ xanh trong ảnh không được tính.
	# Đổi tâm bóng từ tọa độ thế giới sang tọa độ local của polygon trước khi kiểm tra.
	return Geometry2D.is_point_in_polygon(_mouth.to_local(world_position), _mouth.polygon)

## Kiểm tra các vật thể đang chạm vùng lỗ theo nhịp cập nhật vật lý; không cần dùng _delta.
func _physics_process(_delta: float) -> void:
	# Không xử lý gameplay trong editor hoặc sau khi lỗ đã nhận bóng thành công.
	if Engine.is_editor_hint() or _completed:
		return
	# Area2D chỉ cung cấp danh sách vật thể chạm vùng; còn phải lọc tâm bóng và tốc độ.
	for body in get_overlapping_bodies():
		# Chỉ xử lý vật thể vật lý có hàm vào lỗ của bóng; bỏ qua vật thể khác.
		if not body is RigidBody2D or not body.has_method("sink_into_hole"):
			continue
		# Bỏ qua bóng đã vào lỗ, bóng đang xử lý chìm nước hoặc bóng đi quá nhanh.
		# Khi vùng nước và lỗ chồng nhau, hiệu ứng nước không được làm người chơi thắng lỗ.
		if body.is_sunk or body.is_in_water or body.linear_velocity.length() > max_capture_speed:
			continue
		# Va chạm của mép bóng với vùng lỗ chưa đủ: tâm phải nằm trong miệng tối màu.
		if not contains_ball_center(body.global_position):
			continue
		# Khóa trạng thái trước khi gọi hiệu ứng để cùng một lỗ chỉ nhận bóng một lần.
		_completed = true
		# Script của bóng lo dừng vật lý, kéo về tâm lỗ và thu nhỏ hình bóng.
		body.sink_into_hole(global_position)
		# Thông báo hoàn thành rồi dừng duyệt, không nhận thêm bóng trong cùng bước vật lý.
		completed.emit()
		break

## Sau khi hoàn thành lỗ, cho phép nhấn R để tải lại scene hiện tại và chơi lại.
func _unhandled_key_input(event: InputEvent) -> void:
	# Không khởi động lại scene khi Godot đang dùng script trong editor.
	if Engine.is_editor_hint():
		return
	# Chỉ nhận lần nhấn phím đầu tiên; bỏ qua sự kiện lặp khi giữ phím lâu.
	if _completed and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			# Tạo lại scene từ dữ liệu đã lưu, đồng thời đặt lại bóng, gậy và trạng thái lỗ.
			get_tree().reload_current_scene()
