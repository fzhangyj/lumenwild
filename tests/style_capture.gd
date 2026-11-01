extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func capture(label: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	print("CAPTURE ", label, " ", root.get_texture().get_image().save_png("res://artifacts/" + label + ".png"))

func run() -> void:
	var stage = Node3D.new()
	root.add_child(stage)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1e303f")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b6c9ec")
	env.ambient_light_energy = 0.50
	environment.environment = env
	stage.add_child(environment)
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-28, -32, 0)
	key.light_color = Color("fff2df")
	key.light_energy = 0.80
	stage.add_child(key)
	var rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-25, 150, 0)
	rim.light_color = Color("bad6f4")
	rim.light_energy = 0.38
	stage.add_child(rim)
	var camera = Camera3D.new()
	stage.add_child(camera)
	camera.fov = 30
	var avatar = Models.character(17)
	stage.add_child(avatar)
	avatar.rotation.y = PI - 0.18
	camera.position = Vector3(0, 2.3, 2.5)
	camera.look_at(Vector3(0, 2.19, 0))
	await capture("refined-face-preview")
	avatar.position.x = -1.45
	for i in [19, 20]:
		var model = Models.character(i)
		stage.add_child(model)
		model.position.x = 0.05 if i == 19 else 1.5
		model.rotation.y = PI + (0.12 if i == 19 else 0.25)
	Models.box(stage, Vector3(0, -0.04, 0), Vector3(9, 0.06, 5), Color("2b4052"))
	camera.position = Vector3(0, 1.70, 6.9)
	camera.look_at(Vector3(0, 1.36, 0))
	await capture("refined-cast-preview")
	stage.queue_free()
	await process_frame
	quit()
