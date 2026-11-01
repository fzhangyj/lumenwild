extends SceneTree

var game: LumenGame

func _initialize() -> void:
	run.call_deferred()

func shot(label: String) -> void:
	await create_timer(1.1).timeout
	await RenderingServer.frame_post_draw
	print("CAPTURE ", label, " ", root.get_texture().get_image().save_png("res://artifacts/" + label + ".png"))

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_nature_capture.json"
	root.add_child(game)
	current_scene = game
	game.auto_shot = false
	game.audio.muted = true
	game.start_game(false)
	game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.open_overlay("bestiary")
	await shot("beasts-preview")
	game.ui.show_arts(17)
	await shot("anime-character-preview")
	game.ui.show_characters(true, 5)
	await shot("anime-roster-preview")
	game.close_overlay()
	game.ui.hud.visible = false
	game.title_camera.position = WildWorld.ground(23, 98, 11)
	game.title_camera.look_at(WildWorld.ground(0, 65, 2.5))
	game.title_camera.make_current()
	await shot("anime-world-preview")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit()
