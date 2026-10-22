# Sân thử riêng gồm năm khu: không thay bố cục hay scene chính TestBeta của người chơi.
# Mỗi khu có bóng riêng để thử cơ chế bằng thao tác kéo/thả bình thường.
extends Node2D

## R đặt lại toàn sân để thử tiếp sau khi bóng đã vào lỗ hoặc bị đánh ra xa.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		# Đánh dấu đã xử lý để các script lỗ không cùng nhận R và tải scene nhiều lần.
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
