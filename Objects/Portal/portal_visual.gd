# Lớp hình ảnh phủ nhẹ lên cổng: xoáy khi chờ, lóe vòng/tia lúc bóng thật sự qua cổng.
# Không đổi Sprite2D gốc, transform cổng, vùng nhận hoặc bất kỳ trạng thái vật lý nào.
extends Node2D

## Màu chính của hiệu ứng. Hai scene cổng đặt màu cam/xanh theo bảng màu SummerTile.
@export var effect_color: Color = Color(0.976471, 0.45098, 0.0862745, 1.0):
	set(value):
		effect_color = value
		_refresh_processing()
## Tắt toàn bộ hình hiệu ứng, gồm cả xoáy chờ và lóe dịch chuyển; cổng vẫn hoạt động.
@export var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		if not effects_enabled:
			# Không tiếp tục một lần lóe cũ khi người chơi bật lại hiệu ứng sau đó.
			_travel_active = false
			_travel_elapsed = 0.0
		_refresh_processing()
## Chỉ tắt xoáy chờ; hiệu ứng khi bóng dịch chuyển vẫn chạy nếu effects_enabled bật.
@export var ambient_enabled: bool = true:
	set(value):
		ambient_enabled = value
		_refresh_processing()

# Mỗi lần lóe kéo dài 0.45 giây; dùng riêng với thời gian chống dịch chuyển lặp của cổng.
const TRAVEL_EFFECT_DURATION := 0.45
# Góc xoay chờ được giữ trong một vòng 0..TAU để số không tăng mãi khi chơi lâu.
var _ambient_phase: float = 0.0
# Chỉ true giữa lúc nhận lời gọi play_travel_effect và lúc kết thúc lần lóe đó.
var _travel_active: bool = false
# Số giây đã chạy của lần lóe hiện tại, không phải thời gian kể từ khi tạo cổng.
var _travel_elapsed: float = 0.0
# true: cổng đích tỏa vòng sáng ra ngoài; false: cổng nguồn thu vòng sáng vào để hút bóng.
var _travel_is_arrival: bool = false

## Bắt đầu xoáy chờ hoặc dừng cập nhật nếu mọi hiệu ứng đang tắt.
func _ready() -> void:
	_refresh_processing()

## Được ball.gd gọi CHỈ sau khi dịch chuyển vật lý thành công.
## arriving phân biệt cổng đích với cổng nguồn; gọi lại sẽ bắt đầu một lần lóe mới.
func play_travel_effect(arriving: bool) -> void:
	if not effects_enabled:
		return
	_travel_is_arrival = arriving
	_travel_elapsed = 0.0
	_travel_active = true
	_refresh_processing()

## Đổi bật/tắt hoặc màu trong lúc chạy cũng phải vẽ lại, không giữ nét cũ trên màn hình.
func _refresh_processing() -> void:
	# Các thuộc tính có thể được gán trước khi node vào scene; _ready sẽ cập nhật lại sau.
	if not is_inside_tree():
		return
	# Không cần chạy _process khi chỉ tắt ambient và không có lần lóe nào đang diễn ra.
	set_process(effects_enabled and (ambient_enabled or _travel_active))
	queue_redraw()

## delta là thời gian giữa hai khung hình vẽ, nên hiệu ứng không phụ thuộc FPS.
func _process(delta: float) -> void:
	# 1.3 radian/giây tạo một vòng xoay chờ khoảng 4.8 giây, tránh xoáy quá nhanh.
	_ambient_phase = fposmod(_ambient_phase + delta * 1.3, TAU)
	if _travel_active:
		_travel_elapsed = minf(_travel_elapsed + delta, TRAVEL_EFFECT_DURATION)
		if _travel_elapsed >= TRAVEL_EFFECT_DURATION:
			_travel_active = false
			_refresh_processing()
	queue_redraw()

## Mọi hình vẽ ở tọa độ local của PortalVisual, đặt tại đúng tâm cổng và không chặn bóng.
func _draw() -> void:
	if not effects_enabled:
		return
	if ambient_enabled:
		_draw_ambient()
	if _travel_active:
		_draw_travel_effect()

## Hai cung ngắn quay đối nhau tạo xoáy nhẹ, để phần ảnh cổng gốc vẫn nhìn rõ.
func _draw_ambient() -> void:
	# Đưa sin từ -1..1 về 0..1; hai nhịp sáng nhỏ trong mỗi vòng xoay.
	var pulse := (sin(_ambient_phase * 2.0) + 1.0) * 0.5
	var radius := 6.8 + pulse * 0.3
	var color := effect_color.lightened(0.2)
	# Alpha chỉ khoảng 12%..24% của màu gốc để xoáy chờ không lấn át sân và quả bóng.
	color.a = effect_color.a * (0.12 + pulse * 0.12)
	for index in range(2):
		var angle := _ambient_phase + float(index) * PI
		# false tắt khử răng cưa; 10 điểm và nét hẹp giữ phong cách pixel ở camera zoom 4.
		draw_arc(Vector2.ZERO, radius, angle, angle + PI * 0.42, 10, color, 0.65, false)

## Vòng sáng và tám tia cùng mờ dần; nguồn thu vào, đích tỏa ra, không di chuyển node cổng.
func _draw_travel_effect() -> void:
	# Chuẩn hóa thời gian về 0..1; fade giảm về 0 ở cuối nên không để lại viền sáng.
	var progress := clampf(_travel_elapsed / TRAVEL_EFFECT_DURATION, 0.0, 1.0)
	var fade := 1.0 - progress
	var radius := lerpf(5.8, 10.8, progress) if _travel_is_arrival else lerpf(10.8, 5.8, progress)
	var ring_color := effect_color.lightened(0.35)
	ring_color.a = effect_color.a * fade * 0.85
	# TAU là một vòng đầy đủ; bán kính chỉ khoảng 5..11 pixel quanh cổng 16x16.
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, ring_color, 0.8, false)
	var inner_color := effect_color
	inner_color.a = effect_color.a * fade * 0.35
	draw_arc(Vector2.ZERO, maxf(5.0, radius - 1.8), 0.0, TAU, 28, inner_color, 0.6, false)
	var ray_color := effect_color.lightened(0.55)
	ray_color.a = effect_color.a * fade * 0.72
	for index in range(8):
		# Tám hướng cách đều nhau; xoay nhẹ theo tiến độ để tia có cảm giác xoắn quanh cổng.
		var spin := progress * 0.5 if _travel_is_arrival else -progress * 0.5
		var angle := TAU * float(index) / 8.0 + spin
		var direction := Vector2(cos(angle), sin(angle))
		var start_radius := lerpf(5.5, 9.2, progress) if _travel_is_arrival else lerpf(10.5, 6.0, progress)
		# Ở đích tia chỉ ra ngoài, ở nguồn tia chỉ vào trong; độ dài cũng giảm theo fade.
		var end_radius := start_radius + 1.3 * fade if _travel_is_arrival else start_radius - 1.3 * fade
		draw_line(direction * start_radius, direction * end_radius, ray_color, 0.8, false)
