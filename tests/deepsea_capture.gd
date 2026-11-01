extends SceneTree
var game: LumenGame
func _initialize() -> void: run.call_deferred()
func shot(label: String) -> void:
	await create_timer(1).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://artifacts/"+label+".png")
	print("CAPTURE ",label)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	game.test_mode=true
	game.save_path="user://lumenwild_sea_capture.json"
	root.add_child(game); current_scene=game
	game.start_game(false); game.audio.muted=true
	game.quest_stage=26
	game.sea.enter()
	game.player.set_physics_process(false)
	for e in game.enemies: e.set_physics_process(false)
	game.player.position=DeepSea.CENTER+Vector3(0,19,27)
	game.player.yaw=0; game.player.pitch=-0.1
	game.player.pivot.rotation=Vector3(-0.1,0,0)
	game.player.avatar.rotation.y=0
	game.player.camera.make_current()
	await shot("deepsea-gameplay")
	game.ui.hud.hide()
	game.ui.toast_time=0
	game.waypoint.hide()
	game.title_camera.environment=game.sea.sea_env
	game.title_camera.position=DeepSea.CENTER+Vector3(32,27,40)
	game.title_camera.look_at(DeepSea.CENTER+Vector3(0,10,-16))
	game.title_camera.make_current()
	await shot("deepsea-city")
	game.begin_dialogue([["澜音","这座邮局没有收件人，只有一封封写着『明天见』的信。可这里的人，已经等了一百年。"]])
	await shot("deepsea-dialogue")
	game.advance_dialogue()
	game.open_overlay("map")
	await shot("deepsea-map")
	game.open_overlay("journal")
	await shot("deepsea-journal")
	game.open_overlay("gallery")
	await shot("cast-gallery")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free(); await process_frame
	quit()
