# Godot xử lý va chạm của bóng; script này điều khiển cú đánh và loại mặt sân.
# Luồng cát: đọc nhãn ô dưới tâm bóng -> chọn mức giảm tốc -> giảm vận tốc mỗi bước vật lý.
# Luồng nước: vào đủ sâu -> khóa thao tác, tính phạt -> chạy hiệu ứng -> hồi bóng -> đánh tiếp.
# Luồng mũi tên: lăn đè lên ô, tới giữa quãng đường xuyên ô -> đổi hướng, giữ nguyên tốc độ.
# Hình lăn: đọc quãng đường thực tế -> xoay các chấm trên mặt bóng, không đổi vận tốc.
# Bumper: đọc va chạm thật -> phản xạ và tăng tốc đúng một lần cho mỗi lần chạm.
# Cổng: nhận yêu cầu -> đổi vị trí trong bước vật lý -> xóa lịch sử đường lăn cũ.
extends RigidBody2D

## Báo số gậy mới cho HUD, bao gồm cả cú đánh và gậy phạt khi vào nước.
signal stroke_count_changed(count: int)

## Vận tốc lớn nhất của một cú đánh, tính bằng pixel thế giới/giây.
## Tăng để cú đánh nhanh hơn; ngưỡng lỗ nhận bóng được chỉnh riêng trong hole.gd.
@export var max_shot_speed: float = 120.0
## Kéo xa đến mức này thì đạt lực đánh tối đa; kéo xa hơn không tăng vận tốc.
@export var max_drag_distance: float = 50.0
## Mức giảm vận tốc mỗi giây trên cỏ, tính bằng pixel thế giới/giây².
@export var rolling_deceleration: float = 40.0
## Mức giảm vận tốc trên cát; mặc định 240, gấp 6 lần mức 40 của cỏ.
@export var sand_deceleration: float = 240.0
## Khoảng cách tối đa từ chuột đến tâm bóng để bắt đầu kéo, tính bằng pixel thế giới.
@export var grab_radius: float = 7.0
## TileMap chứa sân. Có thể gán trong Inspector; để trống sẽ tìm node ../TileMap.
@export var surface_tile_map: TileMap
## Chỉ số lớp vẽ cần đọc trong TileMap: 0 là lớp đầu tiên.
@export var surface_map_layer: int = 0
## Số gậy phạt mỗi lần vào nước. Đặt 0 nếu muốn hồi bóng mà không cộng phạt.
@export var water_penalty_strokes: int = 1
## Độ sâu cần đi qua mép nước trước khi chìm; mặc định 5 pixel thế giới, không phụ thuộc zoom.
## Inspector cho chỉnh từ 0 đến 7, mỗi nấc 0.5; đặt 0 để chìm ngay khi tâm vào nước.
@export_range(0.0, 7.0, 0.5) var water_entry_depth: float = 5.0
## Thời gian bóng thu nhỏ và chìm xuống nước trước khi hồi về, tính bằng giây.
@export_range(0.1, 2.0, 0.05) var water_sink_duration: float = 0.55
## Thời gian khóa dịch chuyển sau khi qua cổng, tránh hai cổng kéo bóng qua lại liên tục.
@export_range(0.05, 2.0, 0.05) var portal_cooldown_duration: float = 0.2
## Bật ảnh bóng thu vào cổng nguồn và hiện dần ở đầu ra; chỉ ảnh hưởng hình ảnh.
@export var portal_effects_enabled: bool = true
## Thời gian thu/hiện hình bóng khi qua cổng, tính bằng giây; không làm chậm vận tốc lăn.
@export_range(0.05, 0.5, 0.01) var portal_effect_duration: float = 0.16

# Kéo ngắn hơn 2 pixel được coi là nhấp chuột, không tạo cú đánh.
const MIN_DRAG_DISTANCE := 2.0
# Tên trường Custom Data đã gắn trong TileSet, khác với chỉ số lớp vẽ ở trên.
const SURFACE_DATA_NAME := "surface_layer"
# Trường Custom Data riêng của mũi tên; không thay thế nhãn cát/nước trong surface_layer.
const ARROW_DATA_NAME := "arrow_direction"
# Hiệu ứng gợn sóng và giọt nước tự vẽ, không cần thêm ảnh vào TileSet.
const WATER_SPLASH_EFFECT = preload("res://Objects/Effects/water_splash.gd")
# Script vẽ mặt bóng lăn, dùng làm kiểu cho node con bên dưới Sprite2D.
const BALL_ROLL_VISUAL = preload("res://Objects/Ball/ball_roll_visual.gd")
# Quản lý riêng tween cổng để có thể hủy trước hiệu ứng chìm nước/vào lỗ.
const BALL_PORTAL_EFFECT = preload("res://Objects/Ball/ball_portal_effect.gd")

# Người chơi có đang giữ chuột để kéo bóng hay không.
var _is_dragging := false
# Vị trí chuột lúc bắt đầu kéo, trong tọa độ thế giới của sân.
var _drag_start := Vector2.ZERO
# Vector từ điểm bắt đầu kéo đến chuột, đã giới hạn bởi max_drag_distance.
var _drag_offset := Vector2.ZERO
# Vận tốc cú đánh chờ áp dụng ở bước vật lý kế tiếp; không phải lực hay xung lực.
var _pending_shot := Vector2.ZERO
# Vị trí trước cú đánh gần nhất, dùng để hồi bóng khi rơi vào nước.
var _shot_start_position := Vector2.ZERO
# Đánh dấu đã xử lý lần chạm nước này, tránh cộng phạt liên tục mỗi bước vật lý.
# Cờ này chỉ được xóa khi bóng đã về sân hoặc đang ở phần nước sát bờ chưa đủ sâu.
var _was_in_water := false
# Khi hiệu ứng chìm kết thúc, bước vật lý tiếp theo mới được đổi vị trí bóng.
var _water_respawn_pending := false
# Lưu vị trí trước để quét đường bóng đi qua, kể cả khi bóng nhanh vượt nguyên mũi tên.
var _previous_arrow_position := Vector2.ZERO
# Khi mới tạo bóng hoặc vừa hồi từ nước, chưa có đoạn đường hợp lệ để kiểm tra mũi tên.
var _has_previous_arrow_position := false
# Ô hiện tại đã điều hướng ở bước trước hay chưa; giữ hướng sau khi đã qua điểm rẽ.
# Khi rời ô, cờ này cũng giúp bỏ qua mũi tên cũ trong đoạn đường vừa đi.
var _previous_arrow_was_guiding := false
# Vận tốc cuối bước trước, dùng lấy hướng đi VÀO bumper trước khi bộ giải va chạm bật bóng ra.
var _previous_motion_velocity := Vector2.ZERO
# Các bumper đã tăng lực và còn đang chạm bóng; tiếp xúc đứng yên chưa được tính là đã bật.
var _bumper_contacts: Dictionary = {}
# Khóa ngắn theo ID bumper, ngăn nhiều lần tăng lực khi bóng rung ngay tại một mép va chạm.
var _bumper_cooldowns: Dictionary = {}
# Cổng chỉ đặt yêu cầu; _integrate_forces mới được thay đổi trạng thái thân bóng.
var _portal_travel_pending := false
var _portal_exit_position := Vector2.ZERO
var _portal_exit_velocity := Vector2.ZERO
# Giữ tham chiếu yếu để không giữ cổng đã bị xóa sống mãi trong bộ nhớ.
var _portal_source: WeakRef
var _portal_destination: WeakRef
# Đếm theo thời gian vật lý, độc lập với tốc độ khung hình vẽ.
var _portal_cooldown_remaining := 0.0
# Node hiệu ứng được tạo một lần; không thêm một bộ điều khiển mới sau mỗi lượt qua cổng.
var _portal_visual: BALL_PORTAL_EFFECT
# Tỉ lệ hình bóng ban đầu; hiệu ứng làm nhỏ Sprite2D rồi khôi phục tỉ lệ này khi hồi bóng.
var _sprite_rest_scale := Vector2.ONE
# Vị trí Sprite2D so với thân bóng; dùng để bỏ độ lệch đi xuống sau hiệu ứng chìm.
var _sprite_rest_position := Vector2.ZERO
# Màu và độ trong suốt ban đầu của Sprite2D, để hồi bóng không bị xanh hoặc mờ mãi.
var _sprite_rest_modulate := Color.WHITE
# Trong lúc chìm, chặn cú đánh mới và không cho lỗ nhận bóng.
var is_in_water := false
# Khi đã vào lỗ, bóng ngừng nhận cú đánh và ngừng lăn.
var is_sunk := false
# Tổng số gậy hiện tại, gồm cú đánh đã thực hiện và gậy phạt.
var stroke_count: int = 0

# Lấy node sau khi các node con đã sẵn sàng; các chấm tự đi theo hiệu ứng của Sprite2D.
@onready var _roll_visual: BALL_ROLL_VISUAL = $Sprite2D/RollMarks

## Chuẩn bị liên kết sân và cấu hình vật lý khi bóng được thêm vào scene.
func _ready() -> void:
	# Tự tìm TileMap cùng cấp nếu chưa gán node này trong Inspector.
	if surface_tile_map == null:
		surface_tile_map = get_node_or_null("../TileMap") as TileMap
	# Dùng điểm xuất phát làm vị trí hồi bóng trước khi có cú đánh đầu tiên.
	_shot_start_position = global_position
	# Lưu thông số hình ảnh thực tế trong scene, kể cả khi đã chỉnh chúng trong Inspector.
	_sprite_rest_scale = $Sprite2D.scale
	_sprite_rest_position = $Sprite2D.position
	_sprite_rest_modulate = $Sprite2D.modulate
	_portal_visual = BALL_PORTAL_EFFECT.new()
	_portal_visual.name = "PortalEffect"
	add_child(_portal_visual)
	_portal_visual.setup($Sprite2D)
	# Chốt mốc lăn tại điểm xuất phát, tránh coi đoạn từ gốc tọa độ tới đây là một cú lăn.
	_roll_visual.reset_motion(global_position)
	# Tắt damping tự động để tốc độ chỉ giảm theo phần xử lý mặt sân bên dưới.
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	# Giữ bóng không tự xoay và giảm khả năng xuyên tường khi di chuyển nhanh.
	lock_rotation = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	# Cần báo tiếp xúc thật để phân biệt cạnh của bumper với vùng hình ảnh bao quanh nó.
	max_contacts_reported = 16
	contact_monitor = true

## Nhận thao tác nhấn, kéo và thả chuột trái để chuẩn bị một cú đánh.
func _input(event: InputEvent) -> void:
	# Chặn thao tác khi đã vào lỗ hoặc chưa thoát trạng thái xử lý nước.
	if is_sunk or _was_in_water or is_in_water:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Đổi tọa độ chuột trên màn hình sang tọa độ sân, có tính đến camera/zoom.
		var mouse_world: Vector2 = get_canvas_transform().affine_inverse() * event.position
		if event.pressed:
			# Chỉ bắt đầu kéo khi bóng gần dừng và chưa có cú đánh đang chờ.
			if linear_velocity.length() > 1.0 or _pending_shot != Vector2.ZERO:
				return
			# Nhấn quá xa bóng thì không bắt đầu kéo.
			if mouse_world.distance_to(global_position) > grab_radius:
				return
			_is_dragging = true
			_drag_start = mouse_world
			_drag_offset = Vector2.ZERO
		elif _is_dragging:
			# Cập nhật cả vị trí chuột lúc thả để không bỏ sót đoạn kéo cuối.
			_update_drag(mouse_world)
			if _drag_offset.length() >= MIN_DRAG_DISTANCE:
				# Bóng đi ngược hướng kéo; kéo càng xa thì vận tốc cú đánh càng lớn.
				# maxf(..., 1.0) tránh chia cho 0 nếu chỉnh giới hạn kéo quá nhỏ.
				_pending_shot = -_drag_offset / maxf(max_drag_distance, 1.0) * max_shot_speed
				# Đánh thức RigidBody2D để bước vật lý tiếp theo nhận cú đánh.
				sleeping = false
			_cancel_drag()
		queue_redraw()
	elif event is InputEventMouseMotion and _is_dragging:
		# Khi đang kéo, cập nhật vector kéo và vẽ lại đường ngắm theo chuột.
		_update_drag(get_canvas_transform().affine_inverse() * event.position)
		queue_redraw()

## Tính hướng/khoảng kéo và chặn độ dài ở mức tối đa cho phép.
func _update_drag(mouse_world: Vector2) -> void:
	_drag_offset = (mouse_world - _drag_start).limit_length(maxf(max_drag_distance, 1.0))

## Xóa trạng thái kéo và đường ngắm; không xóa cú đánh đã đưa vào hàng chờ.
func _cancel_drag() -> void:
	_is_dragging = false
	_drag_offset = Vector2.ZERO
	queue_redraw()

## Hủy thao tác kéo khi chuyển sang cửa sổ khác, tránh bị kẹt giữ chuột.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancel_drag()

## Thay đổi trạng thái bóng trong bước vật lý, nơi phù hợp để điều khiển RigidBody2D.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Giảm các khóa theo thời gian của bước vật lý trước khi nhận tác động mới.
	_update_mechanism_cooldowns(state.step)
	# Dịch chuyển được thực hiện trước khi đọc mặt sân, tránh xét nhầm đường từ cổng cũ tới cổng mới.
	if _portal_travel_pending:
		_apply_pending_portal_travel(state)
		return
	# Cập nhật hình lăn từ vị trí thân vật lý thực tế, kể cả sau bật tường hoặc rẽ mũi tên.
	# Khi chìm/vào lỗ/hiện ra từ cổng, chỉ cập nhật mốc chứ không quay chấm theo scale của tween.
	# Scale đang nhỏ sẽ làm phép đổi tọa độ tính sai quãng lăn nếu vẫn xoay chấm lúc này.
	_roll_visual.advance_to(state.transform.origin,
		not is_sunk and not is_in_water and not _portal_visual.is_playing())
	# Bóng đã hoàn thành lỗ thì không nhận thêm chuyển động từ phần cát/nước.
	if is_sunk:
		state.linear_velocity = Vector2.ZERO
		_previous_motion_velocity = Vector2.ZERO
		return
	# Giữ thân vật lý đứng yên tại chỗ rơi, chỉ hình bóng được làm hiệu ứng chìm.
	if is_in_water:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		_previous_motion_velocity = Vector2.ZERO
		# Hiệu ứng báo xong bằng một cờ; chỉ tại bước vật lý này mới được hồi vị trí.
		if _water_respawn_pending:
			_reset_from_water(state)
		# Trong lúc chìm không chạy tiếp phần đánh bóng hoặc giảm tốc trên cát.
		return
	# Tra loại ô chứa tâm bóng bằng vị trí do hệ vật lý cung cấp.
	var surface := _get_surface_at(state.transform.origin)
	# Cho bóng đi sâu qua mép nước trước khi bắt đầu chìm, tránh rơi khi còn ở bờ.
	# Điều kiện đầu kiểm tra tâm; điều kiện sau kiểm tra thêm khoảng cách tới bờ nước.
	if surface == "water" and _is_deep_enough_in_water(state.transform.origin):
		# Chỉ bắt đầu hiệu ứng và cộng phạt một lần trong mỗi đợt chạm nước.
		if not _was_in_water:
			# Ghi nhận trước khi bắt đầu hiệu ứng để các bước tiếp theo không tính lại phạt.
			_was_in_water = true
			_begin_water_fall(state)
		else:
			# Nếu điểm hồi vẫn là nước, giữ bóng đứng yên mà không cộng phạt thêm.
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0.0
		return
	# Về sân hoặc phần sát mép nước sẽ mở lại thao tác đánh.
	_was_in_water = false
	if _pending_shot != Vector2.ZERO:
		# Ghi nhớ điểm trước cú đánh rồi áp dụng vận tốc đúng một lần.
		_shot_start_position = state.transform.origin
		state.linear_velocity = _pending_shot
		_pending_shot = Vector2.ZERO
		# Chỉ tính gậy khi cú đánh thực sự được áp dụng.
		stroke_count += 1
		stroke_count_changed.emit(stroke_count)
	else:
		# Cát dùng mức riêng; cỏ, sát mép nước, ô trống và nhãn khác dùng mức mặc định.
		# Với giá trị mặc định: cát giảm 240 pixel/giây vận tốc mỗi giây, cỏ giảm 40.
		var deceleration := sand_deceleration if surface == "sand" else rolling_deceleration
		# move_toward giảm vận tốc về 0 mà không đảo chiều khi bóng sắp dừng.
		# Nhân state.step để tính lượng giảm theo thời gian của bước vật lý.
		# Ví dụ bước dài 1/60 giây: trên cát giảm 240/60 = 4 pixel/giây vận tốc.
		# maxf(..., 0.0) chặn giá trị âm để việc chỉnh Inspector không làm bóng tự tăng tốc.
		state.linear_velocity = state.linear_velocity.move_toward(
			Vector2.ZERO, maxf(deceleration, 0.0) * state.step
		)
	# Sau khi nhận cú đánh hoặc giảm tốc tự nhiên, mũi tên chỉ đổi hướng vận tốc hiện tại.
	# Các nhánh vào lỗ/chìm nước đã return ở trên nên không bị mũi tên tác động.
	_apply_bumper_bounce(state)
	_apply_arrow_direction(state)
	# Lưu sau khi bumper/mũi tên đã xử lý để bước sau có đúng hướng trước va chạm.
	_previous_motion_velocity = state.linear_velocity

## Nhận yêu cầu từ scene cổng; trả false nếu bóng đang chìm, đã vào lỗ hoặc còn bị khóa.
func queue_portal_travel(exit_position: Vector2, exit_velocity: Vector2,
		source: Node, destination: Node) -> bool:
	if is_sunk or is_in_water or _portal_travel_pending or _portal_cooldown_remaining > 0.0:
		return false
	if not is_instance_valid(source) or not is_instance_valid(destination) or source == destination:
		return false
	if not exit_position.is_finite() or not exit_velocity.is_finite():
		return false
	_portal_exit_position = exit_position
	_portal_exit_velocity = exit_velocity
	_portal_source = weakref(source)
	_portal_destination = weakref(destination)
	_portal_travel_pending = true
	# Hủy đường ngắm/cú đánh đang chờ, nhưng không cộng gậy vì qua cổng không phải cú đánh mới.
	_cancel_drag()
	_pending_shot = Vector2.ZERO
	# Đánh thức cả bóng đang đứng yên để yêu cầu được thực hiện ở bước kế tiếp.
	sleeping = false
	return true

## Đặt thân bóng tại đầu ra bằng trạng thái vật lý, giữ vận tốc do cổng tính sẵn.
func _apply_pending_portal_travel(state: PhysicsDirectBodyState2D) -> void:
	# Nếu một cổng bị xóa trước bước này, bỏ yêu cầu thay vì đưa bóng tới một đích không còn tồn tại.
	if is_sunk or is_in_water or _portal_source == null or _portal_destination == null:
		_cancel_pending_portal_travel()
		return
	if not is_instance_valid(_portal_source.get_ref()) or not is_instance_valid(_portal_destination.get_ref()):
		_cancel_pending_portal_travel()
		return
	# Chụp hình ở vị trí nguồn bằng transform vật lý, trước khi thân bóng nhảy sang đích.
	# Dùng kích thước/màu gốc, kể cả khi lượt hiệu ứng trước chưa kịp hiện đủ.
	var departure_transform := state.transform * Transform2D(
		$Sprite2D.rotation, _sprite_rest_scale, $Sprite2D.skew, _sprite_rest_position)
	# Thêm ảnh/tween ngoài bước vật lý. Chỉ lượt thành công mới làm hai cổng lóe sáng.
	_play_portal_effects.call_deferred(_portal_source, _portal_destination, departure_transform)
	_portal_travel_pending = false
	_portal_source = null
	_portal_destination = null
	var exit_transform := state.transform
	exit_transform.origin = _portal_exit_position
	state.transform = exit_transform
	state.linear_velocity = _portal_exit_velocity
	state.angular_velocity = 0.0
	_portal_cooldown_remaining = maxf(portal_cooldown_duration, 0.05)
	_previous_motion_velocity = state.linear_velocity
	# Dịch chuyển không tạo một đường lăn xuyên qua các mũi tên nằm giữa hai cổng.
	_has_previous_arrow_position = false
	_previous_arrow_was_guiding = false
	_bumper_contacts.clear()
	_bumper_cooldowns.clear()
	_roll_visual.reset_motion(state.transform.origin)

## Chạy hình ảnh sau dịch chuyển; WeakRef giúp an toàn nếu cổng bị xóa ngay sau lượt đi.
func _play_portal_effects(source_reference: WeakRef, destination_reference: WeakRef,
		departure_transform: Transform2D) -> void:
	var source := source_reference.get_ref() as Node2D
	var destination := destination_reference.get_ref() as Node2D
	var source_center := departure_transform.origin
	var source_color := Color.WHITE
	var arrival_color := Color.WHITE
	if is_instance_valid(source):
		source_center = source.global_position
		if source.has_method("get_effect_color"):
			source_color = source.call("get_effect_color")
		if source.has_method("play_travel_effect"):
			source.call("play_travel_effect", false)
	if is_instance_valid(destination):
		if destination.has_method("get_effect_color"):
			arrival_color = destination.call("get_effect_color")
		if destination.has_method("play_travel_effect"):
			destination.call("play_travel_effect", true)
	# Nếu nước/lỗ đã nhận bóng trong cùng frame, để hiệu ứng đó giữ quyền điều khiển Sprite.
	if portal_effects_enabled and not is_in_water and not is_sunk:
		_portal_visual.play(departure_transform, source_center,
			source_color, arrival_color, portal_effect_duration)

## Hủy một yêu cầu chưa thực hiện, đồng thời trả khóa cho những cổng vẫn còn tồn tại.
func _cancel_pending_portal_travel() -> void:
	_portal_travel_pending = false
	for reference in [_portal_source, _portal_destination]:
		if reference == null:
			continue
		var portal := reference.get_ref() as Node
		if is_instance_valid(portal) and portal.has_method("_forget_ball"):
			portal.call("_forget_ball", self)
	_portal_source = null
	_portal_destination = null

## Giảm khóa cổng và khóa từng bumper theo giây thực của bước vật lý.
func _update_mechanism_cooldowns(delta: float) -> void:
	_portal_cooldown_remaining = maxf(_portal_cooldown_remaining - delta, 0.0)
	# keys() tạo danh sách riêng, nên có thể xóa phần tử hết hạn ngay trong vòng lặp.
	for bumper_id in _bumper_cooldowns.keys():
		var remaining := float(_bumper_cooldowns[bumper_id]) - delta
		if remaining <= 0.0:
			_bumper_cooldowns.erase(bumper_id)
		else:
			_bumper_cooldowns[bumper_id] = remaining

## Dùng pháp tuyến tiếp xúc thật để bóng bật đúng cạnh tròn/tam giác, không đẩy theo tâm ảnh.
func _apply_bumper_bounce(state: PhysicsDirectBodyState2D) -> void:
	var touching_now: Dictionary = {}
	var selected: Node = null
	var selected_normal := Vector2.ZERO
	var selected_incoming := Vector2.ZERO
	var strongest_impact := 0.0
	for index in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(index) as Node
		if not is_instance_valid(collider) or not collider.is_in_group("golf_bumpers"):
			continue
		var bumper_id := collider.get_instance_id()
		touching_now[bumper_id] = true
		# Bỏ tiếp xúc cũ hoặc đang bị khóa; vật liệu vẫn giải va chạm thông thường.
		if _bumper_contacts.has(bumper_id) or _bumper_cooldowns.has(bumper_id):
			continue
		if not collider.has_method("get_bounce_velocity"):
			continue
		var normal := state.transform.basis_xform(state.get_contact_local_normal(index)).normalized()
		var incoming := state.linear_velocity
		# Bộ giải có thể đã phản xạ vận tốc trước callback này; mẫu bước trước giữ hướng đi vào.
		if _previous_motion_velocity.dot(normal) < 0.0:
			incoming = _previous_motion_velocity
		# Chỉ tăng lực khi bóng thật sự tiến vào mặt bumper, không kích hoạt khi đứng tựa/rời xa.
		var impact := -incoming.dot(normal)
		if impact > strongest_impact:
			strongest_impact = impact
			selected = collider
			selected_normal = normal
			selected_incoming = incoming
	# Chỉ giữ khóa của những bumper ĐÃ bật và vẫn đang chạm. Một bóng đứng tựa vào bumper
	# vẫn phải nhận được cú bật khi người chơi đánh nó tiến vào mặt vật cản sau đó.
	for bumper_id in _bumper_contacts.keys():
		if not touching_now.has(bumper_id):
			_bumper_contacts.erase(bumper_id)
	if selected == null:
		return
	state.linear_velocity = selected.call("get_bounce_velocity", selected_incoming, selected_normal)
	_bumper_contacts[selected.get_instance_id()] = true
	_bumper_cooldowns[selected.get_instance_id()] = maxf(float(selected.get("cooldown_seconds")), 0.01)
	# Phản hồi hình ảnh hoãn tới lúc an toàn; phần tăng lực đã được áp dụng ngay ở trên.
	if selected.has_method("play_hit_effect"):
		selected.call_deferred("play_hit_effect")

## Cho bóng lăn vào giữa quãng đường xuyên tile rồi mới điều hướng, vẫn đi xuyên được.
func _apply_arrow_direction(state: PhysicsDirectBodyState2D) -> void:
	# Lấy đoạn đường vừa đi trong thế giới, không dự đoán trước vị trí của bước kế tiếp.
	var world_position := state.transform.origin
	var previous_position := world_position
	var previous_was_guiding := _has_previous_arrow_position and _previous_arrow_was_guiding
	if _has_previous_arrow_position:
		previous_position = _previous_arrow_position
	# Luôn cập nhật lịch sử, kể cả trên cỏ/ô trống, để biết bóng đã đi từ đâu vào mũi tên.
	_previous_arrow_position = world_position
	_has_previous_arrow_position = true
	_previous_arrow_was_guiding = false
	# Nếu chưa gán sân hoặc sân chưa có TileSet, bỏ qua điều hướng.
	if not is_instance_valid(surface_tile_map) or surface_tile_map.tile_set == null:
		return
	# Chỉ đọc lớp vẽ đã chọn, giống phần cát/nước; không đọc nhầm chỉ số Custom Data.
	if surface_map_layer < 0 or surface_map_layer >= surface_tile_map.get_layers_count():
		return
	# TileSet chưa tạo arrow_direction thì vẫn chơi bình thường, không báo lỗi đọc dữ liệu.
	if surface_tile_map.tile_set.get_custom_data_layer_by_name(ARROW_DATA_NAME) < 0:
		return
	# Lấy độ lớn vận tốc ngay lúc điều hướng, không dùng max_shot_speed để tránh tăng lực.
	var speed := state.linear_velocity.length()
	# Không đặt ngưỡng tốc độ tối thiểu: chậm bao nhiêu vẫn nhận; bóng đứng yên không tự tăng lực.
	if speed == 0.0:
		return
	# Dùng toàn bề ngang ô, kể cả đường đi lệch tâm; không bắt bóng chạm đúng một điểm nhỏ.
	# Bóng phải lăn đến nửa quãng đường xuyên ô trước khi rẽ, nên có thể đè lên mũi tên.
	# Chỉ đổi vận tốc; vị trí bóng tiếp tục do vật lý xử lý, không bị kéo hoặc chặn ở mép.
	var cell := surface_tile_map.local_to_map(surface_tile_map.to_local(world_position))
	var previous_cell := surface_tile_map.local_to_map(surface_tile_map.to_local(previous_position))
	var tile_direction := _get_arrow_direction_at_cell(cell)
	if tile_direction != Vector2.ZERO:
		# Sau lần rẽ đầu, giữ đúng hướng khi còn trong cùng ô; không tính lại điểm giữa
		# theo hướng mới vì như vậy có thể khiến bóng rẽ qua lại ngay trên mũi tên.
		var already_guiding := previous_was_guiding and previous_cell == cell
		var turn_distance := _get_arrow_turn_distance(cell, previous_position,
			world_position, state.linear_velocity)
		if already_guiding or turn_distance < INF:
			state.linear_velocity = surface_tile_map.global_transform.basis_xform(tile_direction).normalized() * speed
			_previous_arrow_was_guiding = true
			return
	# Kiểm tra cả đoạn vừa đi để nhận được điểm rẽ khi bóng nhanh vượt nguyên ô trong một bước.
	# Hai đầu đoạn đường đổi về local tạo vùng ô cần xét, vẫn đúng khi cả sân được xoay.
	var min_x := mini(previous_cell.x, cell.x)
	var max_x := maxi(previous_cell.x, cell.x)
	var min_y := mini(previous_cell.y, cell.y)
	var max_y := maxi(previous_cell.y, cell.y)
	# ZERO nghĩa là chưa có hướng mới; INF để so sánh và chọn điểm rẽ gần đầu đoạn đường nhất.
	var direction := Vector2.ZERO
	var nearest_distance := INF
	var current_direction := state.linear_velocity.normalized()
	for cell_x in range(min_x, max_x + 1):
		for cell_y in range(min_y, max_y + 1):
			var candidate := Vector2i(cell_x, cell_y)
			# Ô ở đầu đoạn đã được xử lý trước đó thì không ép lại sau khi bóng rời ô.
			# Điều này cũng ngăn mũi tên cũ giành hướng của mũi tên liền kề vừa đi vào.
			if previous_was_guiding and candidate == previous_cell:
				continue
			var candidate_direction := _get_arrow_direction_at_cell(candidate)
			if candidate_direction == Vector2.ZERO:
				continue
			var world_direction := surface_tile_map.global_transform.basis_xform(candidate_direction).normalized()
			# Đã đi đúng hướng thì không cần đổi; vẫn xét tiếp để mũi tên mới phía sau có thể rẽ bóng.
			if world_direction.is_equal_approx(current_direction):
				continue
			# Chỉ nhận khi đã qua điểm giữa của đường xuyên tile, không nhận ngay tại mép ô.
			var distance_from_start := _get_arrow_turn_distance(candidate, previous_position,
				world_position, state.linear_velocity)
			if distance_from_start < nearest_distance:
				nearest_distance = distance_from_start
				direction = world_direction
	if direction == Vector2.ZERO:
		return
	# Hướng đã chuẩn hóa nhân tốc độ hiện tại: chỉ rẽ, không tăng tốc, không cộng gậy hay nhảy vị trí.
	# Bóng có thể đã vượt hẳn ô trong bước nhanh này; vẫn nhận được hướng của ô vừa đi xuyên.
	state.linear_velocity = direction * speed

## Khoảng cách bình phương tới điểm rẽ giữa đường xuyên ô; INF nếu bóng chưa tới đó.
func _get_arrow_turn_distance(cell: Vector2i, segment_start: Vector2,
		segment_end: Vector2, velocity: Vector2) -> float:
	# Hướng của đoạn vừa đi cho biết bóng đang lăn vào từ phía nào, kể cả đường chéo.
	# Nếu chưa có dịch chuyển (vừa đánh từ trong ô), dùng hướng cú đánh để tìm điểm rẽ.
	var movement := segment_end - segment_start
	var travel_direction := movement.normalized() if movement != Vector2.ZERO else velocity.normalized()
	if travel_direction == Vector2.ZERO:
		return INF
	# Tính trong local của TileMap để hình chữ nhật vẫn đúng khi sân xoay hoặc phóng to.
	# Không chuẩn hóa local_direction: tham số dọc đường vẫn tính bằng pixel thế giới.
	var local_start := surface_tile_map.to_local(segment_start)
	var local_direction := surface_tile_map.global_transform.affine_inverse().basis_xform(travel_direction)
	var center := surface_tile_map.map_to_local(cell)
	var half_size := Vector2(surface_tile_map.tile_set.tile_size) * 0.5
	var minimum := center - half_size
	var maximum := center + half_size
	# Cắt đường thẳng với hai dải X/Y của tile để tìm điểm vào và điểm ra trên cùng đường.
	# Dùng đường thẳng kéo dài vì đoạn của một bước chậm có thể chưa đi tới cạnh đối diện.
	var entry_distance := -INF
	var exit_distance := INF
	for axis in range(2):
		if is_zero_approx(local_direction[axis]):
			# Đi song song cạnh: nằm ngoài dải này thì không thể đi xuyên tile đó.
			if local_start[axis] < minimum[axis] or local_start[axis] > maximum[axis]:
				return INF
			continue
		var first_edge := (minimum[axis] - local_start[axis]) / local_direction[axis]
		var second_edge := (maximum[axis] - local_start[axis]) / local_direction[axis]
		entry_distance = maxf(entry_distance, minf(first_edge, second_edge))
		exit_distance = minf(exit_distance, maxf(first_edge, second_edge))
		if entry_distance > exit_distance:
			return INF
	# Chỉ sượt qua đúng một góc không có quãng đường nằm trong ô để lăn đè lên mũi tên.
	if exit_distance - entry_distance <= 0.0001:
		return INF
	var segment_length := movement.length()
	# Không nhận ô nằm hoàn toàn sau lưng hoặc vẫn ở phía trước đoạn bóng thực sự đã đi.
	if exit_distance < 0.0 or entry_distance > segment_length:
		return INF
	# Đi được nửa đường từ cạnh vào tới cạnh ra mới rẽ. Với tile 16px, đi ngang cần vào 8px.
	# Đường lệch tâm/đường chéo cũng có điểm giữa riêng, nên không cần đi đúng tâm hình mũi tên.
	var turn_distance := (entry_distance + exit_distance) * 0.5
	if turn_distance > segment_length + 0.0001:
		return INF
	# Bắt đầu ở nửa sau của ô nghĩa là đã đè lên mũi tên rồi, có thể nhận hướng ngay.
	return pow(maxf(turn_distance, 0.0), 2.0)

## Đọc hướng local của một ô; chỉ gọi sau khi đã xác nhận TileMap và Custom Data tồn tại.
func _get_arrow_direction_at_cell(cell: Vector2i) -> Vector2:
	var tile_data := surface_tile_map.get_cell_tile_data(surface_map_layer, cell)
	# Ô trống không có dữ liệu mũi tên.
	if tile_data == null:
		return Vector2.ZERO
	# Các vector đều dài 1: X phải dương, Y xuống dương, giống hướng của hình trên sân.
	match str(tile_data.get_custom_data(ARROW_DATA_NAME)):
		"right":
			return Vector2.RIGHT
		"left":
			return Vector2.LEFT
		"down":
			return Vector2.DOWN
		"up":
			return Vector2.UP
	# Nhãn trống hoặc không hợp lệ được coi như ô bình thường.
	return Vector2.ZERO

## Đọc nhãn "sand"/"water" của ô tại vị trí được truyền vào. Trả rỗng nếu thiếu dữ liệu.
func _get_surface_at(world_position: Vector2) -> String:
	# Chưa có TileMap/TileSet thì vẫn cho bóng lăn với mức giảm tốc mặc định.
	if not is_instance_valid(surface_tile_map) or surface_tile_map.tile_set == null:
		return ""
	# Bảo đảm chỉ số lớp vẽ nằm trong các lớp đang có của TileMap.
	if surface_map_layer < 0 or surface_map_layer >= surface_tile_map.get_layers_count():
		return ""
	# Kiểm tra tên Custom Data trước khi đọc để tránh lỗi khi TileSet chưa gắn nhãn.
	if surface_tile_map.tile_set.get_custom_data_layer_by_name(SURFACE_DATA_NAME) < 0:
		return ""
	# Thế giới -> tọa độ local của TileMap -> tọa độ ô lưới.
	# Cách đổi này vẫn đúng khi TileMap được di chuyển, xoay hoặc phóng to.
	var cell := surface_tile_map.local_to_map(surface_tile_map.to_local(world_position))
	# Đọc TileData của đúng lớp vẽ; dữ liệu này chứa Custom Data gắn trên tile của TileSet.
	var tile_data := surface_tile_map.get_cell_tile_data(surface_map_layer, cell)
	# Ô chưa được vẽ tile không có TileData để đọc.
	if tile_data == null:
		return ""
	# Giá trị phải khớp chính xác, có phân biệt hoa/thường: sand hoặc water.
	# str(...) đưa dữ liệu về chuỗi để so sánh; nhãn trống/khác sẽ dùng giảm tốc mặc định.
	return str(tile_data.get_custom_data(SURFACE_DATA_NAME))

## Chỉ cho chìm khi tâm và các điểm xung quanh đều đã nằm trong vùng nước.
func _is_deep_enough_in_water(world_position: Vector2) -> bool:
	# Chặn giá trị âm nếu thông số được thay đổi bằng script ngoài giới hạn Inspector.
	var depth := maxf(water_entry_depth, 0.0)
	# Đặt 0 để chìm ngay khi tâm vừa vào ô nước, giống cách xử lý ban đầu.
	# Hàm này chỉ được gọi sau khi đã xác nhận ô tại tâm có nhãn water.
	if is_zero_approx(depth):
		return true
	# Tra cả những ô lân cận để mép nối giữa hai tile nước không bị coi là bờ.
	# Kiểm tra thêm các góc để bóng không chìm quá sớm khi đi chéo vào vùng nước.
	# Hai vòng lặp tạo 9 điểm: tâm, 4 điểm theo các cạnh và 4 điểm ở các góc.
	# Với depth = 5, mỗi tọa độ lệch so với tâm là -5, 0 hoặc +5 pixel thế giới.
	for offset_x in [-depth, 0.0, depth]:
		for offset_y in [-depth, 0.0, depth]:
			# Chỉ một điểm còn ở cỏ, cát hoặc ô trống thì bóng vẫn chưa được chìm.
			if _get_surface_at(world_position + Vector2(offset_x, offset_y)) != "water":
				return false
	# Cả 9 điểm đều nằm trên các tile nước liền nhau: đã đủ sâu để bắt đầu hiệu ứng.
	return true

## Dừng bóng tại chỗ rơi và bắt đầu một lần xử lý nước.
func _begin_water_fall(state: PhysicsDirectBodyState2D) -> void:
	# Dừng tween hiện hình của cổng trước khi nước làm bóng thu nhỏ và mờ dần.
	_portal_visual.cancel()
	# Điểm rơi và điểm hồi không phải một đoạn lăn, nên không được quét mũi tên giữa hai điểm.
	_has_previous_arrow_position = false
	_previous_arrow_was_guiding = false
	_bumper_contacts.clear()
	_bumper_cooldowns.clear()
	_previous_motion_velocity = Vector2.ZERO
	_cancel_pending_portal_travel()
	# Khóa thao tác chuột và để lỗ biết bóng đang thuộc quá trình chìm xuống nước.
	is_in_water = true
	# Một lần chìm mới phải đợi hiệu ứng hoàn tất, không dùng cờ hồi của lần trước.
	_water_respawn_pending = false
	# Xóa cả thao tác ngắm lẫn vận tốc cú đánh chưa được áp dụng.
	_cancel_drag()
	_pending_shot = Vector2.ZERO
	# Dừng cả tịnh tiến và xoay của thân bóng tại điểm bắt đầu chìm.
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	# Tính gậy phạt khi đã vào nước đủ sâu; không tính lại lúc hiệu ứng kết thúc.
	# maxi chặn mức phạt âm; tín hiệu cập nhật bộ đếm gậy trên HUD ngay lập tức.
	stroke_count += maxi(water_penalty_strokes, 0)
	stroke_count_changed.emit(stroke_count)
	# Thêm node hiệu ứng sau bước vật lý, tránh sửa cây scene trong lúc xử lý va chạm.
	_play_water_effect.call_deferred(state.transform.origin)

## Tạo sóng nước tại điểm rơi và làm hình bóng thu nhỏ, hạ thấp, mờ dần.
func _play_water_effect(water_position: Vector2) -> void:
	# Bảo đảm hiệu ứng có ít nhất 0.1 giây để tween không kết thúc ngay lập tức.
	var duration := maxf(water_sink_duration, 0.1)
	# Tạo node từ script hiệu ứng; tên giúp tìm node khi xem scene đang chạy.
	var splash := WATER_SPLASH_EFFECT.new()
	splash.name = "WaterSplash"
	# Sóng tồn tại lâu hơn lúc bóng chìm 0.15 giây để điểm rơi còn gợn sau khi hồi bóng.
	splash.duration = duration + 0.15
	# Vẽ giọt bắn/gợn sóng phía trên hình bóng trong cùng hệ lớp của sân.
	splash.z_index = z_index + 1
	# Đặt hiệu ứng cùng cấp với bóng để sóng ở lại điểm rơi sau khi bóng hồi về.
	get_parent().add_child(splash)
	# water_position là tọa độ thế giới lấy từ bước vật lý, nên gán bằng global_position.
	splash.global_position = water_position
	# Tween chạy theo nhịp vật lý; set_parallel cho 3 thuộc tính đổi cùng lúc.
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel(true)
	# Đường cong bậc hai EASE_IN: bắt đầu chậm rồi chìm nhanh dần về cuối hiệu ứng.
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Thu Sprite2D còn 10% kích thước gốc; hình va chạm của thân bóng không bị thu theo.
	tween.tween_property($Sprite2D, "scale", _sprite_rest_scale * 0.1, duration)
	# Hạ riêng hình ảnh 3 pixel để tạo chiều sâu; khác với ngưỡng đi vào nước 5 pixel.
	tween.tween_property($Sprite2D, "position", _sprite_rest_position + Vector2(0, 3), duration)
	# Nhuộm xanh nhẹ và giảm alpha về 0; nhân màu gốc để giữ đúng tông ban đầu của bóng.
	tween.tween_property($Sprite2D, "modulate", _sprite_rest_modulate * Color(0.4, 0.75, 1, 0), duration)
	# Khi cả 3 chuyển đổi xong mới bật cờ hồi bóng; callback không tự đổi vị trí thân bóng.
	tween.finished.connect(_finish_water_effect)

## Báo cho bước vật lý hồi bóng sau khi người chơi đã nhìn thấy hiệu ứng chìm.
func _finish_water_effect() -> void:
	# _integrate_forces sẽ đọc cờ này ở bước vật lý tiếp theo để hồi bóng an toàn.
	_water_respawn_pending = true
	# Bóng đứng yên đủ lâu có thể đã ngủ; đánh thức để bước vật lý nhận cờ hồi bóng.
	sleeping = false

## Hồi bóng sau hiệu ứng nước, khôi phục hình ảnh và cho phép đánh tiếp khi về ô an toàn.
func _reset_from_water(state: PhysicsDirectBodyState2D) -> void:
	# Bắt đầu lại lịch sử đường lăn ở điểm hồi, không dùng đoạn đường trước khi chìm.
	_has_previous_arrow_position = false
	_previous_arrow_was_guiding = false
	_bumper_contacts.clear()
	_bumper_cooldowns.clear()
	_previous_motion_velocity = Vector2.ZERO
	_cancel_pending_portal_travel()
	# Đổi vị trí ngay trong trạng thái vật lý, giữ nguyên hướng/độ lớn của transform.
	var reset_transform := state.transform
	# Chỉ thay điểm đặt thân bóng bằng vị trí đã lưu trước cú đánh, không phải điểm rơi.
	reset_transform.origin = _shot_start_position
	state.transform = reset_transform
	# Hồi bóng là dịch chuyển tức thời, không phải quãng đường lăn để xoay các chấm.
	_roll_visual.reset_motion(state.transform.origin)
	# Bóng hồi về phải đứng yên để người chơi có thể thực hiện cú đánh tiếp theo.
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	# Trả lại đủ kích thước, độ lệch và màu/alpha để bóng xuất hiện bình thường sau khi hồi.
	$Sprite2D.scale = _sprite_rest_scale
	$Sprite2D.position = _sprite_rest_position
	$Sprite2D.modulate = _sprite_rest_modulate
	# Kết thúc trạng thái hiệu ứng và xóa yêu cầu hồi đã được xử lý.
	is_in_water = false
	_water_respawn_pending = false
	# Giữ _was_in_water đến bước kiểm tra bề mặt tiếp theo, tránh lặp phạt nếu điểm hồi là nước sâu.

## Được gọi từ script của lỗ khi bóng đủ điều kiện rơi vào miệng lỗ.
func sink_into_hole(hole_position: Vector2) -> void:
	# Chặn xử lý vào lỗ nhiều lần và chặn tween của lỗ giành Sprite2D khi bóng đang chìm.
	if is_sunk or is_in_water:
		return
	# Hủy tween cổng để bóng đã lọt lỗ không bị phóng to/hiện lại giữa chừng.
	_portal_visual.cancel()
	is_sunk = true
	# Vào lỗ kết thúc lượt bóng; không để một yêu cầu cổng cũ giữ khóa các cổng còn sống.
	_cancel_pending_portal_travel()
	_cancel_drag()
	_pending_shot = Vector2.ZERO
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	# Hoãn việc đóng băng/tắt va chạm đến lúc Godot có thể cập nhật vật lý an toàn.
	set_deferred("freeze", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	# Hai hiệu ứng chạy đồng thời: kéo bóng về tâm lỗ và thu nhỏ hình bóng.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", hole_position, 0.2)
	tween.tween_property($Sprite2D, "scale", Vector2.ZERO, 0.25)

## Vẽ gợi ý thao tác trong tọa độ local của bóng khi đang kéo đủ xa.
func _draw() -> void:
	if _is_dragging and _drag_offset.length() >= MIN_DRAG_DISTANCE:
		# Vạch và chấm vàng biểu diễn hướng người chơi đang kéo về phía sau.
		var pull_end := to_local(global_position + _drag_offset)
		draw_line(Vector2.ZERO, pull_end, Color.YELLOW, 1.0, true)
		draw_circle(pull_end, 1.5, Color.YELLOW)
		# Vạch trắng chỉ hướng bóng sẽ đi, không phải quỹ đạo hay điểm dừng dự đoán.
		var aim_end := to_local(global_position - _drag_offset * 0.5)
		draw_line(Vector2.ZERO, aim_end, Color.WHITE, 1.0, true)
