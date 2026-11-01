extends SceneTree

var game: LumenGame
var checks = 0
var failures = 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_solids_test.json"
	root.add_child(game)
	current_scene = game
	game.start_game(false)
	game.audio.muted = true
	for enemy in game.enemies:
		enemy.set_physics_process(false)
		enemy.awakened = false
	await physics_frame
	var trees = 0
	var rocks = 0
	var trunk: Dictionary = {}
	var boulder: Dictionary = {}
	for obstacle in game.world.solids.obstacles:
		if obstacle["kind"] == "tree":
			trees += 1
			if trunk.is_empty() and absf(obstacle["pos"].x) < 90:
				trunk = obstacle
		else:
			rocks += 1
			var pos: Vector3 = obstacle["pos"]
			if boulder.is_empty() and obstacle["top"] - WildWorld.height_at(pos.x, pos.z) > 1.5 and pos.y > 3:
				boulder = obstacle
	check(trees > 100 and rocks > 100, "World creates physical trunks and boulders throughout the island")
	for obstacle in [trunk, boulder]:
		var pos: Vector3 = obstacle["pos"]
		var base = WildWorld.ground(pos.x, pos.z, 0.2)
		var distance: float = obstacle["radius"].length() + 2.5
		game.player.position = WildWorld.ground(pos.x, pos.z - distance, 0.3)
		game.player.velocity = Vector3.ZERO
		game.player.yaw = PI
		for i in range(20):
			await physics_frame
		Input.action_press("move_forward")
		for i in range(90):
			await physics_frame
		Input.action_release("move_forward")
		check(game.player.position.z < pos.z - 0.3 and game.player.position.z > pos.z - distance + 0.3, "Walking reaches but cannot pass through " + obstacle["kind"])
		var ray = PhysicsRayQueryParameters3D.create(base + Vector3(0, 1, -distance), base + Vector3(0, 1, distance), 1)
		var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit["collider"] == obstacle["body"], "Camera/world collision ray meets actual " + obstacle["kind"])
	game.player.set_physics_process(false)
	var inside = WildWorld.ground(trunk["pos"].x, trunk["pos"].z, 0.1)
	game.player.position = inside
	game.last_safe_position = inside
	game.coins = 734
	game.save_game()
	game.load_game()
	check(game.world.solids.clear_at(game.player.position) and game.player.position.distance_to(inside) > 0.5 and game.coins == 734, "Old player position is moved out of a solid trunk without changing currency")
	check(game.world.solids.clear_at(game.last_safe_position), "Saved recovery checkpoint is also kept outside obstacles")
	game.renewal._set_chest(0, inside)
	check(game.world.solids.clear_at(game.world.chests[0]["pos"], 1.0), "Restored chest positions avoid new solid scenery")
	var data = game.renewal.to_dict()
	data["enemies"][0] = [inside.x, inside.z, -1]
	game.renewal.restore(data)
	check(game.world.solids.clear_at(game.enemies[0].home, 0.85), "Restored roaming enemy homes avoid new solid scenery")
	game.mode = "playing"
	game.wishes.owned.append(6)
	game.player.set_character(6, false)
	game.player.position = WildWorld.ground(inside.x, inside.z - 3.0, 0.3)
	game.player.avatar.rotation.y = PI
	game.player.velocity = Vector3.ZERO
	game.player.set_physics_process(true)
	for enemy in game.enemies:
		enemy.awakened = false
	for i in range(20):
		await physics_frame
	game.player.cast_skill()
	for i in range(40):
		await physics_frame
	check(game.player.position.z < inside.z - 0.3 and game.player.position.z > inside.z - 2.4, "Limited fire dash is blocked by an actual tree trunk")
	check(game.world.solids.clear_at(inside + Vector3.UP * 20), "Gliding above the canopy does not trigger ground-position recovery")
	print("SOLIDS RESULT: ", checks - failures, "/", checks, " checks passed; ", trees, " trunks, ", rocks, " rocks")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
