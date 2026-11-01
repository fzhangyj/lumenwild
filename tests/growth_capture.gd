extends SceneTree

var game: LumenGame

func _initialize() -> void:
	run.call_deferred()

func shot(label: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	print("CAPTURE ",label," ",root.get_texture().get_image().save_png("res://artifacts/"+label+".png"))

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_growth_capture.json"
	root.add_child(game)
	current_scene = game
	game.auto_shot = false
	game.start_game(false)
	game.audio.muted = true
	game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.wishes.owned.append(17)
	game.growth.books.assign([16,8,3])
	game.growth.levels[17] = 20
	game.growth.experience[17] = 155
	game.growth.materials[17] = 4
	game.growth.materials[23] = 2
	game.growth.materials[28] = 6
	game.open_overlay("growth")
	game.ui.show_growth(17)
	await shot("growth-screen-preview")
	game.growth.ascend(17)
	game.ui.show_growth(17)
	await shot("growth-ascended-preview")
	game.ui.show_growth(20)
	await shot("growth-locked-preview")
	game.growth.tracked_material = 17
	game.ui.show_map()
	await shot("growth-map-preview")
	game.close_overlay()
	game.ui.hud.visible = false
	var point: Dictionary = game.growth.nodes[51]
	game.title_camera.position = point["pos"]+Vector3(2.5,1.5,3.4)
	game.title_camera.look_at(point["pos"]+Vector3.UP*0.65)
	game.title_camera.make_current()
	await shot("growth-material-preview")
	game.growth.spawn_drop(game.enemies[0])
	var drop: Dictionary = game.growth.drops[0]
	game.title_camera.position = drop["pos"]+Vector3(1.5,1.2,2.0)
	game.title_camera.look_at(drop["pos"]+Vector3.UP*0.35)
	await shot("growth-drop-preview")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit()
