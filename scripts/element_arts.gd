class_name ElementArts
extends Node3D

# Timed abilities advance only during play; their owner and damage are fixed at cast.
var game: LumenGame
var active: Array[Dictionary] = []
var marks: Dictionary = {}

func forget_enemy(enemy: HollowEnemy) -> void:
	var key = enemy.get_instance_id()
	if marks.has(key):
		marks[key]["root"].queue_free()
		marks.erase(key)
	for effect in active:
		if effect.has("targets"):
			for i in range(effect["targets"].size()):
				if effect["targets"][i] == enemy:
					effect["targets"][i] = null

func clear() -> void:
	active.clear()
	marks.clear()
	for child in get_children():
		child.queue_free()

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not game.is_playing():
		return
	for effect in active.duplicate():
		effect["age"] += delta
		match effect["kind"]:
			"moon": _moon_tick(effect, delta)
			"wind_field": _wind_tick(effect)
			"dash": _dash_tick(effect)
			"phoenix": _phoenix_tick(effect)
			"chain": _chain_tick(effect)
			"judgement": _judgement_tick(effect)
			"tide_orbs": _tide_tick(effect, false)
			"tide_field": _tide_tick(effect, true)
			"stone_shield": _stone_tick(effect, false)
			"stone_field": _stone_tick(effect, true)
			"petals": _petal_tick(effect)
			"tide_lance": _lance_tick(effect)
			"sunfall": _sun_tick(effect)
		if effect["age"] >= effect["duration"]:
			effect["root"].queue_free()
			active.erase(effect)
	for key in marks.keys():
		var mark: Dictionary = marks[key]
		mark["time"] -= delta
		var enemy: HollowEnemy = mark["enemy"]
		if not is_instance_valid(enemy) or enemy.dead or mark["time"] <= 0:
			mark["root"].queue_free()
			marks.erase(key)
		else:
			mark["root"].position = enemy.position + Vector3.UP * (7 if enemy.boss else 3.4)
			mark["root"].rotation.y += delta * 1.4

func _effect(kind: String, index: int, duration: float, pos: Vector3) -> Dictionary:
	var visual = Node3D.new()
	add_child(visual)
	visual.position = pos
	var effect = {"kind": kind, "id": index, "age": 0.0, "duration": duration, "root": visual, "pos": pos, "mult": 1.3 * game.wishes.damage_multiplier(index) * game.growth.damage_multiplier(index), "tick": 0, "hit": {}}
	active.append(effect)
	return effect

func nearest(origin: Vector3, reach: float, excluded: Array = []) -> HollowEnemy:
	var result: HollowEnemy = null
	var distance = reach
	for enemy in game.enemies:
		if enemy.dead or not enemy.awakened or enemy in excluded:
			continue
		var d = origin.distance_to(enemy.position)
		if d < distance:
			distance = d
			result = enemy
	return result

func aim(reach: float) -> Vector3:
	var enemy = nearest(game.player.position, reach)
	if enemy != null:
		return enemy.position
	var forward = -game.player.avatar.global_basis.z
	return game.player.position + forward * reach

func cast(index: int, burst: bool) -> void:
	if index not in GameData.LIMITED_IDS or not game.wishes.has_character(index):
		return
	var color = GameData.character_color(index)
	game.toast(GameData.character(index)["burst" if burst else "skill"], 2)
	game.audio.tone(760 + index * 45, 0.45 if burst else 0.22, 0.2)
	var origin = game.player.position
	var element = GameData.element_of(index)
	if index == 17 and not burst:
		var effect = _effect("petals", index, 6.0, origin)
		field_visual(effect["root"], color, 5.8)
		for i in range(6):
			var a = i * TAU / 6
			CharacterSculpt.leaf(effect["root"], Vector3(cos(a) * 4, 1.1, sin(a) * 4), Vector3(cos(a + 0.3) * 5, 1.4, sin(a + 0.3) * 5), 0.35, color, 0.05)
	elif index == 19 and not burst:
		var effect = _effect("tide_lance", index, 1.15, origin)
		effect["from"] = origin + Vector3.UP * 1.3
		effect["to"] = aim(18) + Vector3.UP * 1.3
		var direction: Vector3 = (effect["to"] - effect["from"]).normalized()
		effect["to"] = effect["from"] + direction * 18
		var beam = Models.cylinder(effect["root"], (effect["to"] + effect["from"]) * 0.5 - origin, 0.11, 18, color, -1, 12)
		beam.quaternion = Quaternion(Vector3.UP, direction)
		for i in range(4):
			var ring = Models.ring(effect["root"], Vector3.UP * 1.3 + direction * (2 + i * 4), 0.5, color, 0.035)
			ring.quaternion = Quaternion(Vector3.UP, direction)
	elif index == 20:
		var target = aim(18)
		target.y = WildWorld.height_at(target.x, target.z) + 0.2
		var effect = _effect("sunfall", index, 3.8 if burst else 1.5, target)
		effect["burst"] = burst
		field_visual(effect["root"], color, 11 if burst else 7)
		var sun = Models.sphere(effect["root"], Vector3.UP * 12, Vector3.ONE * 1.6, color, 1.1)
		sun.name = "Sun"
		Models.ring(sun, Vector3.ZERO, 1.3, Color("fff0c9"), 0.06).rotation.x = PI * 0.5
		particles(effect["root"], color, 36, 6)
	elif element == 0 and not burst:
		var effect = _effect("moon", index, 1.5, origin + Vector3.UP * 1.4)
		effect["from"] = origin + Vector3.UP * 1.4
		effect["to"] = aim(18) + Vector3.UP * 1.4
		effect["previous"] = effect["from"]
		var ring = Models.ring(effect["root"], Vector3.ZERO, 1.05, color, 0.11)
		ring.rotation.x = PI * 0.5
		Models.ring(effect["root"], Vector3.ZERO, 0.72, Color("fff2b5"), 0.045).rotation.x = PI * 0.5
		for i in range(5):
			var a = i * TAU / 5
			Models.crystal(effect["root"], Vector3(sin(a), cos(a), 0), 0.3, color)
		particles(effect["root"], color, 28, 0.8)
	elif element == 0:
		var effect = _effect("wind_field", index, 10.0 if index == 14 else 8.0, origin + Vector3.UP * 0.22)
		field_visual(effect["root"], color, 12.5 if index == 14 else 10.5)
		game.pulse(origin, color, 11, 0.8)
	elif element == 1 and not burst:
		var direction = aim(12) - origin
		direction.y = 0
		if direction.length() < 0.1:
			direction = -game.player.avatar.global_basis.z
		game.player.dash_direction = direction.normalized()
		game.player.dash_time = 0.4
		game.player.gliding = false
		game.player.shield = minf(100, game.player.shield + (40 if index == 16 else 25))
		game.player.invulnerability = maxf(game.player.invulnerability, 0.4)
		var effect = _effect("dash", index, 1.3, origin)
		effect["next_trail"] = 0.0
		effect["trail"] = []
	elif element == 1:
		var target = aim(18)
		target.y = WildWorld.height_at(target.x, target.z) + 0.2
		var effect = _effect("phoenix", index, 5.5, target)
		field_visual(effect["root"], color, 8.8)
		var bird = phoenix(effect["root"], color)
		effect["bird"] = bird
		bird.position = Vector3(0, 13, -6)
	elif element == 2:
		var target = aim(18) if burst else origin
		target.y = WildWorld.height_at(target.x, target.z) + 0.2
		var effect = _effect("tide_field" if burst else "tide_orbs", index, 8.0 if burst else 2.1, target)
		field_visual(effect["root"], color, 10 if burst else 2.2)
		for i in range(6 if burst else 3):
			var a = i * TAU / (6 if burst else 3)
			var orb = Models.sphere(effect["root"], Vector3(cos(a) * (6 if burst else 2), 1.8, sin(a) * (6 if burst else 2)), Vector3.ONE * 0.6, color, 1.2)
			orb.name = "TideOrb%d" % i
		particles(effect["root"], color, 40, 7 if burst else 2)
	elif element == 4:
		var target = aim(16) if burst else origin
		target.y = WildWorld.height_at(target.x, target.z) + 0.15
		var effect = _effect("stone_field" if burst else "stone_shield", index, (5.0 if index == 15 else 4.0) if burst else 1.3, target)
		field_visual(effect["root"], color, 10 if burst else 7)
		for i in range(6):
			var a = i * TAU / 6
			var pillar = Models.crystal(effect["root"], Vector3(cos(a) * (7 if burst else 4), -0.5, sin(a) * (7 if burst else 4)), 2.4 if burst else 1.2, color)
			pillar.name = "Pillar%d" % i
		if not burst:
			game.player.shield = minf(100, game.player.shield + 55)
	elif element == 3 and not burst:
		var effect = _effect("chain", index, 0.9, origin)
		effect["targets"] = []
		var point = origin
		for i in range(5 if index == 21 else 4):
			var enemy = nearest(point, 22 if i == 0 else 9, effect["targets"])
			if enemy == null:
				break
			effect["targets"].append(enemy)
			point = enemy.position
		effect["from"] = origin + Vector3.UP * 1.5
		game.player.invulnerability = maxf(game.player.invulnerability, 0.65)
		game.pulse(origin, color, 3.5, 0.45)
		if effect["targets"].is_empty():
			game.lightning(effect["from"], aim(16) + Vector3.UP, color)
	else:
		var target = aim(18)
		target.y = WildWorld.height_at(target.x, target.z) + 0.2
		var effect = _effect("judgement", index, 3.9, target)
		field_visual(effect["root"], color, 10.0)
		var crown = Models.ring(effect["root"], Vector3(0, 9, 0), 4.8, color, 0.09)
		crown.rotation.x = 0.14
		for i in range(6):
			var a = i * TAU / 6
			Models.crystal(effect["root"], Vector3(sin(a) * 4.8, 9, cos(a) * 4.8), 0.9, color)

func _damage(enemy: HollowEnemy, amount: float, effect: Dictionary) -> void:
	if is_instance_valid(enemy) and not enemy.dead and enemy.awakened:
		enemy.damage(amount * effect["mult"], GameData.element_of(effect["id"]))

func area(effect: Dictionary, center: Vector3, radius: float, damage: float, pull: bool = false) -> void:
	for enemy in game.enemies:
		if not enemy.dead and enemy.awakened and enemy.position.distance_to(center) < radius:
			_damage(enemy, damage, effect)
			if pull and not enemy.boss and not enemy.dead:
				var direction = center - enemy.position
				direction.y = 0
				enemy.velocity = direction.normalized() * minf(8, direction.length() * 2)
				enemy.stagger = 0.4

func _moon_tick(effect: Dictionary, delta: float) -> void:
	var age: float = effect["age"]
	var returning = age >= 0.7
	var destination: Vector3 = effect["to"]
	var pos = effect["from"].lerp(destination, minf(1, age / 0.7)) if not returning else destination.lerp(game.player.position + Vector3.UP * 1.4, clampf((age - 0.7) / 0.8, 0, 1))
	var previous: Vector3 = effect["previous"]
	effect["root"].position = pos
	effect["root"].rotation.z += delta * 11
	for enemy in game.enemies:
		if enemy.dead or not enemy.awakened:
			continue
		var key = str(enemy.get_instance_id()) + ("return" if returning else "out")
		var closest = Geometry3D.get_closest_point_to_segment(enemy.position + Vector3.UP * 1.2, previous, pos)
		if not effect["hit"].has(key) and closest.distance_to(enemy.position + Vector3.UP * 1.2) < (3.4 if enemy.boss else 2.2):
			effect["hit"][key] = true
			_damage(enemy, 42 if effect["id"] in [12, 22] else 34, effect)
			game.pulse(enemy.position, GameData.character_color(effect["id"]), 2, 0.3)
	effect["previous"] = pos
	if age >= effect["duration"]:
		var healing = 6 if effect["id"] == 12 else 12
		game.player.hp = minf(game.player.max_hp, game.player.hp + healing)
		game.floating_text(game.player.position + Vector3.UP * 2.5, "+%d" % healing, Color("a5f5d5"))

func _wind_tick(effect: Dictionary) -> void:
	effect["root"].rotation.y = effect["age"] * 0.32
	var radius = 13.0 if effect["id"] == 14 else 11.0
	while effect["tick"] < (5 if effect["id"] == 14 else 4) and effect["age"] >= effect["tick"] * 2:
		effect["tick"] += 1
		area(effect, effect["pos"], radius, 36, true)
		game.pulse(effect["pos"], GameData.character_color(effect["id"]), radius, 0.9)
		if game.player.position.distance_to(effect["pos"]) < radius:
			game.player.hp = minf(game.player.max_hp, game.player.hp + 8)
			game.floating_text(game.player.position + Vector3.UP * 2, "+8", Color("a5f5d5"))

func _dash_tick(effect: Dictionary) -> void:
	var age: float = effect["age"]
	var color = GameData.character_color(effect["id"])
	if age <= 0.5:
		if age >= effect["next_trail"]:
			effect["next_trail"] += 0.06
			var p: Vector3 = game.player.position - effect["pos"]
			var feather = Models.crystal(effect["root"], p + Vector3.UP * 0.8, 1.0, color)
			feather.rotation.z = 0.5
			effect["trail"].append(feather)
			Models.ring(effect["root"], p + Vector3.UP * 0.18, 1.0, color, 0.05)
		for enemy in game.enemies:
			if not effect["hit"].has(enemy.get_instance_id()) and enemy.position.distance_to(game.player.position) < (4.0 if enemy.boss else 3.1):
				if not enemy.dead and enemy.awakened:
					effect["hit"][enemy.get_instance_id()] = true
					_damage(enemy, 64, effect)
					game.spark(enemy.position + Vector3.UP, color, 12)
	else:
		for feather in effect["trail"]:
			feather.scale = Vector3.ONE * maxf(0.05, 1.0 - (age - 0.5) / 0.8)

func _phoenix_tick(effect: Dictionary) -> void:
	var age: float = effect["age"]
	var bird: Node3D = effect["bird"]
	if age < 1:
		bird.position = Vector3(0, 13, -6).lerp(Vector3(0, 0.7, 0), age * age)
		bird.rotation.z = sin(age * 8) * 0.18
	elif effect["tick"] == 0:
		effect["tick"] = 1
		bird.visible = false
		area(effect, effect["pos"], 9, 138 if effect["id"] == 10 else 115)
		game.pulse(effect["pos"], Color("ffd08b"), 10, 0.8)
		game.spark(effect["pos"] + Vector3.UP * 2, Color("ffbc78"), 28)
	while effect["tick"] >= 1 and effect["tick"] < 5 and age >= effect["tick"] + 1:
		effect["tick"] += 1
		area(effect, effect["pos"], 9, 20)
		game.pulse(effect["pos"], GameData.character_color(effect["id"]), 9, 0.65)

func _chain_tick(effect: Dictionary) -> void:
	while effect["tick"] < effect["targets"].size() and effect["age"] >= effect["tick"] * 0.16:
		var enemy: HollowEnemy = effect["targets"][effect["tick"]]
		effect["tick"] += 1
		if not is_instance_valid(enemy) or enemy.dead or not enemy.awakened:
			continue
		var point = enemy.position + Vector3.UP * (3.5 if enemy.boss else 1.5)
		game.lightning(effect["from"], point, GameData.character_color(effect["id"]))
		game.lightning(point + Vector3.UP * 8, point, Color("ede0ff"))
		effect["from"] = point
		_damage(enemy, 53, effect)
		if not enemy.dead:
			_mark(enemy)

func _mark(enemy: HollowEnemy) -> void:
	var key = enemy.get_instance_id()
	if marks.has(key):
		marks[key]["time"] = 8.0
		return
	var visual = Node3D.new()
	add_child(visual)
	var diamond = Models.ring(visual, Vector3.ZERO, 0.52, Color("e0c7ff"), 0.075)
	diamond.rotation.x = PI * 0.5
	Models.crystal(visual, Vector3.ZERO, 0.5, Color("f2ddff"))
	marks[key] = {"enemy": enemy, "root": visual, "time": 8.0}
	visual.position = enemy.position + Vector3.UP * (7 if enemy.boss else 3.4)

func _judgement_tick(effect: Dictionary) -> void:
	effect["root"].rotation.y = effect["age"] * 0.3
	while effect["tick"] < 3 and effect["age"] >= 0.8 + effect["tick"] * 1.05:
		effect["tick"] += 1
		var color = GameData.character_color(effect["id"])
		game.pulse(effect["pos"], color, 10.5, 0.6)
		for i in range(5):
			var a: float = i * TAU / 5 + effect["tick"] * 0.4
			var point: Vector3 = effect["pos"] + Vector3(sin(a) * 6.0, 0.2, cos(a) * 6.0)
			game.lightning(point + Vector3.UP * 13, point, color)
		for enemy in game.enemies:
			if not enemy.dead and enemy.awakened and enemy.position.distance_to(effect["pos"]) < 10.5:
				var marked = marks.has(enemy.get_instance_id())
				game.lightning(enemy.position + Vector3.UP * 12, enemy.position + Vector3.UP, Color("f0dfff"))
				_damage(enemy, (64 if effect["id"] == 13 else 54) + (28 if marked else 0), effect)
				if marked:
					game.floating_text(enemy.position + Vector3.UP * 3, "雷印共鸣", Color("f0dfff"))

func _petal_tick(effect: Dictionary) -> void:
	effect["root"].position = game.player.position
	effect["root"].rotation.y = effect["age"] * 2.1
	while effect["tick"] < 4 and effect["age"] >= effect["tick"] * 1.5:
		effect["tick"] += 1
		area(effect, game.player.position, 6, 29)
		game.pulse(game.player.position, GameData.character_color(effect["id"]), 6, 0.6)

func _lance_tick(effect: Dictionary) -> void:
	while effect["tick"] < 3 and effect["age"] >= 0.10 + effect["tick"] * 0.3:
		effect["tick"] += 1
		for enemy in game.enemies:
			if enemy.dead or not enemy.awakened:
				continue
			var point = enemy.position + Vector3.UP * 1.3
			var closest = Geometry3D.get_closest_point_to_segment(point, effect["from"], effect["to"])
			if point.distance_to(closest) < 2.1:
				_damage(enemy, 33, effect)
		game.player.hp = minf(game.player.max_hp, game.player.hp + 6)
		game.floating_text(game.player.position + Vector3.UP * 2.5, "+6", GameData.character_color(effect["id"]))
	var visual: Node3D = effect["root"]
	visual.scale = Vector3.ONE * (0.96 + sin(effect["age"] * 28) * 0.04)

func _sun_tick(effect: Dictionary) -> void:
	var sun: Node3D = effect["root"].get_node("Sun")
	var phase = fmod(float(effect["age"]), 1.0)
	sun.position.y = lerpf(12, 0.8, phase * phase)
	sun.rotation.y = effect["age"] * 1.7
	while effect["tick"] < (3 if effect["burst"] else 1) and effect["age"] >= 1.0 + effect["tick"]:
		effect["tick"] += 1
		area(effect, effect["pos"], 11 if effect["burst"] else 7, 64 if effect["burst"] else 78)
		game.pulse(effect["pos"], GameData.character_color(effect["id"]), 11 if effect["burst"] else 7, 0.7)
		game.spark(effect["pos"] + Vector3.UP * 2, Color("ffdf9e"), 22)
	if effect["tick"] >= (3 if effect["burst"] else 1):
		sun.visible = false

func _tide_tick(effect: Dictionary, burst: bool) -> void:
	var color = GameData.character_color(effect["id"])
	effect["root"].rotation.y = effect["age"] * (1.2 if burst else 3.0)
	if not burst:
		effect["root"].position = game.player.position
	while effect["tick"] < (4 if burst else 3) and effect["age"] >= effect["tick"] * (2.0 if burst else 0.55):
		effect["tick"] += 1
		if burst:
			area(effect, effect["pos"], 10, 38, true)
			game.pulse(effect["pos"], color, 10, 1.1)
		else:
			var enemy = nearest(game.player.position, 18)
			if enemy != null:
				game.projectile(game.player.position + Vector3.UP * 1.8, enemy.position + Vector3.UP, color)
				_damage(enemy, 28 if effect["id"] == 11 else 34, effect)
			var orb = effect["root"].get_node_or_null("TideOrb%d" % (effect["tick"] - 1))
			if orb:
				orb.visible = false
		if not burst or game.player.position.distance_to(effect["pos"]) < 10:
			var healing = 10 if burst else (12 if effect["id"] == 11 else 8)
			game.player.hp = minf(game.player.max_hp, game.player.hp + healing)
			game.floating_text(game.player.position + Vector3.UP * 2.5, "+%d" % healing, color)

func _stone_tick(effect: Dictionary, burst: bool) -> void:
	var color = GameData.character_color(effect["id"])
	for i in range(6):
		var pillar = effect["root"].get_node("Pillar%d" % i)
		pillar.position.y = lerpf(-2.0, 1.7 if burst else 0.5, minf(1, effect["age"] * 3))
		pillar.rotation.y = effect["age"] * 0.4
	var pulses = (4 if effect["id"] == 15 else 3) if burst else 1
	while effect["tick"] < pulses and effect["age"] >= 0.35 + effect["tick"] * 1.1:
		effect["tick"] += 1
		area(effect, effect["pos"], 10 if burst else 7, 56 if burst else 62)
		game.pulse(effect["pos"], color, 10 if burst else 7, 0.7)
		game.spark(effect["pos"] + Vector3.UP, color, 16)
		if burst and game.player.position.distance_to(effect["pos"]) < 10:
			game.player.shield = minf(100, game.player.shield + 10)

func field_visual(parent: Node3D, color: Color, radius: float) -> void:
	Models.ring(parent, Vector3.ZERO, radius, color, 0.085)
	Models.ring(parent, Vector3.UP * 0.08, radius * 0.83, color, 0.035)
	for i in range(10):
		var a = i * TAU / 10
		var p = Vector3(sin(a) * radius * 0.9, 0.65, cos(a) * radius * 0.9)
		Models.crystal(parent, p, 0.65, color)
		Models.box(parent, p * Vector3(1, 0, 1), Vector3(0.08, 0.1, 1.0), color).rotation.y = a
	particles(parent, color, 48, radius * 0.7)
	var light = OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.1
	light.omni_range = radius * 1.2
	light.position.y = 2.5
	parent.add_child(light)

func particles(parent: Node3D, color: Color, amount: int, radius: float) -> void:
	var dust = CPUParticles3D.new()
	dust.amount = amount
	dust.lifetime = 1.8
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = radius
	dust.direction = Vector3.UP
	dust.spread = 25
	dust.gravity = Vector3(0, 0.3, 0)
	dust.initial_velocity_min = 0.6
	dust.initial_velocity_max = 1.7
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.2
	var mesh = SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	mesh.radial_segments = 6
	mesh.rings = 3
	dust.mesh = mesh
	dust.material_override = Models.material(color, 1.4)
	parent.add_child(dust)

func phoenix(parent: Node3D, color: Color) -> Node3D:
	var bird = Node3D.new()
	parent.add_child(bird)
	var body = Models.crystal(bird, Vector3.ZERO, 2.2, Color("fff0aa"))
	body.rotation.x = PI * 0.5
	for side in [-1, 1]:
		for i in range(5):
			var feather = Models.crystal(bird, Vector3(side * (0.7 + i * 0.6), 0.2 + i * 0.12, -i * 0.18), 2.2 - i * 0.2, color)
			feather.rotation.z = side * (-0.55 - i * 0.15)
			feather.rotation.x = 0.4
	for i in range(3):
		var tail = Models.crystal(bird, Vector3((i - 1) * 0.4, 0, -1.5), 2.3, color)
		tail.rotation.x = -PI * 0.4
	particles(bird, Color("ffc87d"), 40, 2)
	return bird
