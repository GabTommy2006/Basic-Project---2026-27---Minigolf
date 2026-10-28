extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame

func floor_stage() -> Node2D:
	var stage := Node2D.new()
	var map := TileMap.new()
	map.name = "TileMap"
	map.tile_set = load("res://Assets/TileSetSummer.tres")
	for x in range(-2, 8):
		for y in range(-2, 3):
			map.set_cell(0, Vector2i(x, y), 0, Vector2i(1, 4))
	stage.add_child(map)
	root.add_child(stage)
	return stage

func make_ball(stage: Node, position: Vector2):
	var ball = load("res://Objects/Ball/Ball.tscn").instantiate()
	ball.position = position
	stage.add_child(ball)
	return ball

func dispose(stage: Node) -> void:
	stage.queue_free()
	await process_frame

func _run() -> void:
	for config in [[Vector2i(8, 4), Vector2.RIGHT], [Vector2i(9, 4), Vector2.LEFT],
		[Vector2i(8, 5), Vector2.DOWN], [Vector2i(9, 5), Vector2.UP]]:
		var stage := floor_stage()
		stage.get_node("TileMap").set_cell(0, Vector2i.ZERO, 0, config[0])
		var ball = make_ball(stage, Vector2(-0.5, 4))
		ball.rolling_deceleration = 0.0
		ball.linear_velocity = Vector2(60, 0)
		await ticks(3)
		check(ball.linear_velocity.is_equal_approx(Vector2(60, 0)), "Partial entry must not redirect or boost")
		await ticks(5)
		check(ball.linear_velocity.normalized().is_equal_approx(config[1]), "Arrow direction after full-ball entry")
		check(is_equal_approx(ball.linear_velocity.length(), 72.0), "Arrow boosts once by 20 percent")
		check(ball.stroke_count == 0, "Arrow does not count a shot")
		check(ball._get_arrow_turn_distance(Vector2i.ZERO, Vector2(-2, 4), Vector2(2.9, 4), Vector2.RIGHT) == INF,
			"Ball radius must fit inside tile")
		check(ball._get_arrow_turn_distance(Vector2i.ZERO, Vector2(-2, 1), Vector2(20, 1), Vector2.RIGHT) == INF,
			"Side graze cannot activate arrow")
		check(ball._get_arrow_turn_distance(Vector2i.ZERO, Vector2(-2, 4), Vector2(20, 4), Vector2.RIGHT) < INF,
			"Fast full traversal is detected")
		await dispose(stage)
	var grass := floor_stage()
	var grass_ball = make_ball(grass, Vector2(8, 8))
	grass_ball.linear_velocity = Vector2(100, 0)
	await ticks(15)
	var grass_speed: float = grass_ball.linear_velocity.length()
	await dispose(grass)
	var sand := floor_stage()
	for x in range(-2, 8):
		sand.get_node("TileMap").set_cell(0, Vector2i(x, 0), 0, Vector2i(3, 10))
	var sand_ball = make_ball(sand, Vector2(8, 8))
	sand_ball.linear_velocity = Vector2(100, 0)
	await ticks(15)
	check(grass_speed > 85.0 and sand_ball.linear_velocity.length() < grass_speed - 35.0, "Sand decelerates more strongly than grass")
	await dispose(sand)
	var water := floor_stage()
	for x in range(0, 8):
		water.get_node("TileMap").set_cell(0, Vector2i(x, 0), 0, Vector2i(6, 10))
	var water_ball = make_ball(water, Vector2(-2, 8))
	water_ball.rolling_deceleration = 0.0
	water_ball._pending_shot = Vector2(60, 0)
	await ticks(4)
	check(not water_ball.is_in_water and water_ball.stroke_count == 1, "Water edge does not sink prematurely")
	await ticks(8)
	check(water_ball.is_in_water and water_ball.stroke_count == 2, "Deep water adds one penalty")
	await ticks(45)
	check(not water_ball.is_in_water and water_ball.global_position.distance_to(Vector2(-2, 8)) < 0.1,
		"Water returns the ball to the previous shot position")
	check(water_ball.stroke_count == 2, "Water penalty is not repeated during respawn")
	await dispose(water)
	for speed in [150.0, 170.0]:
		var stage := floor_stage()
		var hole = load("res://Objects/Hole/Hole.tscn").instantiate()
		hole.position = Vector2(8, 8)
		stage.add_child(hole)
		var ball = make_ball(stage, Vector2(2, 8))
		ball.rolling_deceleration = 0.0
		ball.linear_velocity = Vector2(speed, 0)
		await ticks(10)
		check(ball.is_sunk == (speed <= 160.0), "Hole respects 160 px/s capture threshold")
		await dispose(stage)
	print("SURFACES_RESULT checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
