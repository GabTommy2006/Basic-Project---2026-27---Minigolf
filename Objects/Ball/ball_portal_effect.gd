# Chỉ điều khiển hình bóng khi qua cổng; không sửa thân vật lý, vận tốc hoặc số gậy.
# Ảnh dư ở nguồn tự thu vào tâm cổng, còn Sprite2D thật hiện dần ở vị trí đầu ra.
extends Node

# Sprite thật và các giá trị gốc được lưu trước khi bất kỳ hiệu ứng nào bắt đầu.
var _sprite: Sprite2D
var _rest_scale := Vector2.ONE
var _rest_position := Vector2.ZERO
var _rest_modulate := Color.WHITE
# Giữ tween để có thể hủy ngay khi nước/lỗ cần tiếp quản hình bóng.
var _arrival_tween: Tween

## Gọi một lần từ Ball._ready; không thêm collider hoặc thay đổi cấu trúc Sprite2D.
func setup(sprite: Sprite2D) -> void:
	_sprite = sprite
	_rest_scale = sprite.scale
	_rest_position = sprite.position
	_rest_modulate = sprite.modulate

## Tạo hiệu ứng hai đầu sau khi bước vật lý đã dịch chuyển thành công.
## departure_transform được chụp tại vị trí cũ, nên ảnh dư không nhảy theo bóng thật.
func play(departure_transform: Transform2D, source_center: Vector2,
		source_color: Color, arrival_color: Color, duration: float) -> void:
	if not is_instance_valid(_sprite):
		return
	# Một lượt mới thay lượt cũ, tránh hai tween cùng ghi scale/modulate lên Sprite2D.
	cancel()
	var safe_duration := clampf(duration, 0.05, 0.5)
	_spawn_departure_echo(departure_transform, source_center, source_color, safe_duration)
	# Chỉ thu nhỏ hình ảnh. Collider của bóng vẫn giữ nguyên bán kính và tiếp tục lăn.
	_sprite.scale = _rest_scale * 0.25
	_sprite.modulate = _rest_modulate * Color(arrival_color.lightened(0.65), 0.3)
	_arrival_tween = create_tween().set_parallel(true)
	_arrival_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_arrival_tween.tween_property(_sprite, "scale", _rest_scale, safe_duration)
	_arrival_tween.tween_property(_sprite, "modulate", _rest_modulate, safe_duration)

## Tạo Sprite tạm cùng cấp với bóng, để ảnh nguồn ở lại sân sau khi bóng đi xa.
## Dùng lại đúng texture/frame của bóng; ảnh dư hoàn toàn không có va chạm hay script đánh bóng.
func _spawn_departure_echo(departure_transform: Transform2D, source_center: Vector2,
		effect_color: Color, duration: float) -> void:
	var ball := get_parent() as Node2D
	if ball == null or ball.get_parent() == null:
		return
	var echo := Sprite2D.new()
	echo.name = "PortalBallEcho"
	echo.add_to_group("portal_ball_echoes")
	echo.texture = _sprite.texture
	echo.texture_filter = _sprite.texture_filter
	echo.centered = _sprite.centered
	echo.offset = _sprite.offset
	echo.hframes = _sprite.hframes
	echo.vframes = _sprite.vframes
	echo.frame = _sprite.frame
	echo.region_enabled = _sprite.region_enabled
	echo.region_rect = _sprite.region_rect
	echo.flip_h = _sprite.flip_h
	echo.flip_v = _sprite.flip_v
	echo.z_index = ball.z_index + _sprite.z_index + 1
	ball.get_parent().add_child(echo)
	echo.global_transform = departure_transform
	echo.modulate = _rest_modulate * Color(effect_color.lightened(0.7), 0.9)
	# Tween gắn vào ảnh dư: khi sân bị xóa, cả ảnh lẫn tween được dọn cùng nhau.
	var echo_tween := echo.create_tween().set_parallel(true)
	echo_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	echo_tween.tween_property(echo, "global_position", source_center, duration)
	echo_tween.tween_property(echo, "scale", echo.scale * 0.05, duration)
	echo_tween.tween_property(echo, "modulate:a", 0.0, duration)
	echo_tween.chain().tween_callback(echo.queue_free)

## Cho biết Sprite còn đang hiện dần; hữu ích khi kiểm tra hiệu ứng trong scene chạy.
func is_playing() -> bool:
	return _arrival_tween != null and _arrival_tween.is_running()

## Nước/lỗ gọi trước khi tạo tween riêng, tránh bị tween cổng làm bóng hiện lại về sau.
## Khôi phục ngay để hiệu ứng kế tiếp luôn bắt đầu từ hình bóng đủ kích thước và đúng màu.
func cancel() -> void:
	if _arrival_tween != null:
		_arrival_tween.kill()
		_arrival_tween = null
	if is_instance_valid(_sprite):
		_sprite.scale = _rest_scale
		_sprite.position = _rest_position
		_sprite.modulate = _rest_modulate
