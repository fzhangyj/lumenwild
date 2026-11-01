class_name CharacterGrowth
extends Node3D

const BOOK_NAMES = ["旅途札记", "冒险心得", "星辉典藏"]
const BOOK_XP = [100, 500, 2000]
const BOOK_COLORS = [Color("8cbfae"), Color("84b5e1"), Color("c4a1e5")]
const SPECIALTIES = ["风铃羽叶", "烬心花", "潮音螺", "鸣电果", "磐纹矿", "月露铃兰", "赤羽蕊", "夜镜晶", "沧海珠", "墨纹石", "余烬翎花", "霜月莲", "朔风籽", "玄雷芽", "曜星穗", "丹砂髓", "晨焰芽", "森心绒叶", "琥珀木芯", "雾弦珊瑚", "曦光花", "星弦矿", "青羽草"]
const CENTERS = [Vector2(-53,34), Vector2(61,27), Vector2(-67,-27), Vector2(59,-49), Vector2(-30,-76)]
const RESPAWN_SECONDS = 600.0
const COMMON = 28
var game: LumenGame
var levels: Array[int] = []
var experience: Array[int] = []
var ascensions: Array[int] = []
var books: Array[int] = [0,0,0]
var materials: Array[int] = []
var nodes: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var next_drop_id = 0
var tracked_material = -1
var notice = "击败怪物拾取经验书，使用经验书培养已获得的角色。"
var loot_rng = RandomNumberGenerator.new()
var pickup_timer = 0.0

func _ready() -> void:
	loot_rng.randomize()
	reset()
	_build_gathering()

func reset() -> void:
	levels.assign([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1])
	experience.resize(GameData.CHARACTER_COUNT)
	experience.fill(0)
	ascensions.resize(GameData.CHARACTER_COUNT)
	ascensions.fill(0)
	books = [0,0,0]
	materials.resize(29)
	materials.fill(0)
	for drop in drops:
		drop["root"].queue_free()
	drops.clear()
	next_drop_id = 0
	tracked_material = -1
	pickup_timer = 0
	notice = "击败怪物拾取经验书，使用经验书培养已获得的角色。"
	for point in nodes:
		point["ready_at"] = 0.0
		point["root"].visible = true

func cap(index: int) -> int:
	return 20 + ascensions[index] * 20

func needed(level: int) -> int:
	return 100 + (level - 1) * 25

func damage_multiplier(index: int) -> float:
	return 1.0 + (levels[index] - 1) * 0.018 + ascensions[index] * 0.10

func damage_taken(index: int) -> float:
	return 1.0 / (1.0 + (levels[index] - 1) * 0.006 + ascensions[index] * 0.05)

func _settle_xp(index: int) -> void:
	while levels[index] < cap(index) and experience[index] >= needed(levels[index]):
		experience[index] -= needed(levels[index])
		levels[index] += 1

func use_book(index: int, kind: int, quantity: int = 1) -> bool:
	if index < 0 or index >= GameData.CHARACTER_COUNT or kind < 0 or kind > 2 or quantity < 1 or quantity > 10:
		return false
	if not game.wishes.has_character(index) or levels[index] >= cap(index) or books[kind] <= 0:
		return false
	var previous = to_dict()
	var used = 0
	while used < quantity and books[kind] > 0 and levels[index] < cap(index):
		books[kind] -= 1
		experience[index] += BOOK_XP[kind]
		_settle_xp(index)
		used += 1
	if not game.save_game():
		restore(previous)
		notice = "存档失败，本次经验书已退回。"
		return false
	notice = "使用 %s ×%d，%s 达到 Lv.%d。" % [BOOK_NAMES[kind], used, GameData.character(index)["name"], levels[index]]
	game.audio.tone(760,0.22,0.2)
	return true

func costs(index: int) -> Dictionary:
	return {index: 3 * (ascensions[index] + 1), 23 + GameData.element_of(index): 2 * (ascensions[index] + 1), COMMON: 4 * (ascensions[index] + 1)}

func can_ascend(index: int) -> bool:
	if not game.wishes.has_character(index) or ascensions[index] >= 2 or levels[index] != cap(index):
		return false
	for item in costs(index):
		if materials[item] < costs(index)[item]:
			return false
	return true

func ascend(index: int) -> bool:
	if index < 0 or index >= GameData.CHARACTER_COUNT or not can_ascend(index):
		return false
	var previous = to_dict()
	for item in costs(index):
		materials[item] -= costs(index)[item]
	ascensions[index] += 1
	_settle_xp(index)
	if not game.save_game():
		restore(previous)
		notice = "存档失败，突破材料已退回。"
		return false
	notice = "%s 突破成功，等级上限提升至 %d！" % [GameData.character(index)["name"], cap(index)]
	game.audio.tone(1046,0.4,0.25)
	return true

func material_name(item: int) -> String:
	if item < 23:
		return SPECIALTIES[item]
	return "蚀光碎片" if item == COMMON else GameData.CHARACTERS[item - 23]["element"] + "辉晶"

func material_region(item: int) -> String:
	if item == COMMON:
		return "击败任意怪物后拾取"
	var element = GameData.element_of(item) if item < 23 else item - 23
	return GameData.SHRINES[element]["name"] + "周边 · F 采集"

func track(item: int) -> void:
	tracked_material = item
	game.close_overlay()
	game.toast("正在追踪 " + material_name(item) + " · M 查看采集位置",5)

func target() -> Dictionary:
	var result: Dictionary = {}
	var waiting: Dictionary = {}
	var distance = INF
	for point in nodes:
		if point["item"] != tracked_material:
			continue
		if point["ready_at"] > game.play_time:
			if waiting.is_empty() or point["ready_at"] < waiting["ready_at"]:
				waiting = point
			continue
		var d = game.player.position.distance_to(point["pos"])
		if d < distance:
			distance = d
			result = point
	return waiting if result.is_empty() else result

func _build_gathering() -> void:
	var element_slots = [0,0,0,0,0]
	for item in range(28):
		var element = GameData.element_of(item) if item < 23 else item - 23
		var slot: int = element_slots[element]
		element_slots[element] += 1
		for copy in range(3):
			var a = slot * 0.93 + copy * TAU / 3 + element * 0.31
			var xz: Vector2 = CENTERS[element] + Vector2(cos(a), sin(a)) * (11 + (slot % 3) * 4)
			var pos = game.world.solids.resolve(WildWorld.ground(xz.x,xz.y,0.04),0.8)
			# The tidal basin is water; samples on its edge move toward the dry eastern bank.
			while WildWorld.height_at(pos.x,pos.z) < 1.0:
				pos.x += 2
				pos = WildWorld.ground(pos.x,pos.z,0.04)
			pos = game.world.solids.resolve(pos,0.8)
			var visual = Node3D.new()
			add_child(visual)
			visual.position = pos
			_build_material(visual,item,element)
			nodes.append({"item": item, "pos": pos, "ready_at": 0.0, "root": visual})

func _build_material(visual: Node3D, item: int, element: int) -> void:
	var color = GameData.element_color(element)
	if item >= 23 or element == 4 or item in [7,21]:
		Models.sphere(visual,Vector3(0,0.12,0),Vector3(0.70,0.28,0.58),Color("6c7980"))
		for i in range(3):
			Models.crystal(visual,Vector3((i-1)*0.18,0.40,0.10*(i%2)),0.44 + i * 0.08,color)
	else:
		Models.cylinder(visual,Vector3(0,0.33,0),0.025,0.66,Color("568166"),0.015,8)
		for side in [-1,1]:
			CharacterSculpt.leaf(visual,Vector3(0,0.20,0),Vector3(side*0.30,0.42,0.09),0.10,Color("689374"),0.018)
		for i in range(5):
			var a = i * TAU/5
			CharacterSculpt.leaf(visual,Vector3(0,0.53,0),Vector3(cos(a)*0.28,0.68,sin(a)*0.28),0.09,color,0.026)
		Models.sphere(visual,Vector3(0,0.65,0),Vector3.ONE*0.13,Color("f6e4ab"),0.3)
	var mote = Models.crystal(visual,Vector3(0,1.0,0),0.10,color)
	mote.name = "Mote"

func nearby() -> int:
	var result = -1
	var nearest = 2.4
	for i in range(nodes.size()):
		if nodes[i]["ready_at"] > game.play_time:
			continue
		var distance = game.player.position.distance_to(nodes[i]["pos"])
		if distance < nearest:
			nearest = distance
			result = i
	return result

func gather(index: int) -> bool:
	if index < 0 or index >= nodes.size() or nodes[index]["ready_at"] > game.play_time:
		return false
	var point: Dictionary = nodes[index]
	if game.player.position.distance_to(point["pos"]) > 2.5:
		return false
	materials[point["item"]] += 2
	var old_time: float = point["ready_at"]
	point["ready_at"] = game.play_time + RESPAWN_SECONDS
	if not game.save_game():
		materials[point["item"]] -= 2
		point["ready_at"] = old_time
		return false
	point["root"].visible = false
	game.toast("采集 " + material_name(point["item"]) + " ×2 · 探索十分钟后再生")
	game.pulse(point["pos"] + Vector3.UP*0.2,GameData.element_color(GameData.element_of(point["item"]) if point["item"] < 23 else point["item"]-23),1.2,0.4)
	return true

func spawn_drop(enemy: HollowEnemy) -> void:
	var quantities = [2,0,0]
	if enemy.boss:
		quantities = [0,4,1]
	else:
		if loot_rng.randf() < 0.25:
			quantities[1] = 1
		if loot_rng.randf() < 0.05:
			quantities[2] = 1
	var pos = game.world.solids.resolve(WildWorld.ground(enemy.position.x,enemy.position.z,0.12),0.5)
	if drops.size() >= 64:
		for i in range(3):
			drops[0]["books"][i] += quantities[i]
		drops[0]["shards"] += 4 if enemy.boss else 1
		return
	var drop = {"id": next_drop_id, "pos": pos, "books": quantities, "shards": 4 if enemy.boss else 1}
	next_drop_id += 1
	_make_drop(drop)
	drops.append(drop)

func _make_drop(drop: Dictionary) -> void:
	var visual = Node3D.new()
	add_child(visual)
	visual.position = drop["pos"]
	var kind = 2 if drop["books"][2] > 0 else (1 if drop["books"][1] > 0 else 0)
	var cover = Models.box(visual,Vector3(0,0.30,0),Vector3(0.42,0.07,0.56),BOOK_COLORS[kind])
	cover.rotation.y = 0.22
	Models.box(visual,Vector3(0,0.35,0),Vector3(0.35,0.07,0.49),Color("eee2c6")).rotation.y = 0.22
	Models.box(visual,Vector3(0,0.40,0),Vector3(0.42,0.035,0.56),BOOK_COLORS[kind]).rotation.y = 0.22
	Models.crystal(visual,Vector3(0,0.73,0),0.15,BOOK_COLORS[kind])
	drop["root"] = visual

func collect_drop(id: int) -> bool:
	for drop in drops:
		if drop["id"] != id or game.player.position.distance_to(drop["pos"]) > 2.8:
			continue
		for i in range(3):
			books[i] += drop["books"][i]
		materials[COMMON] += drop["shards"]
		drops.erase(drop)
		if not game.save_game():
			for i in range(3):
				books[i] -= drop["books"][i]
			materials[COMMON] -= drop["shards"]
			drops.append(drop)
			return false
		drop["root"].queue_free()
		var items: Array[String] = []
		for i in range(3):
			if drop["books"][i] > 0:
				items.append(BOOK_NAMES[i] + " ×" + str(drop["books"][i]))
		items.append("蚀光碎片 ×" + str(drop["shards"]))
		game.toast("拾取 " + " · ".join(items) + " · U 培养角色",4)
		return true
	return false

func _process(delta: float) -> void:
	if not game.is_playing():
		return
	for point in nodes:
		point["root"].visible = point["ready_at"] <= game.play_time
		if point["root"].visible:
			point["root"].get_node("Mote").rotation.y += delta * 0.8
	pickup_timer -= delta
	if pickup_timer > 0:
		return
	pickup_timer = 0.2
	for drop in drops.duplicate():
		if game.player.position.distance_to(drop["pos"]) < 2.0:
			if not collect_drop(drop["id"]):
				pickup_timer = 1.0
				break

func to_dict() -> Dictionary:
	var collected: Dictionary = {}
	for i in range(nodes.size()):
		if nodes[i]["ready_at"] > game.play_time:
			collected[str(i)] = nodes[i]["ready_at"]
	var pending: Array = []
	for drop in drops:
		var p: Vector3 = drop["pos"]
		pending.append({"id":drop["id"],"pos":[p.x,p.y,p.z],"books":drop["books"].duplicate(),"shards":drop["shards"]})
	return {"levels":levels.duplicate(),"xp":experience.duplicate(),"ascensions":ascensions.duplicate(),"books":books.duplicate(),"materials":materials.duplicate(),"collected":collected,"drops":pending,"next_drop_id":next_drop_id,"tracked":tracked_material}

func _numbers(data: Dictionary, key: String, count: int, default_value: int, maximum: int) -> Array[int]:
	var result: Array[int] = []
	var values = data.get(key,[])
	for i in range(count):
		var value = values[i] if values is Array and i < values.size() else default_value
		result.append(clampi(int(value),0,maximum) if value is float or value is int else default_value)
	return result

func restore(value: Variant) -> void:
	reset()
	if not value is Dictionary:
		return
	var data: Dictionary = value
	ascensions = _numbers(data,"ascensions",23,0,2)
	levels = _numbers(data,"levels",23,1,60)
	experience = _numbers(data,"xp",23,0,1000000)
	books = _numbers(data,"books",3,0,1000000)
	materials = _numbers(data,"materials",29,0,1000000)
	for i in range(23):
		levels[i] = clampi(levels[i],1,cap(i))
	var collected = data.get("collected",{})
	if collected is Dictionary:
		for key in collected:
			if not str(key).is_valid_int():
				continue
			var i = int(key)
			if i >= 0 and i < nodes.size() and (collected[key] is float or collected[key] is int):
				nodes[i]["ready_at"] = clampf(float(collected[key]),0,game.play_time+RESPAWN_SECONDS)
				nodes[i]["root"].visible = nodes[i]["ready_at"] <= game.play_time
	tracked_material = clampi(int(data.get("tracked",-1)),-1,28)
	var pending = data.get("drops",[])
	if pending is Array:
		for saved in pending.slice(0,64):
			if not saved is Dictionary or not saved.get("pos") is Array or saved["pos"].size() != 3:
				continue
			var p = saved["pos"]
			if not (p[0] is float or p[0] is int) or not (p[1] is float or p[1] is int) or not (p[2] is float or p[2] is int):
				continue
			var pos = Vector3(float(p[0]),float(p[1]),float(p[2]))
			if not pos.is_finite() or Vector2(pos.x,pos.z).length() > 165:
				continue
			var drop = {"id":next_drop_id,"pos":game.world.solids.resolve(pos,0.5),"books":_numbers(saved,"books",3,0,1000000),"shards":clampi(int(saved.get("shards",0)),0,1000000)}
			next_drop_id += 1
			_make_drop(drop)
			drops.append(drop)
