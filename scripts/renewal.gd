class_name WorldRenewal
extends Node

const ENEMY_SLOTS = 14
const CHEST_THRESHOLD = 15
const ENEMY_THRESHOLD = 12
var game: LumenGame
var chest_wave = 1
var enemy_wave = 1
var collected_total = 0
var pending = false
var initial_chests: Array[Vector3] = []
var initial_enemies: Array[Dictionary] = []

func _ready() -> void:
	for chest in game.world.chests:
		initial_chests.append(chest["pos"])
	for enemy in game.enemies.slice(0, ENEMY_SLOTS):
		initial_enemies.append({"home": enemy.home, "shrine": enemy.shrine_index})

func reset() -> void:
	chest_wave = 1
	enemy_wave = 1
	collected_total = 0
	for i in range(initial_chests.size()):
		_set_chest(i, initial_chests[i])
	for i in range(initial_enemies.size()):
		game.enemies[i].home = initial_enemies[i]["home"]
		game.enemies[i].shrine_index = initial_enemies[i]["shrine"]

func _set_chest(index: int, pos: Vector3) -> void:
	pos = game.world.solids.resolve(pos, 1.05)
	var chest: Dictionary = game.world.chests[index]
	chest["pos"] = pos
	chest["root"].position = pos
	chest["opened"] = false
	chest["lid"].rotation = Vector3.ZERO
	chest["lid"].position = Vector3(0, 0.98, 0)

func request_check() -> void:
	if not pending:
		pending = true
		_refresh.call_deferred()

func dead_count() -> int:
	var count = 0
	for enemy in game.enemies.slice(0, ENEMY_SLOTS):
		if enemy.dead:
			count += 1
	return count

func _refresh() -> void:
	pending = false
	var notes: Array[String] = []
	if game.opened_chest_count() >= CHEST_THRESHOLD:
		var slots: Array[int] = []
		for i in range(game.world.chests.size()):
			if game.world.chests[i]["opened"]:
				slots.append(i)
		var positions = _positions(slots.size(), chest_wave * 701 + 31)
		if positions.size() == slots.size():
			for i in range(slots.size()):
				_set_chest(slots[i], positions[i])
			chest_wave += 1
			notes.append("宝箱第 %d 轮 · 新增 %d 只" % [chest_wave, slots.size()])
	if dead_count() >= ENEMY_THRESHOLD:
		var slots: Array[int] = []
		for i in range(ENEMY_SLOTS):
			if game.enemies[i].dead:
				slots.append(i)
		var positions = _positions(slots.size(), enemy_wave * 997 + 73)
		if positions.size() == slots.size():
			for i in range(slots.size()):
				_respawn(game.enemies[slots[i]], positions[i] + Vector3.UP * 0.3)
			enemy_wave += 1
			notes.append("野怪第 %d 轮 · 新增 %d 只" % [enemy_wave, slots.size()])
	if not notes.is_empty():
		game.toast(" / ".join(notes) + " · M 查看地图", 6)
		game.save_game()

func _respawn(enemy: HollowEnemy, pos: Vector3) -> void:
	game.arts.forget_enemy(enemy)
	if enemy.beast:
		enemy.beast.reset()
	if is_instance_valid(enemy.telegraph):
		enemy.telegraph.queue_free()
		enemy.telegraph = null
	enemy.home = pos
	enemy.position = pos
	enemy.shrine_index = -1
	enemy.dead = false
	enemy.visible = true
	enemy.awakened = true
	enemy.collision_layer = 4
	enemy.hp = enemy.max_hp
	enemy.health_bar.scale.x = 1
	enemy.velocity = Vector3.ZERO
	enemy.engaged = false
	enemy.element = -1
	enemy.element_time = 0
	enemy.burn_time = 0
	enemy.burn_tick = 0
	enemy.windup = -1
	enemy.stagger = 0
	enemy.attack_timer = 2

# Plan the complete batch first, retaining all unopened chests and living enemies.
func _positions(count: int, seed_value: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var occupied: Array[Vector3] = []
	for chest in game.world.chests:
		occupied.append(chest["pos"])
	for enemy in game.enemies:
		if not enemy.dead:
			occupied.append(enemy.home)
	var shape = SphereShape3D.new()
	shape.radius = 0.85
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	for attempt in range(5000):
		var pos = WildWorld.ground(rng.randf_range(-109, 109), rng.randf_range(-99, 103))
		if not _safe_ground(pos) or pos.distance_to(game.player.position) < 22:
			continue
		var crowded = false
		for other in occupied:
			if other.distance_to(pos) < 7:
				crowded = true
				break
		if crowded:
			continue
		query.transform = Transform3D(Basis(), pos + Vector3.UP * 1.05)
		if not game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			continue
		result.append(pos)
		occupied.append(pos)
		if result.size() == count:
			break
	return result

func _safe_ground(pos: Vector3) -> bool:
	if pos.y < 1.5 or Vector2(pos.x, pos.z).length() > 118:
		return false
	if absf(pos.x) < 40 and pos.z > 45 and pos.z < 91:
		return false
	if Vector2(pos.x + 91, pos.z + 27).length() < 21:
		return false
	for offset in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		if absf(WildWorld.height_at(pos.x + offset.x, pos.z + offset.y) - pos.y) > 0.65:
			return false
	for shrine in game.world.shrines:
		if pos.distance_to(shrine["pos"]) < 11:
			return false
	for point in game.campaign.points:
		if pos.distance_to(point["pos"]) < 9:
			return false
	for enemy in game.enemies:
		if enemy.boss and pos.distance_to(enemy.home) < 26:
			return false
	return true

func to_dict() -> Dictionary:
	var chests: Array = []
	var enemies: Array = []
	for chest in game.world.chests:
		chests.append([chest["pos"].x, chest["pos"].z])
	for enemy in game.enemies.slice(0, ENEMY_SLOTS):
		enemies.append([enemy.home.x, enemy.home.z, enemy.shrine_index])
	return {"chest_wave": chest_wave, "enemy_wave": enemy_wave, "collected": collected_total, "chests": chests, "enemies": enemies}

func restore(data: Dictionary) -> void:
	chest_wave = maxi(1, int(data.get("chest_wave", 1)))
	enemy_wave = maxi(1, int(data.get("enemy_wave", 1)))
	collected_total = maxi(0, int(data.get("collected", 0)))
	var chests = data.get("chests", [])
	if chests is Array and chests.size() == initial_chests.size():
		for i in range(chests.size()):
			if _valid_row(chests[i], 2):
				_set_chest(i, WildWorld.ground(float(chests[i][0]), float(chests[i][1])))
	var enemies = data.get("enemies", [])
	if enemies is Array and enemies.size() == ENEMY_SLOTS:
		for i in range(ENEMY_SLOTS):
			if _valid_row(enemies[i], 3):
				var enemy: HollowEnemy = game.enemies[i]
				enemy.home = game.world.solids.resolve(WildWorld.ground(float(enemies[i][0]), float(enemies[i][1]), 0.3), 0.9)
				enemy.position = enemy.home
				var shrine = int(enemies[i][2])
				enemy.shrine_index = shrine if shrine == initial_enemies[i]["shrine"] else -1

func _valid_row(row: Variant, length: int) -> bool:
	return row is Array and row.size() == length and is_finite(float(row[0])) and is_finite(float(row[1])) and absf(float(row[0])) < 160 and absf(float(row[1])) < 160
