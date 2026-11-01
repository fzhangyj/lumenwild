extends SceneTree

var game: LumenGame
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

# The walker now plans around solid scenery instead of demanding straight lines.
# Every resulting step is still performed through the player's movement input.
func walking_route(target: Vector2) -> PackedVector2Array:
	var start = Vector2(game.player.position.x, game.player.position.z)
	var blocked = false
	for sample in range(ceili(start.distance_to(target) * 2) + 1):
		var point = start.move_toward(target, sample * 0.5)
		if not game.world.solids.clear_at(WildWorld.ground(point.x, point.y, 0.2), 0.85):
			blocked = true
			break
	if not blocked:
		return PackedVector2Array([target])
	var grid = AStarGrid2D.new()
	var begin = Vector2i(floori(minf(start.x, target.x)) - 8, floori(minf(start.y, target.y)) - 8)
	var end = Vector2i(ceili(maxf(start.x, target.x)) + 8, ceili(maxf(start.y, target.y)) + 8)
	grid.region = Rect2i(begin, end - begin + Vector2i.ONE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.43
	capsule.height = 1.8
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	for x in range(begin.x, end.x + 1):
		for z in range(begin.y, end.y + 1):
			var pos = WildWorld.ground(x, z, 0.2)
			var solid = pos.y < 1.1 or not game.world.solids.clear_at(pos, 0.85)
			if not solid:
				query.transform = Transform3D(Basis(), pos + Vector3.UP * 0.95)
				solid = not game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
			grid.set_point_solid(Vector2i(x, z), solid)
	var first = Vector2i(start.round())
	var last = Vector2i(target.round())
	grid.set_point_solid(first, false)
	grid.set_point_solid(last, false)
	var path = grid.get_point_path(first, last)
	path.append(target)
	return path

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_traversal_test.json"
	root.add_child(game)
	current_scene = game
	game.start_game(false)
	game.audio.set_process(false)
	for enemy in game.enemies:
		enemy.awakened = false
	for i in range(30):
		await physics_frame
	var routes = [Vector2(0, 35), Vector2(-53, 39), Vector2(0, 35), Vector2(61, 32), Vector2(8, -25), Vector2(-56, -27), Vector2(-67, -22), Vector2(-56, -27), Vector2(8, -25), Vector2(59, -44), Vector2(8, -25), Vector2(-30, -71), Vector2(0, -92), Vector2(0, -101)]
	# Walk the new chapter routes around the lake, without teleporting.
	routes.append_array([Vector2(-55, -81), Vector2(-98, -66), Vector2(-105, -49), Vector2(-116, -42), Vector2(-112, -33), Vector2(-114, -9), Vector2(-104, -12), Vector2(-91, -3), Vector2(-69, -14), Vector2(-66, -45), Vector2(-73, -56), Vector2(-89, -56), Vector2(-60, -66), Vector2(8, -25), Vector2(93, 42), Vector2(88, 31), Vector2(94, 20), Vector2(94, -8), Vector2(75, 3), Vector2(85, -37), Vector2(83, -73), Vector2(47, -95)])
	routes.append_array([Vector2(8, -25), Vector2(-20, -8), Vector2(-48, 5), Vector2(-30, 22), Vector2(-28, 26), Vector2(-17, 20), Vector2(-27, 4), Vector2(-29, -15), Vector2(-40, -30), Vector2(-15, 10), Vector2(0, 35), Vector2(40, 57), Vector2(55, 65), Vector2(65, 48), Vector2(51, 34), Vector2(34, 39), Vector2(51, 12), Vector2(75, 58), Vector2(55, 82)])
	for target in routes:
		var reached = false
		var path = walking_route(target)
		var step = 0
		Input.action_press("move_forward")
		for frame in range(3000):
			var current = Vector2(game.player.position.x, game.player.position.z)
			if current.distance_to(target) < 1.1:
				reached = true
				break
			while step < path.size() - 1 and current.distance_to(path[step]) < 0.45:
				step += 1
			var difference: Vector2 = path[step] - current
			game.player.yaw = atan2(-difference.x, -difference.y)
			await physics_frame
		Input.action_release("move_forward")
		if reached:
			print("PASS Walked to ", target, " at height ", snappedf(game.player.position.y, 0.01))
		else:
			failures.append(str(target))
			push_error("Unable to walk to " + str(target) + "; stopped at " + str(game.player.position))
	var summit_height = WildWorld.height_at(0, -92)
	if absf(summit_height - 14.0) > 0.05:
		failures.append("Summit platform alignment")
	else:
		print("PASS Observatory floor aligns with terrain")
	# Route tests move only through input, never teleport the player.
	game.ui.show_pause()
	game.ui.show_map()
	game.ui.show_characters()
	game.ui.show_journal()
	game.close_overlay()
	for i in range(4):
		await process_frame
	print("TRAVERSAL RESULT: ", routes.size() + 1 - failures.size(), "/", routes.size() + 1, " checks passed")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)


