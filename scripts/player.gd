class_name LumenPlayer
extends CharacterBody3D

var game: Node3D
var avatar: Node3D
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var glider: Node3D
var character_index: int = 0
var hp: float = 180.0
var max_hp: float = 180.0
var stamina: float = 100.0
var energy: float = 65.0
var shield: float = 0.0
var skill_cooldowns: Array[float] = []
var burst_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var invulnerability: float = 0.0
var switch_cooldown: float = 0.0
var hit_animation: float = 0.0
var walk_time: float = 0.0
var gliding: bool = false
var yaw: float = 0.0
var pitch: float = -0.22
var enabled: bool = false
var dash_time: float = 0
var dash_direction = Vector3.ZERO

func _ready() -> void:
	skill_cooldowns.resize(GameData.CHARACTER_COUNT)
	skill_cooldowns.fill(0)
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.6
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.9
	collider.shape = capsule
	collider.position.y = 0.96
	add_child(collider)
	pivot = Node3D.new()
	pivot.position.y = 1.8
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 8.6
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())
	var sphere = SphereShape3D.new()
	sphere.radius = 0.2
	arm.shape = sphere
	arm.margin = 0.18
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 65
	camera.near = 0.15
	camera.far = 1000
	arm.add_child(camera)
	set_character(0, false)
	_make_glider()

func _make_glider() -> void:
	glider = Node3D.new()
	add_child(glider)
	glider.position.y = 2.35
	for side in [-1, 1]:
		var surface = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in [Vector3(0, 0.3, -0.6), Vector3(side * 3.1, 0.15, 0.2), Vector3(side * 1.3, -0.2, 1.15)]:
			surface.add_vertex(v)
		surface.generate_normals()
		var wing = MeshInstance3D.new()
		wing.mesh = surface.commit()
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color("e2ddbe")
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		wing.material_override = mat
		glider.add_child(wing)
		var spar = Models.box(glider, Vector3(side * 1.4, 0.21, -0.15), Vector3(3.0, 0.06, 0.07), Color("4a8078"))
		spar.rotation.y = side * -0.26
	glider.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not game.is_playing():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clampf(pitch - event.relative.y * 0.002, -0.9, 0.35)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			arm.spring_length = maxf(4.0, arm.spring_length - 0.6)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			arm.spring_length = minf(15.0, arm.spring_length + 0.6)

func _physics_process(delta: float) -> void:
	if not enabled or not game.is_playing():
		return
	for i in range(skill_cooldowns.size()):
		skill_cooldowns[i] = maxf(0, skill_cooldowns[i] - delta)
	burst_cooldown = maxf(0, burst_cooldown - delta)
	attack_cooldown = maxf(0, attack_cooldown - delta)
	invulnerability = maxf(0, invulnerability - delta)
	switch_cooldown = maxf(0, switch_cooldown - delta)
	shield = maxf(0, shield - delta * 1.3)
	hit_animation = maxf(0, hit_animation - delta)
	pivot.rotation = Vector3(pitch, yaw, 0)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Basis(Vector3.UP, yaw) * Vector3(input_dir.x, 0, input_dir.y)
	if game.sea.active:
		_swim(delta,direction)
		return
	avatar.rotation.x = 0
	floor_snap_length = 0.6
	var sprint = Input.is_action_pressed("sprint") and stamina > 1 and direction.length() > 0.1 and is_on_floor()
	var speed = 13.5 if sprint else 8.3
	if sprint:
		stamina = maxf(0, stamina - delta * 17)
	elif is_on_floor():
		stamina = minf(100, stamina + delta * 22)
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = 10.5
		elif stamina > 3:
			gliding = not gliding
	if is_on_floor():
		gliding = false
	if gliding:
		speed = 11.5
		stamina = maxf(0, stamina - delta * 8)
		velocity.y = move_toward(velocity.y, -1.65, delta * 20)
		if stamina <= 0:
			gliding = false
	elif not is_on_floor():
		velocity.y -= delta * 24
	glider.visible = gliding
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 42)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 42)
	if dash_time > 0:
		dash_time = maxf(0, dash_time - delta)
		velocity.x = dash_direction.x * 23
		velocity.z = dash_direction.z * 23
		direction = dash_direction
		if dash_time <= 0:
			velocity.x = 0
			velocity.z = 0
	move_and_slide()
	if direction.length() > 0.1:
		avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(-direction.x, -direction.z), delta * 12)
	glider.rotation.y = avatar.rotation.y
	_animate(delta, direction.length(), sprint)
	if Input.is_action_pressed("attack"):
		attack()
	if Input.is_action_just_pressed("skill"):
		cast_skill()
	if Input.is_action_just_pressed("burst"):
		cast_burst()
	for i in range(5):
		if Input.is_action_just_pressed("character_" + str(i + 1)):
			set_character(game.party[i])
	if Input.is_action_just_pressed("potion"):
		game.use_potion()
	if global_position.y < -1.3 or Vector2(global_position.x, global_position.z).length() > 168:
		game.recover_player("潮水把你送回了最近的共鸣点。")

func _animate(delta: float, amount: float, sprint: bool) -> void:
	walk_time += delta * (15.0 if sprint else 10.0)
	var swing = sin(walk_time) * amount * 0.6 if is_on_floor() else 0.15
	avatar.get_node("LegL").rotation.x = swing
	avatar.get_node("LegR").rotation.x = -swing
	avatar.get_node("ArmL").rotation.x = -swing * 0.7
	avatar.get_node("ArmR").rotation.x = swing * 0.7 - sin(hit_animation * 12) * 1.8
	avatar.get_node("Cape").rotation.x = -0.18 - amount * 0.25 + sin(walk_time * 0.5) * 0.05
	avatar.position.y = absf(sin(walk_time)) * 0.065 * amount if is_on_floor() else 0.0
	if gliding:
		avatar.get_node("ArmL").rotation.z = -1.9
		avatar.get_node("ArmR").rotation.z = 1.9
	else:
		avatar.get_node("ArmL").rotation.z = 0.1
		avatar.get_node("ArmR").rotation.z = -0.1

func set_character(index: int, effects: bool = true) -> void:
	if index < 0 or index >= GameData.CHARACTER_COUNT or not game.wishes.has_character(index):
		return
	if effects and (switch_cooldown > 0 or character_index == index):
		return
	var previous_rotation = 0.0
	if is_instance_valid(avatar):
		previous_rotation = avatar.rotation.y
		remove_child(avatar)
		avatar.queue_free()
	character_index = index
	avatar = Models.character(index)
	add_child(avatar)
	avatar.rotation.y = previous_rotation
	switch_cooldown = 0.35
	if effects and is_instance_valid(game):
		game.pulse(global_position + Vector3.UP, GameData.character_color(index), 2.2, 0.45)
		game.audio.tone(480.0 + index * 75, 0.16, 0.16)

func attack() -> void:
	if attack_cooldown > 0:
		return
	attack_cooldown = 0.43
	hit_animation = 0.3
	game.perform_attack("normal")

func cast_skill() -> void:
	if skill_cooldowns[character_index] > 0:
		return
	skill_cooldowns[character_index] = GameData.character(character_index)["cooldown"]
	hit_animation = 0.45
	if character_index >= 5:
		game.arts.cast(character_index, false)
		return
	if character_index == 2:
		hp = minf(max_hp, hp + 35)
		game.floating_text(global_position + Vector3.UP * 2.5, "+35", Color("8de3c7"))
	elif character_index == 4:
		shield = minf(100, shield + 65)
	elif character_index == 3:
		invulnerability = 0.5
	game.perform_attack("skill")

func cast_burst() -> void:
	if burst_cooldown > 0:
		return
	if energy < 100:
		game.toast("共鸣能量不足 · 攻击敌人或开启宝箱可积攒能量")
		return
	energy = 0
	burst_cooldown = 14
	invulnerability = 1.2
	if character_index >= 5:
		game.arts.cast(character_index, true)
		return
	if character_index == 2:
		hp = minf(max_hp, hp + 90)
	elif character_index == 4:
		shield = 100
	game.perform_attack("burst")

func take_damage(amount: float) -> void:
	if invulnerability > 0 or not game.is_playing():
		return
	amount *= game.growth.damage_taken(character_index)
	var absorbed = minf(shield, amount)
	shield -= absorbed
	amount -= absorbed
	hp = maxf(0, hp - amount)
	invulnerability = 0.65
	game.floating_text(global_position + Vector3.UP * 2.3, "−" + str(int(amount)), Color("ffab97"))
	game.ui.flash_damage()
	if hp <= 0:
		game.recover_player("星灯仍在守望你。生命与共鸣已恢复。")

func _swim(delta: float, direction: Vector3) -> void:
	var vertical = float(Input.is_action_pressed("jump"))-float(Input.is_action_pressed("dive_down"))
	var speed = 11.0 if Input.is_action_pressed("sprint") else 7.0
	var desired = Vector3(direction.x,vertical,direction.z).limit_length(1.0)*speed
	velocity = velocity.move_toward(desired,delta*15)
	floor_snap_length = 0
	move_and_slide()
	position.x=clampf(position.x,542,658)
	position.z=clampf(position.z,-58,58)
	position.y=clampf(position.y,-39,1)
	glider.visible=false
	stamina=100
	if direction.length()>0.1:
		avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(-direction.x,-direction.z),delta*5)
	avatar.rotation.x=lerpf(avatar.rotation.x,-0.28 if desired.length()>0.2 else 0.0,delta*3)
	walk_time+=delta*3
	avatar.get_node("LegL").rotation.x=sin(walk_time)*0.22
	avatar.get_node("LegR").rotation.x=-sin(walk_time)*0.22
	avatar.get_node("ArmL").rotation.z=-0.65-sin(walk_time)*0.18
	avatar.get_node("ArmR").rotation.z=0.65+sin(walk_time)*0.18
	avatar.get_node("Cape").rotation.x=-0.35+sin(walk_time)*0.10
	for i in range(5):
		if Input.is_action_just_pressed("character_"+str(i+1)): set_character(game.party[i])
	if Input.is_action_just_pressed("skill") and attack_cooldown<=0:
		attack_cooldown=0.8
		game.sea.sonar()
	if Input.is_action_just_pressed("potion"): game.use_potion()
