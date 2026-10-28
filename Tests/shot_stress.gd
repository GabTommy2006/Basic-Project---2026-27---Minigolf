extends SceneTree
var samples: Array = []
func _initialize() -> void:
    _run.call_deferred()
func _run() -> void:
    for number in range(1,11):
        var packed = load("res://Maps/Courses/Map%d.tscn" % number)
        for direction in 8:
            var viewport := SubViewport.new()
            viewport.size = Vector2i(1280,720)
            viewport.world_2d = World2D.new()
            viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
            root.add_child(viewport)
            var scene = packed.instantiate()
            viewport.add_child(scene)
            var map: TileMap = scene.get_node("TileMap")
            var used := map.get_used_rect()
            var tile_size := Vector2(map.tile_set.tile_size)
            var bounds := map.global_transform * Rect2(Vector2(used.position)*tile_size,Vector2(used.size)*tile_size)
            samples.append({"number":number,"angle":direction,"viewport":viewport,"ball":scene.get_node("Ball"),"bounds":bounds,"escaped":false})
    await physics_frame
    await physics_frame
    var shots := 0
    for round_index in 4:
        for sample in samples:
            var ball = sample.ball
            if not ball.is_sunk and not ball.is_in_water and ball.linear_velocity.length() <= 1.0:
                ball._pending_shot = Vector2.RIGHT.rotated(sample.angle * TAU / 8.0 + round_index * 0.71) * 180.0
                ball.sleeping = false
                shots += 1
        for tick in 420:
            await physics_frame
            for sample in samples:
                if (not sample.ball.global_position.is_finite() or not sample.ball.linear_velocity.is_finite() \
                        or not sample.bounds.grow(4.0).has_point(sample.ball.global_position)) and not sample.escaped:
                    sample.escaped = true
                    print("ESCAPED map=",sample.number," angle=",sample.angle," round=",round_index," pos=",sample.ball.global_position)
    var escapes := 0
    for sample in samples:
        if sample.escaped: escapes += 1
        sample.viewport.queue_free()
    await process_frame
    print("SHOT_STRESS_RESULT simulations=", samples.size(), " shots=", shots, " rounds=4 escapes=", escapes)
    quit(1 if escapes > 0 else 0)
