# Cổng chỉ phát hiện bóng và gửi yêu cầu dịch chuyển; ball.gd mới đổi trạng thái vật lý.
# Cổng cam và xanh là hai scene độc lập, có thể đặt ở vị trí bất kỳ trên sân.
# Gán Destination của mỗi cổng tới cổng còn lại trong Inspector để nối đủ hai chiều.
@tool
extends Area2D

## Cổng đích. Kéo node PortalOrange/PortalBlue khác vào đây trong Inspector.
## Mỗi instance có đích riêng: gán cam tới xanh, rồi gán xanh ngược lại tới cam.
@export_node_path("Area2D") var destination: NodePath = NodePath(""):
	set(value):
		destination = value
		if is_inside_tree():
			update_configuration_warnings()
## Khoảng đặt bóng cách tâm cổng ĐÍCH khi đi từ cổng này, tính bằng pixel thế giới.
## Script tự tăng khoảng này nếu cần để bóng nằm ngoài vòng nhận của cổng đích.
@export_range(0.0, 64.0, 1.0) var exit_distance: float = 12.0
## Tắt: giữ hướng/vận tốc đi vào. Bật: đi ra theo trục X dương của cổng đích.
## Có thể xoay node cổng đích để chỉnh hướng ra khi tùy chọn này được bật.
@export var redirect_exit_direction: bool = false
## Sau một lượt đi, khóa nhận lại ít nhất từng này giây VÀ chờ bóng ra khỏi cổng.
@export_range(0.05, 2.0, 0.05) var travel_cooldown: float = 0.2

# Mỗi mục giữ WeakRef và thời điểm có thể mở khóa; không giữ bóng đã bị xóa trong bộ nhớ.
var _blocked_balls: Dictionary = {}

## Chỉ kết nối tín hiệu khi chơi; @tool được dùng cho cảnh báo cấu hình trong editor.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## Kiểm tra lại mỗi bước để chỉ nhận khi TÂM bóng đã vào miệng cổng.
## body_entered có thể báo sớm lúc mới chạm mép; vòng lặp này chờ tâm vào hẳn.
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_prune_blocked_balls()
	if _get_destination() == null:
		return
	for body in get_overlapping_bodies():
		_try_transport(body)

## Tín hiệu hỗ trợ trường hợp bóng vừa xuất hiện ngay bên trong vùng nhận.
func _on_body_entered(body: Node2D) -> void:
	_try_transport(body)

## Rời cổng chỉ mở khóa nếu thời gian chống lặp tối thiểu cũng đã hết.
func _on_body_exited(body: Node2D) -> void:
	var instance_id := body.get_instance_id()
	if not _blocked_balls.has(instance_id):
		return
	var record: Dictionary = _blocked_balls[instance_id]
	if Time.get_ticks_msec() >= int(record["release_after"]):
		_blocked_balls.erase(instance_id)

## Cổng nguồn gọi trên cổng đích TRƯỚC khi gửi yêu cầu dịch chuyển bóng.
## Nhờ vậy cổng đích không thể gửi bóng ngược lại ngay trong cùng lượt vật lý.
func block_ball_until_exit(ball: Node2D) -> void:
	_blocked_balls[ball.get_instance_id()] = {
		"body": weakref(ball),
		"release_after": Time.get_ticks_msec() + int(maxf(travel_cooldown, 0.05) * 1000.0),
	}

## Hủy khóa khi yêu cầu dịch chuyển bị bóng từ chối, chẳng hạn bóng đang chìm nước.
func _forget_ball(ball: Node2D) -> void:
	_blocked_balls.erase(ball.get_instance_id())

## Cho cả cổng đối tác kiểm tra khóa mà không cần biết cách lưu Dictionary bên trong.
func _is_ball_blocked(ball: Node2D) -> bool:
	return _blocked_balls.has(ball.get_instance_id())

## Dọn bóng đã bị xóa; cũng xử lý điểm ra nằm ngoài Area nên không phát body_exited.
func _prune_blocked_balls() -> void:
	var now := Time.get_ticks_msec()
	for instance_id in _blocked_balls.keys():
		var record: Dictionary = _blocked_balls[instance_id]
		var body_reference: WeakRef = record["body"]
		var body := body_reference.get_ref() as Node2D
		if not is_instance_valid(body):
			_blocked_balls.erase(instance_id)
		elif now >= int(record["release_after"]) and not overlaps_body(body):
			_blocked_balls.erase(instance_id)

## Kiểm tra điều kiện, tính điểm ra an toàn, rồi nhờ ball.gd xếp hàng xử lý vật lý.
func _try_transport(body: Node2D) -> void:
	var ball := body as RigidBody2D
	if ball == null or not ball.has_method("queue_portal_travel") or _is_ball_blocked(ball):
		return
	if not _is_center_inside(ball.global_position):
		return
	var target := _get_destination()
	if target == null or bool(target.call("_is_ball_blocked", ball)):
		return
	var incoming_velocity := ball.linear_velocity
	var exit_direction := incoming_velocity.normalized()
	# Bóng đứng yên vẫn có thể qua cổng; dùng hướng đích để chọn điểm ra, vận tốc vẫn là 0.
	if redirect_exit_direction or exit_direction == Vector2.ZERO:
		exit_direction = target.global_transform.x.normalized()
	if exit_direction == Vector2.ZERO:
		exit_direction = Vector2.RIGHT
	var exit_velocity := incoming_velocity
	if redirect_exit_direction:
		exit_velocity = exit_direction * incoming_velocity.length()
	# Chừa cả bán kính cổng, bán kính bóng và 1 pixel để không xuất hiện ngay trong vòng nhận.
	var safe_distance := _get_portal_world_radius(target) + _get_ball_world_radius(ball) + 1.0
	var exit_position := target.global_position + exit_direction * maxf(exit_distance, safe_distance)
	target.call("block_ball_until_exit", ball)
	# Không gán global_position/linear_velocity ở đây: RigidBody được đổi trong _integrate_forces.
	var accepted := bool(ball.call("queue_portal_travel", exit_position, exit_velocity, self, target))
	if accepted:
		block_ball_until_exit(ball)
	else:
		target.call("_forget_ball", ball)

## Chỉ nhận tâm bóng nằm trong CircleShape2D; vòng va chạm không phải vật chắn.
func _is_center_inside(world_position: Vector2) -> bool:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.disabled:
		return false
	var circle := collision.shape as CircleShape2D
	if circle == null:
		return false
	return collision.to_local(world_position).length_squared() <= circle.radius * circle.radius

## Lấy phạm vi cổng trong thế giới, có tính tỉ lệ node, để chọn điểm ra bên ngoài.
func _get_portal_world_radius(portal: Area2D) -> float:
	var collision := portal.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return 6.0
	var circle := collision.shape as CircleShape2D
	if circle == null:
		return 6.0
	var world_scale := collision.global_scale.abs()
	return circle.radius * maxf(world_scale.x, world_scale.y)

## Vùng nhấn chuột của bóng lớn hơn hình va chạm, nên không dùng grab_radius ở đây.
func _get_ball_world_radius(ball: RigidBody2D) -> float:
	var collision := ball.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return 3.0
	var circle := collision.shape as CircleShape2D
	if circle == null:
		return 3.0
	var world_scale := collision.global_scale.abs()
	return circle.radius * maxf(world_scale.x, world_scale.y)

## Chỉ nhận node cổng cùng script trong cùng cây scene; không tự tìm cổng theo màu.
func _get_destination() -> Area2D:
	if destination.is_empty():
		return null
	var target := get_node_or_null(destination) as Area2D
	if target == null or target == self or not target.is_inside_tree() or target.get_script() != get_script():
		return null
	return target

## Ball chỉ gọi sau khi dịch chuyển thành công, nên lượt bị từ chối không phát tia sáng.
## Node con vẽ hiệu ứng riêng; tuyệt đối không xoay/phóng to Area2D hoặc vùng nhận bóng.
func play_travel_effect(arriving: bool) -> void:
	var visual := get_node_or_null("PortalVisual")
	if visual != null and visual.has_method("play_travel_effect"):
		visual.call("play_travel_effect", arriving)

## Màu cổng được dùng nhuộm nhẹ ảnh bóng khi biến mất/xuất hiện ở mỗi đầu.
func get_effect_color() -> Color:
	var visual := get_node_or_null("PortalVisual")
	if visual != null:
		return visual.get("effect_color")
	return Color.WHITE

## Cảnh báo hiện trên node trong editor, không lặp thông báo mỗi frame khi chơi.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if destination.is_empty():
		warnings.append("Chưa nối cổng đích: chọn node cổng còn lại trong Destination. Gán đích cho cả cam và xanh để dịch chuyển hai chiều.")
	elif _get_destination() == null:
		warnings.append("Destination phải là node cổng khác dùng portal.gd trong cùng sân.")
	return warnings
