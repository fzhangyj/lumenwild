class_name BeastCombat
extends RefCounted

var enemy: HollowEnemy
var charge_time = 0.0
var charge_direction = Vector3.ZERO
var charge_hit = false
var bolts: Array[Dictionary] = []
var claw_points: Array[Vector3] = []
var evade_direction = Vector3.ZERO
var evade_time = 0.0

func reset() -> void:
	charge_time = 0
	charge_hit = false
	evade_time = 0
	claw_points.clear()
	for bolt in bolts:
		if is_instance_valid(bolt["root"]):
			bolt["root"].queue_free()
	bolts.clear()
	if is_instance_valid(enemy.visual):
		enemy.visual.scale = Vector3.ONE

func tick(delta: float) -> void:
	_tick_bolts(delta)
	var difference = enemy.game.player.position - enemy.position
	difference.y = 0
	var distance = difference.length()
	var direction = difference.normalized()
	var previous = enemy.position
	var moving = false
	var charging = charge_time > 0
	if charge_time > 0:
		charge_time = maxf(0, charge_time - delta)
		enemy.velocity.x = charge_direction.x * 17
		enemy.velocity.z = charge_direction.z * 17
		moving = true
	elif enemy.windup >= 0:
		enemy.windup -= delta
		enemy.velocity.x = 0
		enemy.velocity.z = 0
		if enemy.kind == 1:
			enemy.visual.position.y = sin(PI * clampf(1 - enemy.windup / 0.9, 0, 1)) * 1.4
		if enemy.windup < 0:
			finish()
	elif enemy.engaged and enemy.stagger <= 0:
		enemy.visual.rotation.y = lerp_angle(enemy.visual.rotation.y, atan2(-direction.x, -direction.z), delta * 5)
		var reach = [0, 3.1, 9.5, 16.0, 3.5][enemy.kind]
		var speed = [0, 3.2, 4.6, 3.5, 2.6][enemy.kind]
		var desired = direction if distance > (10 if enemy.kind == 3 else 2.5) else Vector3.ZERO
		if enemy.kind == 3 and distance < 6:
			desired = -direction
		desired = _steer(desired, delta)
		enemy.velocity.x = desired.x * speed
		enemy.velocity.z = desired.z * speed
		moving = desired.length() > 0.1
		enemy.attack_timer -= delta
		if enemy.attack_timer <= 0 and distance < reach and _line_clear(enemy.game.player.position):
			start()
	else:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0, delta * 20)
		enemy.velocity.z = move_toward(enemy.velocity.z, 0, delta * 20)
	if not enemy.is_on_floor():
		enemy.velocity.y -= delta * 20
	enemy.move_and_slide()
	if charging:
		for i in range(enemy.get_slide_collision_count()):
			if absf(enemy.get_slide_collision(i).get_normal().y) < 0.6:
				charge_time = 0
				enemy.stagger = 0.8
		var closest = Geometry3D.get_closest_point_to_segment(enemy.game.player.position, previous, enemy.position)
		if not charge_hit and closest.distance_to(enemy.game.player.position) < 1.35:
			charge_hit = true
			enemy.game.player.take_damage(19)
	if enemy.kind == 1 and enemy.windup < 0:
		var squash = sin(enemy.elapsed * 6) * 0.055
		enemy.visual.scale = Vector3(1 + squash, 1 - squash, 1 + squash)
	if enemy.kind == 2:
		for side in [-1, 1]:
			for fore in [-1, 1]:
				enemy.visual.get_node("Paw%d%d" % [side, fore]).rotation.x = sin(enemy.elapsed * 10 + (PI if side == fore else 0)) * (0.30 if moving else 0.025)
	if enemy.kind == 4:
		for side in [-1, 1]:
			enemy.visual.get_node("ClawL" if side < 0 else "ClawR").rotation.y = side * (0.45 if enemy.windup >= 0 else sin(enemy.elapsed * 2) * 0.06)
	if enemy.position.distance_to(enemy.home) > 28 and not enemy.engaged:
		enemy.position = enemy.home

func _line_clear(target: Vector3) -> bool:
	var query = PhysicsRayQueryParameters3D.create(enemy.position + Vector3.UP * 1.0, target + Vector3.UP * 1.0, 1)
	return enemy.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _steer(desired: Vector3, delta: float) -> Vector3:
	evade_time = maxf(0, evade_time - delta)
	if desired.length() < 0.1:
		return Vector3.ZERO
	if evade_time > 0:
		return evade_direction
	if _line_clear(enemy.position + desired * 2.1):
		return desired
	for angle in [PI * 0.4, -PI * 0.4, PI * 0.7, -PI * 0.7]:
		var candidate = desired.rotated(Vector3.UP, angle)
		if _line_clear(enemy.position + candidate * 2.1):
			evade_direction = candidate
			evade_time = 0.55
			return candidate
	return Vector3.ZERO

func start() -> void:
	var game: LumenGame = enemy.game
	enemy.attack_point = WildWorld.ground(enemy.position.x, enemy.position.z, 0.14)
	enemy.windup = 0.9
	match enemy.kind:
		1:
			enemy.telegraph = Models.ring(game, enemy.attack_point, 3.3, Color("ed997e"), 0.08)
		2:
			charge_direction = (game.player.position - enemy.position) * Vector3(1, 0, 1)
			charge_direction = charge_direction.normalized()
			enemy.telegraph = Models.box(game, enemy.attack_point + charge_direction * 6, Vector3(1.8, 0.05, 12), Color("edac88"))
			enemy.telegraph.rotation.y = atan2(charge_direction.x, charge_direction.z)
			enemy.windup = 1.0
		3:
			enemy.attack_point = game.player.position + Vector3.UP * 1.0
			enemy.telegraph = Models.ring(game, enemy.position + Vector3.UP * 2.6, 0.65, Color("9cdce9"), 0.07)
			enemy.windup = 0.8
		4:
			claw_points.clear()
			var forward = -enemy.visual.global_basis.z
			var right = enemy.visual.global_basis.x
			enemy.telegraph = Models.ring(game, enemy.attack_point, 0.85, Color("c8a4df"), 0.08)
			for side in [-1, 1]:
				var point = enemy.attack_point + forward * 2.0 + right * side * 1.15
				claw_points.append(point)
				Models.ring(enemy.telegraph, point - enemy.attack_point, 1.6, Color("e6a691"), 0.08)
			enemy.windup = 1.05

func finish() -> void:
	if is_instance_valid(enemy.telegraph):
		enemy.telegraph.queue_free()
		enemy.telegraph = null
	enemy.windup = -1
	var game: LumenGame = enemy.game
	match enemy.kind:
		1:
			enemy.visual.position.y = 0
			game.pulse(enemy.attack_point, Color("f5b477"), 3.3, 0.55)
			game.spark(enemy.attack_point + Vector3.UP * 0.5, Color("f3c786"), 14)
			if game.player.position.distance_to(enemy.attack_point) < 3.3 and _line_clear(game.player.position):
				game.player.take_damage(14)
		2:
			charge_time = 0.72
			charge_hit = false
		3:
			for angle in [-0.13, 0.0, 0.13]:
				var pos = enemy.position + Vector3.UP * 1.6
				var direction = (enemy.attack_point - pos).normalized().rotated(Vector3.UP, angle)
				var orb = Models.sphere(game, pos, Vector3.ONE * 0.42, Color("b0e6f0"), 0.65)
				bolts.append({"root": orb, "velocity": direction * 12, "life": 2.8})
		4:
			for point in claw_points:
				game.pulse(point, Color("d0b3e7"), 1.6, 0.4)
				if game.player.position.distance_to(point) < 1.6 and _line_clear(game.player.position):
					game.player.take_damage(17)
					break
	enemy.attack_timer = 3.0 if enemy.kind in [2, 3] else 2.5

func _tick_bolts(delta: float) -> void:
	for bolt in bolts.duplicate():
		var orb: Node3D = bolt["root"]
		var previous = orb.position
		var next: Vector3 = previous + bolt["velocity"] * delta
		bolt["life"] -= delta
		var query = PhysicsRayQueryParameters3D.create(previous, next, 1)
		var wall = enemy.get_world_3d().direct_space_state.intersect_ray(query)
		if not wall.is_empty():
			next = wall["position"]
		var body: Vector3 = enemy.game.player.position + Vector3.UP
		var hit = Geometry3D.get_closest_point_to_segment(body, previous, next).distance_to(body) < 0.6
		if hit:
			enemy.game.player.take_damage(11)
		if hit or not wall.is_empty() or bolt["life"] <= 0:
			orb.queue_free()
			bolts.erase(bolt)
		else:
			orb.position = next
