# Cổng vàng mờ dần và co nhẹ khi hiện/ẩn; chỉ pha hiện đủ mới chặn bóng.
extends StaticBody2D

## Thời gian cổng hiện đủ và chặn bóng, không tính thời gian chuyển tiếp, đơn vị giây.
@export_range(0.05, 30.0, 0.05) var visible_duration: float = 1.5
## Thời gian cổng ẩn hẳn, không tính thời gian chuyển tiếp, đơn vị giây.
@export_range(0.05, 30.0, 0.05) var hidden_duration: float = 1.0
## Thời gian cho mỗi lượt mờ ra hoặc hiện vào; chỉ thay hình ảnh, không bóp collider.
@export_range(0.05, 2.0, 0.05) var fade_duration: float = 0.2
## Bật để bắt đầu ẩn; tắt để hiện dần ngay khi vùng đóng cổng đã trống.
@export var start_hidden: bool = false
## Giữ pha ổn định đầu tiên thêm từng này giây: ẩn hẳn hoặc đã hiện đủ.
@export_range(0.0, 30.0, 0.05) var start_delay: float = 0.0

# Bốn pha giúp phân biệt cửa còn thấy trong lúc mờ với cửa đang thực sự chặn bóng.
enum GatePhase { HIDDEN, FADING_IN, SOLID, FADING_OUT }
# Chỉ true khi đã ẩn hẳn; trong hai pha chuyển tiếp, cửa vẫn có thể còn thấy trên sân.
var is_hidden: bool = true
# Chỉ true sau khi đã hiện đủ và collider đã được bật an toàn trong callback deferred.
var is_solid: bool = false
# Pha hiện tại dùng để quan sát khi chạy; không gán trực tiếp từ script khác.
var phase: GatePhase = GatePhase.HIDDEN

# Mức hiện tuyến tính 0..1; alpha/scale dùng đường cong mềm khi vẽ.
var _visibility: float = 0.0
# Hai thời gian giữ pha không bao gồm fade; độ trễ đầu chỉ được dùng một lần.
var _remaining: float = 0.0
var _initial_visible_delay: float = 0.0
# Tránh chạy logic trước khi collider khởi tạo an toàn và tránh xếp nhiều callback trùng nhau.
var _initialized: bool = false
var _transition_pending: bool = false
# Giữ màu và kích thước Sprite2D để hiệu ứng chỉ đổi phần hiển thị rồi trả đúng trạng thái gốc.
var _rest_modulate := Color.WHITE
var _rest_scale := Vector2.ONE

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _glow: Sprite2D = $Sprite2D/Glow
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var _clearance: CollisionShape2D = $Clearance/CollisionShape2D

## Lưu hình gốc rồi mở cổng ngoài bước giải va chạm để không kẹp bóng ngay lúc tải scene.
func _ready() -> void:
	_rest_modulate = _sprite.modulate
	_rest_scale = _sprite.scale
	_initialize_gate.call_deferred()

## Khởi đầu ẩn và không chặn; nếu chọn bắt đầu hiện thì lần kiểm tra sau sẽ chạy fade-in.
func _initialize_gate() -> void:
	_collider.disabled = true
	_enter_hidden()
	if start_hidden:
		_remaining += maxf(start_delay, 0.0)
	else:
		_remaining = 0.0
		_initial_visible_delay = maxf(start_delay, 0.0)
	_initialized = true

## Chạy hiệu ứng trong nhịp vật lý; collider luôn tắt khi sprite chưa hiện đủ.
func _physics_process(delta: float) -> void:
	if not _initialized or _transition_pending:
		return
	match phase:
		GatePhase.HIDDEN:
			_remaining = maxf(_remaining - delta, 0.0)
			# Nếu bóng còn nằm ở chỗ cổng, tiếp tục ẩn thay vì hiện lên bao quanh bóng.
			if _remaining <= 0.0 and _can_close():
				phase = GatePhase.FADING_IN
				is_hidden = false
		GatePhase.FADING_IN:
			# Bóng được đi qua lúc cửa còn mờ. Nếu bóng vào giữa chừng, đảo sang mờ ra.
			if not _can_close():
				_request_fade_out()
				return
			_visibility = minf(_visibility + delta / maxf(fade_duration, 0.01), 1.0)
			_render_visual()
			if _visibility >= 1.0:
				_transition_pending = true
				_commit_solid.call_deferred()
		GatePhase.SOLID:
			_remaining -= delta
			# Chớp sáng mềm một lần trước lúc biến mất; alpha vẫn đầy đủ nên không chặn vô hình.
			var warning_window := minf(0.16, maxf(visible_duration, 0.05) * 0.5)
			var warning_progress := clampf(1.0 - _remaining / warning_window, 0.0, 1.0)
			_render_visual(sin(warning_progress * PI) * 0.8)
			if _remaining <= 0.0:
				_request_fade_out()
		GatePhase.FADING_OUT:
			_visibility = maxf(_visibility - delta / maxf(fade_duration, 0.01), 0.0)
			_render_visual()
			if _visibility <= 0.0:
				_enter_hidden()

## Ghi nhận pha ẩn hẳn sau khi hình đã mờ hết; collider đã được tắt từ đầu fade-out.
func _enter_hidden() -> void:
	phase = GatePhase.HIDDEN
	is_hidden = true
	is_solid = false
	_visibility = 0.0
	_remaining = maxf(hidden_duration, 0.05)
	_render_visual()

## Tắt collider trước, rồi mới cho bước kế tiếp bắt đầu giảm alpha và bóp hình.
func _request_fade_out() -> void:
	if _transition_pending:
		return
	_transition_pending = true
	_commit_fade_out.call_deferred()

## Callback deferred đổi va chạm an toàn; không có frame hình đã mờ mà collider còn bật.
func _commit_fade_out() -> void:
	_transition_pending = false
	_collider.disabled = true
	is_solid = false
	is_hidden = false
	phase = GatePhase.FADING_OUT
	_render_visual()

## Chỉ đóng khi alpha/scale đã trở về đủ và kiểm tra lại rằng không kẹp bóng.
func _commit_solid() -> void:
	_transition_pending = false
	if phase != GatePhase.FADING_IN:
		return
	if not _can_close():
		_request_fade_out()
		return
	_collider.disabled = false
	is_solid = true
	is_hidden = false
	phase = GatePhase.SOLID
	_remaining = maxf(visible_duration, 0.05) + _initial_visible_delay
	_initial_visible_delay = 0.0

## Alpha, co nhẹ và quầng sáng đều nằm dưới Sprite2D, không đổi kích thước va chạm.
func _render_visual(warning: float = 0.0) -> void:
	var eased := smoothstep(0.0, 1.0, _visibility)
	var glow_strength := maxf(warning, sin(_visibility * PI) * 0.6)
	_sprite.visible = _visibility > 0.0
	_sprite.scale = _rest_scale * Vector2(lerpf(0.94, 1.0, eased), lerpf(0.55, 1.0, eased))
	_sprite.modulate = _rest_modulate * Color(1.0 + glow_strength * 0.45,
		1.0 + glow_strength * 0.3, 1.0, eased)
	# Dùng lại hình cổng đã phóng nhẹ, vẽ phía sau thanh chính; không cần ảnh hoặc shader mới.
	_glow.visible = glow_strength > 0.01
	_glow.modulate = Color(1.0, 0.9, 0.35, glow_strength * 0.55)

## Hỏi trực tiếp không gian vật lý, tránh dùng danh sách overlap cũ của Area2D lúc vừa tải.
func _can_close() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _clearance.shape
	query.transform = _clearance.global_transform
	query.collision_mask = $Clearance.collision_mask
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	# Clearance lớn hơn hình cổng 1 pixel mỗi phía, cộng thêm chút dư để không kẹp mép bóng.
	query.margin = 0.2
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var body = hit.get("collider")
		if body is RigidBody2D or body is CharacterBody2D:
			return false
	return true
