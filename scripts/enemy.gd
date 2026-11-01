class_name HollowEnemy
extends CharacterBody3D

var game: Node3D
var boss: bool = false
var shrine_index: int = -1
var hp: float = 100
var max_hp: float = 100
var element: int = -1
var element_time: float = 0
var burn_time: float = 0
var burn_tick: float = 0
var dead: bool = false
var home: Vector3
var visual: Node3D
var core: Node3D
var health_bar: MeshInstance3D
var attack_timer: float = 1.5
var windup: float = -1
var attack_point: Vector3
var telegraph: MeshInstance3D
var stagger: float = 0
var elapsed: float = 0
var engaged: bool = false
var awakened: bool = true
var display_name: String = "失律的天穹守卫"
var chapter: int = 1
var root_strikes: Array[Vector3] = []
var kind = 0
var beast: BeastCombat
var nameplate: Label3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	max_hp = 880 if boss else 104
	hp = max_hp
	home = position
	var col = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 1.25 if boss else 0.6
	shape.height = 5 if boss else 1.8
	col.shape = shape
	col.position.y = 2.5 if boss else 0.9
	add_child(col)
	visual = Node3D.new()
	add_child(visual)
	if boss:
		_build_boss()
	elif kind > 0:
		core = BeastSculpt.build(visual, kind)
		beast = BeastCombat.new()
		beast.enemy = self
	else:
		_build_hollow()
		Models.stylize(visual, 0.008)
	var bar_back = Models.box(self, Vector3(0, 6.5 if boss else 2.7, 0), Vector3(3.0 if boss else 1.5, 0.10, 0.06), Color("38494d"))
	health_bar = Models.box(bar_back, Vector3(0, 0, -0.04), Vector3(2.95 if boss else 1.45, 0.08, 0.04), Color("e3a683"))
	bar_back.visible = not boss
	if not boss:
		display_name = BeastSculpt.NAMES[kind]
		nameplate = game.world._label(self, display_name, Vector3(0, 3.0, 0), BeastSculpt.COLORS[kind], 19)

func _build_hollow() -> void:
	core = Models.crystal(visual, Vector3(0, 1.4, 0), 1.0, Color("ae7ed8"))
	for i in range(4):
		var a = i * PI / 2 + PI / 4
		var shard = Models.cylinder(visual, Vector3(sin(a) * 0.73, 0.9, cos(a) * 0.73), 0.3, 1.5, Color("424c64"), 0.06, 4)
		shard.rotation.z = sin(a) * 0.4
		shard.rotation.x = cos(a) * 0.4
	Models.ring(visual, Vector3(0, 1.4, 0), 0.75, Color("9673b5"), 0.04)
	for side in [-1, 1]:
		CharacterSculpt.leaf(visual, Vector3(side * 0.23, 1.62, 0.08), Vector3(side * 0.89, 1.12, -0.15), 0.26, Color("566576"), 0.10)
		CharacterSculpt.leaf(visual, Vector3(side * 0.70, 1.12, -0.15), Vector3(side * 0.91, 0.17, -0.36), 0.13, Color("334553"), 0.09)
		Models.sphere(visual, Vector3(side * 0.3, 1.6, -0.42), Vector3(0.10, 0.06, 0.04), Color("e3c6ef"), 0.8)
	Models.ring(visual, Vector3(0, 1.35, -0.46), 0.24, Color("b9acbd"), 0.027).rotation.x = PI * 0.5

func _build_boss() -> void:
	core = EnemySculpt.guardian(visual)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(game) or not game.is_playing() or not awakened:
		return
	elapsed += delta
	var distance = global_position.distance_to(game.player.global_position)
	if distance > 58:
		if beast:
			beast._tick_bolts(delta)
		return
	if element_time > 0:
		element_time -= delta
	else:
		element = -1
	if burn_time > 0:
		burn_time -= delta
		burn_tick -= delta
		if burn_tick <= 0:
			burn_tick = 1.0
			damage(5, -1, false)
			if dead:
				return
	stagger = maxf(0, stagger - delta)
	core.rotation.y += delta * 1.2
	visual.position.y = sin(elapsed * 2.3) * (0.07 if boss else 0.18)
	health_bar.get_parent().rotation.y = game.player.yaw
	engaged = distance < (25 if boss else 17) or (engaged and distance < 32)
	if nameplate:
		nameplate.visible = distance < 23
	if beast:
		beast.tick(delta)
		return
	if windup >= 0:
		windup -= delta
		if is_instance_valid(telegraph):
			telegraph.scale = Vector3.ONE * (1.0 + sin(elapsed * 18) * 0.06)
		if windup < 0:
			_finish_attack()
		velocity.x = 0
		velocity.z = 0
	elif engaged and stagger <= 0:
		var difference: Vector3 = game.player.global_position - global_position
		difference.y = 0
		var direction = difference.normalized()
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), delta * 4)
		var speed = (4.0 if hp > max_hp * 0.5 else 5.2) if boss else 3.4
		velocity.x = direction.x * speed if distance > (4.2 if boss else 2.3) else 0.0
		velocity.z = direction.z * speed if distance > (4.2 if boss else 2.3) else 0.0
		attack_timer -= delta
		if attack_timer <= 0 and distance < (18 if boss else 3.7):
			_start_attack()
	else:
		velocity.x = move_toward(velocity.x, 0, delta * 14)
		velocity.z = move_toward(velocity.z, 0, delta * 14)
	if not is_on_floor():
		velocity.y -= delta * 20
	move_and_slide()
	if global_position.distance_to(home) > (31 if boss else 28) and not engaged:
		global_position = home

func _start_attack() -> void:
	if beast:
		beast.start()
		return
	windup = (1.15 if hp > max_hp * 0.5 else 0.8) if boss else 0.65
	attack_point = game.player.global_position
	attack_point.y = WildWorld.height_at(attack_point.x, attack_point.z) + 0.18
	telegraph = Models.ring(game, attack_point, 5.8 if boss else 2.7, Color("f37e6a"), 0.10)
	root_strikes.clear()
	if boss and chapter == 4:
		windup = 1.35
		var circle = TorusMesh.new()
		circle.inner_radius = 2.7
		circle.outer_radius = 2.9
		telegraph.mesh = circle
		for offset in [Vector3(-5.5, 0, 0), Vector3.ZERO, Vector3(5.5, 0, 0)]:
			var strike = WildWorld.ground(attack_point.x + offset.x, attack_point.z + offset.z, 0.18)
			root_strikes.append(strike)
		for i in [0, 2]:
			Models.ring(telegraph, root_strikes[i] - attack_point, 2.8, Color("e6a58b"), 0.10)
		game.toast("根刺将刺穿三处地面 · 离开红圈", 3)
		return
	if boss and chapter == 5:
		windup = 1.5
		var circle = TorusMesh.new()
		circle.inner_radius = 8.9
		circle.outer_radius = 9.1
		telegraph.mesh = circle
		Models.ring(telegraph, Vector3.ZERO, 3.5, Color("a7e1b1"), 0.11)
		game.toast("日冕将冲击环形区域 · 进入绿色内圈或远离外圈", 3)
		return
	if boss:
		game.toast("守卫正在蓄力 · 离开红色圆环")

func _finish_attack() -> void:
	if beast:
		beast.finish()
		return
	if is_instance_valid(telegraph):
		telegraph.queue_free()
	if boss and chapter >= 4:
		if chapter == 4:
			for point in root_strikes:
				game.pulse(point, Color("e2b588"), 2.8, 0.65)
				game.spark(point + Vector3.UP, Color("b5c7a1"), 12)
				if game.player.position.distance_to(point) < 2.8:
					game.player.take_damage(28)
		else:
			game.pulse(attack_point, Color("efc38c"), 9, 0.6)
			var distance = game.player.position.distance_to(attack_point)
			if distance >= 3.5 and distance < 9:
				game.player.take_damage(35)
		attack_timer = 2.5 if hp < max_hp * 0.5 else 3.2
		return
	game.pulse(attack_point, Color("e7907b"), 6.0 if boss else 2.8, 0.5)
	if game.player.global_position.distance_to(attack_point) < (5.8 if boss else 2.8):
		game.player.take_damage(31 if boss else 12)
	attack_timer = (2.2 if hp < max_hp * 0.5 else 3.2) if boss else 2.0
	if chapter == 3:
		attack_timer *= 0.8

func customize(new_name: String, new_hp: float, color: Color, new_chapter: int) -> void:
	display_name = new_name
	if nameplate:
		nameplate.text = new_name + " · " + BeastSculpt.NAMES[kind]
	max_hp = new_hp
	hp = new_hp
	chapter = new_chapter
	for part in core.get_children():
		if part is MeshInstance3D:
			part.material_override = Models.material(color, 0.8)
	if boss:
		for i in range(1 if chapter >= 4 else 3):
			var halo = Models.ring(visual, Vector3(0, 2.7 if chapter >= 4 else 3.5 + i * 0.6, 0), 2.5 + i * 0.3, color, 0.045)
			halo.rotation.x = i * 0.45
		if chapter == 4:
			for side in [-1, 1]:
				for i in range(3):
					CharacterSculpt.leaf(visual, Vector3(side * 0.43, 5.15, 0.1), Vector3(side * (0.9 + i * 0.4), 5.7 + i * 0.23, 0.15 + i * 0.24), 0.13, Color("9c9f75"), 0.08)
		elif chapter == 5:
			for i in range(10):
				var a = i * TAU / 10
				CharacterSculpt.leaf(visual, Vector3(sin(a) * 1.7, 4.5 + cos(a) * 1.7, 0.82), Vector3(sin(a) * 2.2, 4.5 + cos(a) * 2.2, 0.82), 0.11, color, 0.055)

func damage(amount: float, incoming_element: int, apply_element: bool = true) -> void:
	if dead or not awakened:
		return
	if not boss and kind == 4 and windup >= 0:
		if incoming_element == 4:
			windup = -1
			attack_timer = 2.5
			stagger = 1.0
			if is_instance_valid(telegraph):
				telegraph.queue_free()
				telegraph = null
			game.floating_text(position + Vector3.UP * 2.8, "破甲", Color("f2d5a5"))
		else:
			amount *= 0.55
	var reaction_name = ""
	if apply_element and incoming_element >= 0:
		reaction_name = GameData.reaction(element, incoming_element)
		if reaction_name == "蒸腾":
			amount *= 1.8
		elif reaction_name == "超载":
			amount *= 1.55
			stagger = 0.8
		elif reaction_name == "感电":
			amount *= 1.4
			stagger = 0.55
		elif reaction_name == "扩散":
			amount *= 1.25
			game.spread_damage(self, 15)
		elif reaction_name == "结晶":
			game.player.shield = minf(100, game.player.shield + 18)
		if incoming_element == 1:
			burn_time = 4
		element = incoming_element
		element_time = 8.0
	hp -= amount
	engaged = true
	health_bar.scale.x = maxf(0, hp / max_hp)
	var color = GameData.element_color(incoming_element) if incoming_element >= 0 else Color("ffe4b9")
	game.floating_text(global_position + Vector3.UP * (4.7 if boss else 2.1), str(int(amount)), color)
	if reaction_name != "":
		game.floating_text(global_position + Vector3.UP * (5.8 if boss else 3.1), reaction_name, color)
		game.reactions_triggered += 1
	game.player.energy = minf(100, game.player.energy + 7)
	stagger = maxf(stagger, 0.1)
	game.spark(global_position + Vector3.UP * (3 if boss else 1), color, 6)
	if hp <= 0:
		dead = true
		if beast:
			beast.reset()
		if is_instance_valid(telegraph):
			telegraph.queue_free()
		game.on_enemy_defeated(self)
		game.pulse(global_position + Vector3.UP, color, 3 if boss else 1.8, 0.7)
		visible = false
		collision_layer = 0
