class_name LumenCampaign
extends Node3D

const POINTS = [
	{"stage": 5, "name": "潮痕残页 · 回航", "xz": Vector2(-104, -12), "element": -1, "line": "栖月留下的航记：风停之前，湖底曾传来三次钟声。"},
	{"stage": 5, "name": "潮痕残页 · 旧港", "xz": Vector2(-73, -56), "element": -1, "line": "褪色的船票：同一个名字，重复出现了三万六千次。每一张票的日期，竟然都是同一天。"},
	{"stage": 5, "name": "潮痕残页 · 来信", "xz": Vector2(-105, -49), "element": -1, "line": "信的末尾写着：点亮潮灯。若海底的街道灯火通明，别停下——那不是家，是昨日的回声。"},
	{"stage": 6, "name": "潮灯 · 记忆", "xz": Vector2(-69, -14), "element": 2, "line": "澜音：这一次，我记得歌的下一句了。"},
	{"stage": 6, "name": "潮灯 · 航向", "xz": Vector2(-112, -33), "element": 0, "line": "岚羽：愿这束风，把思念送到彼岸。"},
	{"stage": 6, "name": "潮灯 · 归家", "xz": Vector2(-89, -56), "element": 1, "line": "朱烬：灯火的意义，从来都是有人在等待。"},
	{"stage": 10, "name": "星图残卷 · 晨星", "xz": Vector2(93, 42), "element": -1, "line": "绯曜的手记：无光者会在星环重启时苏醒。它惧怕的不是火，是火中的希望。"},
	{"stage": 10, "name": "星图残卷 · 星隙", "xz": Vector2(94, -8), "element": -1, "line": "镜夜的记录：只要三座航标仍在，黑夜便无法吞没星屿。"},
	{"stage": 10, "name": "星图残卷 · 归航", "xz": Vector2(83, -73), "element": -1, "line": "拼合的星图指向观测庭：真正的黎明，需要由活着的人共同点亮。"},
	{"stage": 11, "name": "星航标 · 大地", "xz": Vector2(75, 3), "element": 4, "line": "砾川：我会让大地记住，所有愿意归来的人。"},
	{"stage": 11, "name": "星航标 · 长夜", "xz": Vector2(85, -37), "element": 3, "line": "霁霆：导师没有走完的路，今天由我们接着走。"},
	{"stage": 11, "name": "星航标 · 远风", "xz": Vector2(47, -95), "element": 0, "line": "岚羽：风会经过世界的每一个角落。现在，轮到我们回应它。"}
]

const QUESTS = {
	4: ["第二章 · 沉潮来信", "风已归来，新的信件正等待拆封。\n与阿芙交谈，开启第二章。"],
	5: ["第二章 · 湖畔失落的信", "清除残页旁的蚀光体，\n收集湖畔三张潮痕残页。"],
	6: ["第二章 · 为归人点灯", "分别以潮、风、焰元素\n点亮三座潮灯。"],
	7: ["第二章 · 潮下的回响", "前往西北旧港遗址，\n唤醒并净化忘潮的回声。"],
	8: ["第二章 · 有人等你归来", "将旧港的故事带回风铃村，\n与阿芙交谈。"],
	9: ["第三章 · 群星归航", "最后一封来信已经抵达。\n与阿芙交谈，开启第三章。"],
	10: ["第三章 · 拼合破碎星图", "击败东部的星图看守，\n寻回三张星图残卷。"],
	11: ["第三章 · 在长夜中引航", "分别以岩、雷、风元素\n激活三座星航标。"],
	12: ["第三章 · 无光之夜", "返回北方星陨观测庭，\n击败无光的司辰。"],
	13: ["第三章 · 最后一封信", "回到风铃村，\n亲手送达最后一封信。"],
	14: ["第四章 · 森心苏醒", "与阿芙交谈，回应\n来自苔庭的求援。"]
}

var game: Node3D
var points: Array = []
var completed: Array[String] = []
var bosses: Dictionary = {}
var afterlight: Afterlight

func _ready() -> void:
	for i in range(POINTS.size()):
		var data: Dictionary = POINTS[i]
		var p: Vector2 = data["xz"]
		var node = Node3D.new()
		add_child(node)
		node.position = WildWorld.ground(p.x, p.y)
		var color = GameData.element_color(data["element"]) if data["element"] >= 0 else Color("adccf2")
		Models.cylinder(node, Vector3(0, 0.07, 0), 1.8, 0.14, Color("96a8a1"), -1, 8)
		var crystal = Models.crystal(node, Vector3(0, 1.9, 0), 0.75, color)
		if data["element"] >= 0:
			Models.cylinder(node, Vector3(0, 0.8, 0), 0.3, 1.6, Color("819995"), 0.23, 6)
			Models.ring(node, Vector3(0, 2, 0), 1.0, color, 0.055)
		else:
			Models.box(node, Vector3(0, 0.55, 0), Vector3(0.8, 0.12, 0.6), Color("ecdfb3"))
		game.world._label(node, data["name"], Vector3(0, 3.4, 0), Color("f6e9c8"), 25)
		var guard: HollowEnemy = null
		if data["element"] < 0:
			guard = game._create_enemy(WildWorld.ground(p.x + 3.2, p.y + 2.4, 0.2), -10 - i, false)
			guard.customize("残响看守", 150, color, 2 if data["stage"] == 5 else 3)
		points.append({"root": node, "crystal": crystal, "pos": node.position, "data": data, "guard": guard, "id": str(i)})
	var tide = game._create_enemy(WildWorld.ground(-98, -71, 0.2), -100, true)
	tide.customize("忘潮的回声", 1060, Color("83dbee"), 2)
	bosses[7] = tide
	var final_boss = game._create_enemy(game.world.boss_position, -101, true)
	final_boss.customize("无光的司辰", 1320, Color("cc9fee"), 3)
	bosses[12] = final_boss
	# A shore-side ruin gives chapter two a distinct destination.
	for i in range(6):
		var a = float(i) * TAU / 6
		var p = WildWorld.ground(-98 + sin(a) * 8, -71 + cos(a) * 8)
		Models.cylinder(self, p + Vector3.UP * 2.1, 0.55, 4.2, Color("839f9d"), 0.45, 6)
		Models.crystal(self, p + Vector3.UP * 4.6, 0.55, Color("94d3e6"))
	afterlight = Afterlight.new()
	afterlight.game = game
	afterlight.campaign = self
	add_child(afterlight)
	sync_stage()

func sync_stage() -> void:
	for point in points:
		var done = point["id"] in completed
		var stage: int = point["data"]["stage"]
		point["root"].visible = game.quest_stage == stage and not done
		var guard = point["guard"]
		if is_instance_valid(guard):
			guard.visible = game.quest_stage == stage and not guard.dead
			guard.awakened = guard.visible
			guard.collision_layer = 4 if guard.visible else 0
	for stage in bosses:
		var boss: HollowEnemy = bosses[stage]
		boss.visible = game.quest_stage == stage and not boss.dead
		boss.collision_layer = 4 if boss.visible else 0
		if not boss.visible:
			boss.awakened = false
	if is_instance_valid(afterlight):
		afterlight.sync()

func get_interaction() -> Dictionary:
	for i in range(points.size()):
		var point: Dictionary = points[i]
		if point["data"]["stage"] != game.quest_stage or point["id"] in completed:
			continue
		if game.player.position.distance_to(point["pos"]) >= 4.6:
			continue
		var guard = point["guard"]
		var prompt = "F   拾取" + point["data"]["name"]
		var element: int = point["data"]["element"]
		if is_instance_valid(guard) and not guard.dead:
			prompt = "先击败残响看守，再拾取线索"
		elif element >= 0:
			prompt = "F   点亮" + point["data"]["name"] if GameData.element_of(game.player.character_index) == element else "切换%s元素，点亮%s" % [GameData.CHARACTERS[element]["element"], point["data"]["name"]]
		if game.quest_stage == 16 and not afterlight.can_interact(i, false):
			prompt = "陪伴萤灵抵达下一站 · 风 → 潮 → 岩"
		elif game.quest_stage == 20:
			prompt = "F   鸣钟 · 风 → 潮 → 星 · 当前需要" + points[afterlight.required_index()]["data"]["name"]
		elif game.quest_stage == 21 and not afterlight.can_interact(i, false):
			prompt = "先击败灯台周围的全部巡卫"
		return {"kind": "campaign", "index": i, "prompt": prompt}
	if bosses.has(game.quest_stage):
		var boss: HollowEnemy = bosses[game.quest_stage]
		if not boss.dead and not boss.awakened and game.player.position.distance_to(boss.home) < 15:
			return {"kind": "campaign_boss", "index": game.quest_stage, "prompt": "F   挑战" + boss.display_name}
	return {}

func interact_point(index: int) -> void:
	var point: Dictionary = points[index]
	if point["data"]["stage"] != game.quest_stage or point["id"] in completed:
		return
	if not afterlight.can_interact(index, true):
		return
	var guard = point["guard"]
	if is_instance_valid(guard) and not guard.dead:
		return
	var element: int = point["data"]["element"]
	if element >= 0 and GameData.element_of(game.player.character_index) != element:
		return
	completed.append(point["id"])
	game.coins += 100 if element < 0 else 80
	game.player.hp = minf(game.player.max_hp, game.player.hp + 30)
	game.pulse(point["pos"], Color("a6dbdc"), 4.0, 0.8)
	game.audio.tone(730, 0.3, 0.2)
	var stage = game.quest_stage
	if stage_progress(stage) == 3:
		game.quest_stage += 1
		if game.quest_stage == 16:
			afterlight.reset_escort()
	sync_stage()
	game.ui.update_quest()
	game.save_game()
	game.begin_dialogue([["残响手记", point["data"]["line"]]], func(): game.toast("线索已记录 · 获得 %d 金币 · J 查看主线进度" % (100 if element < 0 else 80), 4))

func start_boss(stage: int) -> void:
	if stage != game.quest_stage or not bosses.has(stage):
		return
	var boss: HollowEnemy = bosses[stage]
	if boss.dead or boss.awakened:
		return
	var lines = [["澜音", "那些未能送达的信，在这里变成了回声。让我把最后一段歌唱完。"], ["岚羽", "这次，不会再有人迷失归途了。"]] if stage == 7 else [["霁霆", "星图已经完整。无光者的名字，是被遗忘的恐惧。"], ["砾川", "那么，就让它记住我们。大地、长风与每一盏不曾熄灭的灯。"]]
	if stage == 17:
		lines = [["丝萝", "你守住了种子，也该看看已经发芽的森林了。"], ["珀砂", "留意三枚根刺的预警。我们要唤醒它，而非毁掉它。"]]
	elif stage == 22:
		lines = [["昭璃", "旧日的钟声被它吞进了身体。但今天的声音，不属于它。"], ["夜弦", "它展开日冕时，内圈是安全的。跟着真正的钟声走。"]]
	game.begin_dialogue(lines, func():
		boss.awakened = true
		game.player.energy = 100
		game.toast(boss.display_name + "已苏醒 · 留意红色预警", 4))

func on_enemy_defeated(enemy: HollowEnemy) -> bool:
	if not bosses.has(game.quest_stage) or bosses[game.quest_stage] != enemy:
		return false
	game.coins += 100
	game.player.hp = game.player.max_hp
	_set_stage(game.quest_stage + 1)
	game.toast("危机已解除 · 返回风铃村，与阿芙交谈", 6)
	return true

func talk_to_npc() -> void:
	if game.quest_stage >= 24 and is_instance_valid(game.sea):
		game.sea.talk()
		return
	if game.quest_stage >= 14:
		afterlight.talk()
		return
	match game.quest_stage:
		4:
			game.begin_dialogue([["阿芙 · 守灯人", "风回来以后，湖边出现了三封浸湿的旧信。它们来自早已沉没的港口。"], ["阿芙 · 守灯人", "沿着镜潮湖寻找残页，再点亮三座潮灯。那些仍在等待的人，需要一个回答。"], ["阿芙 · 守灯人", "按 G 可以进入星海祈愿，每次 60 金币，每只宝箱 30 金币。通关后会迎来新一批限定同行者，之前的保底也会保留。"]], func(): _set_stage(5))
		8:
			game.begin_dialogue([["阿芙 · 守灯人", "湖边的钟声终于停了。今天清晨，村民们梦见了那些久别的人。"], ["澜音", "他们没有怪我们来得太迟。他们只是说，记得替他们看看新的黎明。"], ["阿芙 · 守灯人", "这是大家凑出的谢礼。旧港的潜潮门也亮起来了，已经可以下潜探索。可钟庭深处的门，似乎还在等另一段旋律。"]], func():
				game.coins += 600
				_set_stage(9)
				game.mode = "overlay"
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				game.ui.show_chapter_ending(2))
		9:
			game.begin_dialogue([["阿芙 · 守灯人", "最后一封信来自霁霆的导师。星环复苏的光，也唤醒了藏在星隙里的无光者。"], ["霁霆", "东部仍散落着三片星图。拼合它们，再点亮岩、雷、风三座星航标，我们就能封住那道裂隙。"], ["岚羽", "我们已经替旧日的人点过灯。这一次，要替明天的人守住星空。"]], func(): _set_stage(10))
		13:
			game.begin_dialogue([["阿芙 · 守灯人", "你们回来了。今天的天空，和我小时候见过的一样。"], ["霁霆", "导师的最后一句话，是『不要只守护星星，也要守护仰望星星的人』。现在我终于明白了。"], ["岚羽", "这封信，终于送到了。接下来，去看看风能到达的更远处吧。"]], func():
				game.coins += 800
				_set_stage(14)
				game.mode = "overlay"
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				game.ui.show_chapter_ending(3))
		_:
			var line = "当一轮宝箱或野怪清空八成时，岛屿会带来新的探索。黎明新旅的三位限定也已到来，按 G 祈愿，按 C 查看同行者。" if game.quest_stage == 14 else quest_info()[1].replace("\n", "")
			game.begin_dialogue([["阿芙 · 守灯人", line]], func():
				game.player.hp = game.player.max_hp
				game.toast("阿芙为你恢复了全部生命"))

func _set_stage(stage: int) -> void:
	game.quest_stage = stage
	sync_stage()
	game.ui.update_quest()
	game.save_game()

func stage_progress(stage: int) -> int:
	var count = 0
	for point in points:
		if point["data"]["stage"] == stage and point["id"] in completed:
			count += 1
	return count

func quest_info() -> Array:
	if game.quest_stage >= 24 and is_instance_valid(game.sea):
		return game.sea.info()
	if game.quest_stage >= 14:
		return afterlight.info(game.quest_stage)
	return QUESTS.get(game.quest_stage, QUESTS[4])

func current_target() -> Dictionary:
	if game.quest_stage >= 24 and is_instance_valid(game.sea):
		return game.sea.target()
	if game.quest_stage in [16, 20]:
		var point: Dictionary = points[afterlight.required_index()]
		if game.quest_stage == 16 and game.player.position.distance_to(afterlight.wisp.position) > 11:
			return {"pos": afterlight.wisp.position, "name": "等待你的萤灵"}
		return {"pos": point["pos"], "name": point["data"]["name"]}
	var target = {"pos": game.world.npc_position, "name": "阿芙"}
	var distance = INF
	for point in points:
		if point["data"]["stage"] == game.quest_stage and point["id"] not in completed:
			var d = game.player.position.distance_to(point["pos"])
			if d < distance:
				distance = d
				target = {"pos": point["pos"], "name": point["data"]["name"]}
	if bosses.has(game.quest_stage):
		var boss: HollowEnemy = bosses[game.quest_stage]
		target = {"pos": boss.home, "name": boss.display_name}
	return target

func restore(data: Array) -> void:
	completed.clear()
	for id in data:
		if str(id).is_valid_int() and int(id) >= 0 and int(id) < points.size() and str(id) not in completed:
			completed.append(str(id))
	sync_stage()
	afterlight.reset_escort()
