extends SceneTree

var viewport: SubViewport
var page: Control
var gold=Color("d9c691")
func _initialize() -> void: run.call_deferred()
func label(text: String,pos: Vector2,size: Vector2,point: int,color: Color) -> void:
	var node=Label.new()
	node.text=text
	node.position=pos; node.size=size
	node.add_theme_font_override("font",load("res://assets/ui_font.tres"))
	node.add_theme_font_size_override("font_size",point)
	node.add_theme_color_override("font_color",color)
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(node)
func rule(pos: Vector2,size: Vector2) -> void:
	var line=ColorRect.new()
	line.position=pos; line.size=size; line.color=gold
	page.add_child(line)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/posters")
	for index in range(3):
		print("RENDER START ",index)
		var id=[2,5,20][index]
		var color=GameData.character_color(id)
		viewport=SubViewport.new()
		viewport.size=Vector2i(1000,1500)
		viewport.own_world_3d=true
		viewport.msaa_3d=Viewport.MSAA_4X
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var stage=Node3D.new(); viewport.add_child(stage)
		var env_node=WorldEnvironment.new()
		var env=Environment.new()
		env.background_mode=Environment.BG_COLOR
		env.background_color=[Color("092c40"),Color("111e36"),Color("392637")][index]
		env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color=Color("c2d9e5")
		env.ambient_light_energy=0.65
		env_node.environment=env; stage.add_child(env_node)
		var sun=DirectionalLight3D.new()
		sun.rotation_degrees=Vector3(-30,-35,0)
		sun.light_color=Color("fff1d8"); sun.light_energy=0.9
		stage.add_child(sun)
		var rim=DirectionalLight3D.new()
		rim.rotation_degrees=Vector3(-25,145,0)
		rim.light_color=color; rim.light_energy=0.45
		stage.add_child(rim)
		var avatar=Models.character(id)
		stage.add_child(avatar)
		avatar.rotation.y=PI+[-0.18,0.25,-0.30][index]
		avatar.get_node("ArmL").rotation.z=-0.15
		avatar.get_node("ArmR").rotation.x=-0.15
		avatar.get_node("Head").rotation.y=-0.04
		avatar.get_node("Cape").rotation.x=-0.20
		Models.cylinder(stage,Vector3(0,-0.12,0),0.82,0.12,Color("415967"),-1,64)
		for r in [0.89,1.10,1.22]:
			Models.ring(stage,Vector3(0,1.5,-0.55),r,color.darkened(0.40),0.010).rotation.x=PI/2
		for j in range(24):
			var a=TAU*j/24
			var p=Vector3(sin(a)*1.19,1.5+cos(a)*1.19,-0.54)
			Models.crystal(stage,p,0.017 if j%3 else 0.04,gold)
		for j in range(28):
			var a=j*2.4
			var p=Vector3(sin(a)*(0.75+j*0.014),0.1+j*0.081,0.2-cos(a)*0.25)
			Models.sphere(stage,p,Vector3.ONE*0.022,color,0.3)
		var camera=Camera3D.new()
		stage.add_child(camera)
		camera.position=Vector3(0,1.44,7.4)
		camera.look_at(Vector3(0,1.44,0))
		camera.fov=27
		page=Control.new(); viewport.add_child(page)
		rule(Vector2(42,42),Vector2(916,1)); rule(Vector2(42,1458),Vector2(916,1))
		for x in [42,958]: rule(Vector2(x,42),Vector2(1,1416))
		label("L U M E N W I L D",Vector2(100,72),Vector2(800,52),26,gold)
		label(["T I D E   /   M E M O R Y","M O O N   /   V O Y A G E","D A W N   /   P R O M I S E"][index],Vector2(100,132),Vector2(800,38),17,color)
		label(GameData.character(id)["name"],Vector2(100,1175),Vector2(800,130),86,Color("f4ead3"))
		label(GameData.character(id)["title"],Vector2(100,1310),Vector2(800,50),27,gold)
		label(["潮水记得，每一句未说完的明天见。","让晚风，带你去星光亮起的地方。","晨光会来，我们先点灯。"][index],Vector2(100,1390),Vector2(800,40),21,Color("b5c5c8"))
		await create_timer(0.6).timeout
		RenderingServer.force_draw()
		var path="res://assets/posters/"+["lanyin","qiyue","zhaoli"][index]+".png"
		print("POSTER ",path," ",viewport.get_texture().get_image().save_png(path))
		viewport.queue_free(); await process_frame
	quit()
