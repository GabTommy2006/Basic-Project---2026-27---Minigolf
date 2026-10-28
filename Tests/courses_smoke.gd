# Current authored scenes; never rebuild or write map data in this test.
extends SceneTree

var failures := 0
var checks := 0
const CARDINALS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func _initialize() -> void:
    _run.call_deferred()

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        printerr("FAIL: ", message)

func descendants(node: Node) -> Array[Node]:
    var result: Array[Node] = [node]
    for child in node.get_children():
        result.append_array(descendants(child))
    return result

func dry(map: TileMap, cell: Vector2i) -> bool:
    var data := map.get_cell_tile_data(0, cell)
    if data == null:
        return false
    var atlas := map.get_cell_atlas_coords(0, cell)
    if map.get_cell_source_id(0, cell) == 0 and atlas.x >= 7 and atlas.x <= 9 and atlas.y >= 0 and atlas.y <= 2:
        return false
    if str(data.get_custom_data("surface_layer")) == "water":
        return false
    for polygon in data.get_collision_polygons_count(0):
        if Geometry2D.is_point_in_polygon(Vector2.ZERO, data.get_collision_polygon_points(0, polygon)):
            return false
    return true

func cell_at(map: TileMap, position: Vector2) -> Vector2i:
    return map.local_to_map(map.to_local(position))

func connected(map: TileMap, start: Vector2i, goal: Vector2i, links: Dictionary) -> bool:
    var seen := {start: true}
    var queue: Array[Vector2i] = [start]
    var index := 0
    while index < queue.size():
        var cell := queue[index]
        index += 1
        if cell == goal:
            return true
        var neighbors: Array[Vector2i] = []
        for direction in CARDINALS:
            neighbors.append(cell + direction)
        if links.has(cell):
            neighbors.append(links[cell])
        for next in neighbors:
            if not seen.has(next) and (dry(map, next) or (next == goal and map.get_cell_tile_data(0, goal) == null)):
                seen[next] = true
                queue.append(next)
    return false

func has_room(scene: Node2D, position: Vector2) -> bool:
    var circle := CircleShape2D.new()
    circle.radius = 3.0
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = circle
    query.transform = Transform2D(0, position)
    query.collision_mask = 1
    query.exclude = [scene.get_node("Ball").get_rid()]
    return scene.get_world_2d().direct_space_state.intersect_shape(query).is_empty()

func _run() -> void:
    for number in range(1, 11):
        var packed = load("res://Maps/Courses/Map%d.tscn" % number) as PackedScene
        check(packed != null, "Course loads: %d" % number)
        if packed == null:
            continue
        var scene := packed.instantiate() as Node2D
        root.add_child(scene)
        var map := scene.get_node("TileMap") as TileMap
        var ball = scene.get_node("Ball")
        var hole = scene.get_node("Hole")
        ball.freeze = true
        await physics_frame
        await physics_frame
        var prefix := "Course %d: " % number
        check(map.get_used_rect().has_area(), prefix + "map has tiles")
        check(dry(map, cell_at(map, ball.global_position)), prefix + "ball starts on playable ground")
        # Hole.png includes its own 16x16 grass floor; authored maps intentionally omit that TileMap cell.
        var goal_cell := cell_at(map, hole.global_position)
        var own_grass := map.get_cell_tile_data(0, goal_cell) == null and hole.get_node("Sprite2D").texture != null
        check(dry(map, goal_cell) or own_grass, prefix + "hole has playable ground or its own grass tile")
        check(has_room(scene, ball.global_position), prefix + "spawn is clear of physical walls and obstacles")
        check(has_room(scene, hole.global_position), prefix + "hole is clear of physical walls and obstacles")
        var links := {}
        for node in descendants(scene):
            if node.has_method("_get_destination"):
                var target = node._get_destination()
                check(target != null and target != node, prefix + "portal has a destination")
                if target != null:
                    check(target._get_destination() == node, prefix + "portal links are reciprocal")
                    links[cell_at(map, node.global_position)] = cell_at(map, target.global_position)
        check(connected(map, cell_at(map, ball.global_position), cell_at(map, hole.global_position), links),
            prefix + "tile route connects ball and hole, including linked portals")
        if number == 1:
            ball.freeze = false
            var distance: float = ball.global_position.distance_to(hole.global_position)
            var speed := sqrt(2.0 * float(ball.rolling_deceleration) * distance + 35.0 * 35.0)
            check(speed <= ball.max_shot_speed, "Course 1 can be completed with a legal putt")
            var completed := [0]
            hole.completed.connect(func(): completed[0] += 1)
            ball._pending_shot = ball.global_position.direction_to(hole.global_position) * speed
            for tick in 240:
                await physics_frame
                if ball.is_sunk:
                    break
            check(ball.is_sunk and ball.stroke_count == 1, "Course 1 finishes through real physics")
            check(completed[0] == 1, "Hole completion emits once")
        print("COURSE_AUDIT checked=", number)
        scene.queue_free()
        await process_frame
    print("COURSES_RESULT checks=", checks, " failures=", failures)
    quit(0 if failures == 0 else 1)
