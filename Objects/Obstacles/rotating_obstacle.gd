# Thanh/vật cản xám quay có va chạm thật, dùng chung cho các hình trong SummerTile.
extends AnimatableBody2D

## Tốc độ quay, tính bằng độ/giây. Đặt 0 để giữ vật cản đứng yên.
@export_range(0.0, 720.0, 1.0) var angular_speed_degrees: float = 90.0
## Trong hệ 2D của Godot, góc dương quay theo chiều kim đồng hồ.
@export var clockwise: bool = true
## Tắt để dừng quay tại góc hiện tại; vật cản vẫn còn hình ảnh và va chạm.
@export var enabled: bool = true

## Đồng bộ chuyển động với vật lý để thanh quay có thể đẩy hoặc làm bật bóng.
func _ready() -> void:
	sync_to_physics = true

## Quay cả thân va chạm và sprite cùng lúc, không chỉ xoay hình ảnh trang trí.
func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var direction := 1.0 if clockwise else -1.0
	rotation += deg_to_rad(maxf(angular_speed_degrees, 0.0)) * direction * delta
