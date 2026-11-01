class_name CharacterPortrait
extends SubViewportContainer

var character_id: int = 5
var beast_kind: int = 0
var avatar: Node3D
var timer: float = 0
var closeup: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	var viewport = SubViewport.new()
	viewport.size = Vector2i(size)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var stage = Node3D.new()
	viewport.add_child(stage)
	if beast_kind > 0:
		avatar = Node3D.new()
		BeastSculpt.build(avatar, beast_kind)
		if beast_kind == 4:
			avatar.scale = Vector3.ONE * 0.73
	else:
		# Keep the gameplay portrait rig stable; Blender deliverables are available
		# as editable source assets under assets/blender for continued refinement.
		avatar = Models.character(character_id)
	stage.add_child(avatar)
	avatar.rotation.y = PI - 0.18
	var camera = Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 1.65, 5.4)
	camera.look_at(Vector3(0, 1.40, 0))
	camera.fov = 30
	if closeup:
		camera.position=Vector3(0,2.13,2.05)
		camera.look_at(Vector3(0,2.04,0))
		camera.fov=27
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -35, 0)
	sun.light_energy = 0.78
	sun.light_color = Color("fff1dd")
	stage.add_child(sun)
	var rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 150, 0)
	rim.light_color = Color("d3e5f1")
	rim.light_energy = 0.32
	stage.add_child(rim)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c5cce5")
	env.ambient_light_energy = 0.40
	environment.environment = env
	stage.add_child(environment)

func _process(delta: float) -> void:
	if not is_instance_valid(avatar):
		return
	timer += delta
	avatar.rotation.y = PI - 0.18 + sin(timer * 0.45) * 0.14
	avatar.position.y = sin(timer * 1.3) * 0.035
