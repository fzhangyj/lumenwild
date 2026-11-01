class_name Afterlight
extends Node3D

const POINTS = [
	{"stage": 15, "name": "森心种 · 萌芽", "xz": Vector2(-30, 22), "element": -1, "line": "丝萝：不是所有枯萎都意味着结束。这枚种子还在呼吸。"},
	{"stage": 15, "name": "森心种 · 年轮", "xz": Vector2(-48, 5), "element": -1, "line": "珀砂：岩层里的根须仍连在一起。守林者在等一个新的约定。"},
	{"stage": 15, "name": "森心种 · 晨露", "xz": Vector2(-18, -8), "element": -1, "line": "溟弦：泉水把记忆送来了。跟着萤灵，让它亲眼看看重生的森林。"},
	{"stage": 16, "name": "萤归路 · 风桥", "xz": Vector2(-17, 20), "element": 0, "line": "丝萝：走慢一些，它已经很久没见过有人愿意等待。"},
	{"stage": 16, "name": "萤归路 · 露泉", "xz": Vector2(-27, 4), "element": 2, "line": "溟弦：风把脚步带进泉水，森林终于听见我们了。"},
	{"stage": 16, "name": "萤归路 · 根庭", "xz": Vector2(-29, -15), "element": 4, "line": "珀砂：这是森心的门。接下来，要让守林者放下千年的警戒。"},
	{"stage": 20, "name": "晨钟 · 星", "xz": Vector2(40, 57), "element": 3, "line": "夜弦：星音不是开端，是最后的回答。"},
	{"stage": 20, "name": "晨钟 · 潮", "xz": Vector2(55, 65), "element": 2, "line": "溟弦：第二声，让潮水带走旧日的恐惧。"},
	{"stage": 20, "name": "晨钟 · 风", "xz": Vector2(65, 48), "element": 0, "line": "青羽：第一声，留给最先归来的风。"},
	{"stage": 21, "name": "守灯台 · 星火", "xz": Vector2(34, 39), "element": 1, "line": "昭璃：灯台亮了。无论旧日的阴影还剩多少，我们都有人在等待。"},
	{"stage": 21, "name": "守灯台 · 山约", "xz": Vector2(51, 12), "element": 4, "line": "珀砂：第二座灯台回应了。今天的约定，会留在明天的岩层中。"},
	{"stage": 21, "name": "守灯台 · 晨歌", "xz": Vector2(75, 58), "element": 2, "line": "夜弦：最后的和声已经完整。去钟庭吧，让那座空壳听见活人的声音。"}
]
const QUESTS = {
	14: ["第四章 · 森心苏醒", "与阿芙交谈，回应\n来自苔庭的求援。"],
	15: ["第四章 · 枯木中的心跳", "击败三处森心种的守卫，\n将种子带回林间。"],
	16: ["第四章 · 等一只萤灵", "陪伴萤灵走过风、潮、岩三站。\n它靠近后，用对应元素唤醒路标。"],
	17: ["第四章 · 千年的守候", "前往苔庭，净化缚根的守林者。\n远离它蓄力时标出的根刺。"],
	18: ["第四章 · 把春天带回家", "回到风铃村，\n把森心的新芽交给阿芙。"],
	19: ["第五章 · 晨钟之约", "与阿芙交谈，\n寻找失落的三段钟声。"],
	20: ["第五章 · 风潮星的和声", "依次敲响：风 → 潮 → 星。\n每座钟需要对应元素。"],
	21: ["第五章 · 为明天守灯", "清除三座灯台周围的敌人，\n以焰、岩、潮重燃灯台。"],
	22: ["第五章 · 黎明之前", "挑战晨钟庭的堕曜圣像。\n日冕蓄力时进入内圈或远离外圈。"],
	23: ["第五章 · 第一声晨钟", "返回村庄，让阿芙\n听见属于今天的钟声。"],
	24: ["五章主线 · 已完成", "森林重生，晨钟长鸣。\n继续探索，结识新的同行者。"]
}
const BELL_ORDER = [20, 19, 18]
var campaign: LumenCampaign
var game: LumenGame
var wisp: Node3D
var companions: Array[Node3D] = []
var escort_time = 0.0

func _ready() -> void:
	for i in range(POINTS.size()):
		var data: Dictionary = POINTS[i]
		var pos: Vector2 = data["xz"]
		var marker = Node3D.new()
		add_child(marker)
		marker.position = WildWorld.ground(pos.x, pos.y)
		var color = GameData.element_color(maxi(0, data["element"]))
		Models.cylinder(marker, Vector3(0, 0.08, 0), 1.6, 0.16, Color("abb4a1"), -1, 16)
		Models.ring(marker, Vector3(0, 0.18, 0), 1.22, color, 0.035)
		var core = Models.crystal(marker, Vector3(0, 1.8, 0), 0.55, color)
		if data["stage"] == 20:
			for side in [-1, 1]:
				Models.cylinder(marker, Vector3(side * 1.0, 1.6, 0), 0.12, 3.2, Color("8b7860"), -1, 12)
			Models.box(marker, Vector3(0, 3.2, 0), Vector3(2.5, 0.18, 0.4), Color("af946b"))
			CharacterSculpt.loft(marker, [Vector4(1.3, 0.65, 0.65, 0), Vector4(1.5, 0.5, 0.5, 0), Vector4(2.4, 0.32, 0.32, 0), Vector4(2.6, 0.13, 0.13, 0)], Color("c8a975"))
		else:
			Models.cylinder(marker, Vector3(0, 0.6, 0), 0.4, 1.1, Color("819587"), 0.25, 12)
		game.world._label(marker, data["name"], Vector3(0, 3.7, 0), Color("f4e6bf"), 27)
		var guard: HollowEnemy = null
		var guards: Array[HollowEnemy] = []
		var guard_count = 3 if data["stage"] == 21 else (1 if data["stage"] == 15 else 0)
		for j in range(guard_count):
			var enemy = game._create_enemy(WildWorld.ground(pos.x + (j - 1) * 3.8, pos.y + 4.8, 0.2), -200 - i, false)
			enemy.customize("噬芽者" if data["stage"] == 15 else "失声巡卫", 160 if j < 2 else 230, color, 4 if data["stage"] == 15 else 5)
			guards.append(enemy)
		if not guards.is_empty():
			guard = guards[0]
		campaign.points.append({"root": marker, "crystal": core, "pos": marker.position, "data": data, "guard": guard, "guards": guards, "id": str(12 + i)})
	var guardian = game._create_enemy(WildWorld.ground(-40, -35, 0.2), -300, true)
	guardian.customize("缚根的守林者", 1450, Color("b6d69f"), 4)
	campaign.bosses[17] = guardian
	var idol = game._create_enemy(WildWorld.ground(55, 87, 0.2), -301, true)
	idol.customize("堕曜圣像", 1680, Color("f5c998"), 5)
	campaign.bosses[22] = idol
	_landmark(guardian.home, true)
	_landmark(idol.home, false)
	wisp = Node3D.new()
	add_child(wisp)
	Models.sphere(wisp, Vector3.ZERO, Vector3.ONE * 0.38, Color("e5edb3"), 1.0)
	for side in [-1, 1]:
		CharacterSculpt.leaf(wisp, Vector3(side * 0.12, 0, 0), Vector3(side * 0.60, 0.25, 0), 0.14, Color("a8d8b1"), 0.02)
	game.world._label(wisp, "归巢的萤灵", Vector3(0, 0.65, 0), Color("ebedbc"), 21)
	for entry in [[17, Vector2(-7, 57)], [20, Vector2(3, 57)]]:
		var npc = Models.character(entry[0])
		add_child(npc)
		npc.position = WildWorld.ground(entry[1].x, entry[1].y)
		npc.rotation.y = PI
		game.world._label(npc, GameData.character(entry[0])["name"], Vector3(0, 2.85, 0), Color("f2dfb4"), 25)
		companions.append(npc)
	reset_escort()

func _landmark(pos: Vector3, grove: bool) -> void:
	for i in range(8):
		var a = i * TAU / 8
		var p = WildWorld.ground(pos.x + cos(a) * 12, pos.z + sin(a) * 12)
		var color = Color("657f66") if grove else Color("b3aa93")
		CharacterSculpt.loft(self, [Vector4(0, 0.6, 0.6, 0), Vector4(1, 0.35, 0.35, 0), Vector4(3.4, 0.28, 0.28, 0), Vector4(3.7, 0.52, 0.52, 0)], color, 12).position = p
		if grove:
			game.world.solids.tree(p, 0.36, 3.7)
			for j in range(3):
				Models.sphere(self, p + Vector3((j - 1) * 1.2, 4.4 + j * 0.3, 0), Vector3(3.6, 2.5, 3.2), Color("87a477"))
		else:
			Models.ring(self, p + Vector3.UP * 3.85, 0.43, Color("e3c294"), 0.055)
	game.world._label(self, "苔庭 · 森心之门" if grove else "晨钟庭 · 长昼之约", WildWorld.ground(pos.x - 11, pos.z + 3, 4.5), Color("ebdfb7"), 27)

func reset_escort() -> void:
	if not is_instance_valid(wisp):
		return
	var previous = maxi(14, 14 + campaign.stage_progress(16))
	wisp.position = campaign.points[previous]["pos"] + Vector3.UP * 1.7 if previous >= 15 else WildWorld.ground(-28, 26, 1.7)

func sync() -> void:
	if not is_instance_valid(wisp):
		return
	wisp.visible = game.quest_stage == 16
	companions[0].visible = game.quest_stage >= 14 and game.quest_stage < 19
	companions[1].visible = game.quest_stage >= 19
	for point in campaign.points.slice(12):
		for guard in point.get("guards", []):
			guard.visible = game.quest_stage == point["data"]["stage"] and not guard.dead and point["id"] not in campaign.completed
			guard.awakened = guard.visible
			guard.collision_layer = 4 if guard.visible else 0

func _process(delta: float) -> void:
	if not game.is_playing() or game.quest_stage != 16:
		return
	escort_time += delta
	var progress = campaign.stage_progress(16)
	if progress >= 3:
		return
	var target: Vector3 = campaign.points[15 + progress]["pos"] + Vector3.UP * 1.7
	if game.player.position.distance_to(wisp.position) < 12:
		wisp.position = wisp.position.move_toward(target, delta * 4.0)
		wisp.position.y = WildWorld.height_at(wisp.position.x, wisp.position.z) + 1.7 + sin(escort_time * 2) * 0.12
	wisp.rotation.y += delta * 0.3

func required_index() -> int:
	if game.quest_stage == 16:
		return 15 + mini(2, campaign.stage_progress(16))
	if game.quest_stage == 20:
		return BELL_ORDER[mini(2, campaign.stage_progress(20))]
	return -1

func can_interact(index: int, feedback: bool) -> bool:
	var point: Dictionary = campaign.points[index]
	for guard in point.get("guards", []):
		if not guard.dead:
			if feedback:
				game.toast("先清除灯台周围所有敌人")
			return false
	if game.quest_stage == 16:
		if index != required_index() or wisp.position.distance_to(point["pos"]) > 3.3:
			if feedback:
				game.toast("在萤灵身边陪它前行 · 按路标顺序风 → 潮 → 岩")
			return false
	if game.quest_stage == 20 and index != required_index():
		if feedback:
			game.toast("钟声还未接上 · 正确顺序：风 → 潮 → 星，已奏响的部分保留", 5)
		return false
	return true

func info(stage: int) -> Array:
	return QUESTS.get(stage, QUESTS[24])

func talk() -> void:
	match game.quest_stage:
		14:
			game.begin_dialogue([["阿芙", "星空回来以后，西边的林子却一夜枯黄。今早，丝萝带着一只萤灵来到村里。"], ["丝萝", "森林把最后三枚森心种藏了起来。守林者仍在驱赶所有靠近的人，它不知道长夜已经过去。"], ["珀砂", "先找回种子，再陪萤灵走过风桥、露泉与根庭。请别丢下它，它只有在你身旁才敢走。"]], func(): campaign._set_stage(15))
		18:
			game.begin_dialogue([["丝萝", "它把名字交给了新生的树。守林者终于能休息了。"], ["阿芙", "把这株新芽种在风铃旁吧。孩子们以后会知道，是谁把春天带回来的。"], ["溟弦", "泉水里还有一段未完成的钟声。森林醒来以后，东边的钟庭也开始回应了。"]], func(): _ending(4, 19, 1000))
		19:
			game.begin_dialogue([["昭璃", "我守着那座钟庭很多年，每天点灯，却从没听见它响。昨晚，有个声音终于告诉我：先风，再潮，最后是星。"], ["夜弦", "三座晨钟需要风、潮、雷元素回应。敲错也别怕，已经奏响的旋律会留下。"], ["青羽", "随后守住三座灯台。让钟声知道，等待黎明的人都还在。"]], func(): campaign._set_stage(20))
		23:
			game.begin_dialogue([["阿芙", "听见了吗？风铃之后，是晨钟。今天，整座岛都醒过来了。"], ["昭璃", "我以为自己守的是一座旧钟。原来我守着的，是大家还会回来的约定。"], ["青羽", "钟停了，海底却又响了一声。我带回一张湿透的明信片——阿芙，为什么上面是你曾祖母的名字？"]], func(): _ending(5, 24, 1200))
		_:
			game.begin_dialogue([["阿芙", info(game.quest_stage)[1].replace("\n", "")]], func(): game.player.hp = game.player.max_hp)

func _ending(chapter: int, stage: int, reward: int) -> void:
	game.coins += reward
	campaign._set_stage(stage)
	game.mode = "overlay"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.ui.show_afterlight_ending(chapter)
