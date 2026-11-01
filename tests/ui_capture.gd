extends SceneTree

var game: LumenGame

func _initialize() -> void:
	run.call_deferred()

func capture(label: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png("res://artifacts/" + label + ".png")
	print("CAPTURE ", label, " ", error)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_ui_capture_test.json"
	root.add_child(game)
	current_scene = game
	game.auto_shot = false
	game.audio.muted = true
	game.start_game(false)
	game.coins = 1800
	game.open_overlay("wish")
	await capture("wish-preview")
	game.ui.show_characters(true)
	await capture("limited-preview")
	game.ui.show_wish()
	game.wishes.pity = WishSystem.SOFT_PITY - 1
	game.wishes.guaranteed = true
	game.perform_wish(10)
	for child in game.ui.overlay.get_children():
		if child is WishAnimation:
			child.set_process(false)
			child.elapsed = 2.8
			child.queue_redraw()
	await capture("wish-animation-preview")
	game.finish_wish_animation()
	await capture("wish-results-preview")
	game.ui.show_wish_results([game.wishes.history.back()])
	await capture("wish-single-preview")
	game.ui.show_wish_rules()
	await capture("wish-rules-preview")
	game.ui.show_wish_history()
	await capture("wish-history-preview")
	game.quest_stage = 6
	game.ui.show_journal(2)
	await capture("chapter-preview")
	game.quest_stage = 12
	game.ui.show_journal(3)
	await capture("chapter-three-preview")
	game.ui.show_chapter_ending(3)
	await capture("ending-three-preview")
	game.ui.show_characters(false)
	await capture("characters-preview")
	game.ui.show_arts(7)
	await capture("skills-detail-preview")
	for batch in range(1, 4):
		game.ui.show_characters(true, batch)
		await capture("limited-batch-%d" % batch)
	game.quest_stage = 4
	game.ui.show_wish()
	await capture("wish-rotation-preview")
	game.ui.show_ending()
	await capture("ending-rotation-preview")
	game._reset_progress()
	for i in range(15):
		game.world.open_chest(i)
	game.renewal.collected_total = 15
	game.renewal.request_check()
	await process_frame
	await physics_frame
	game.ui.show_map()
	await capture("renewed-map-preview")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit()
