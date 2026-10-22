# Vật cản chạy qua lại giữa điểm đặt scene và Marker2D EndPoint.
# Body và EndPoint là hai node cùng cấp: đích không bị kéo chạy theo thân vật lý.
extends Node2D

## Thời gian đi một chiều từ đầu này tới đầu kia, tính bằng giây.
@export_range(0.05, 30.0, 0.05) var travel_duration: float = 1.5
## Thời gian dừng ở mỗi đầu trước khi quay lại, tính bằng giây.
@export_range(0.0, 10.0, 0.05) var pause_duration: float = 0.35
## Đợi từng này giây ở điểm đầu trước khi bắt đầu chạy.
@export_range(0.0, 30.0, 0.05) var start_delay: float = 0.0
## Tắt để giữ vật cản tại vị trí hiện tại; bật lại để tiếp tục hành trình.
@export var enabled: bool = true

# Hai đầu được biểu diễn trong hệ local của scene, nên xoay/di chuyển scene vẫn đúng đường.
var _start_position := Vector2.ZERO
var _elapsed: float = 0.0
var _pause_remaining: float = 0.0
var _towards_end: bool = true

@onready var _body: AnimatableBody2D = $Body
@onready var _end_point: Marker2D = $EndPoint

## Ghi nhớ điểm đầu và để Godot tính vận tốc của thân đang chuyển động.
func _ready() -> void:
	_start_position = _body.position
	_pause_remaining = maxf(start_delay, 0.0)
	_body.sync_to_physics = true

## Di chuyển chính collider trong nhịp vật lý để có thể đẩy hoặc làm bật bóng.
func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if _pause_remaining > 0.0:
		_pause_remaining = maxf(_pause_remaining - delta, 0.0)
		return
	_elapsed += delta
	var progress := minf(_elapsed / maxf(travel_duration, 0.05), 1.0)
	# Kéo EndPoint trong editor để đổi hướng/độ dài đường đi; thân bắt đầu tại vị trí Body.
	var from := _start_position if _towards_end else _end_point.position
	var to := _end_point.position if _towards_end else _start_position
	_body.position = from.lerp(to, progress)
	if progress >= 1.0:
		# Chạm đúng đầu đường rồi dừng trước khi đổi chiều, không cộng dồn sai lệch vị trí.
		_elapsed = 0.0
		_towards_end = not _towards_end
		_pause_remaining = maxf(pause_duration, 0.0)
