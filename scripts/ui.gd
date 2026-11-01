class_name LumenUI
extends CanvasLayer

const INK = Color("19383f")
const CREAM = Color("f2e9d2")
const MUTED = Color("bacbc2")
const GOLD = Color("ddc78f")
var game: Node3D
var root: Control
var hud: Control
var menu: Control
var overlay: Control
var dialogue: Control
var title_label: Label
var quest_title: Label
var quest_text: Label
var quest_count: Label
var interact: Label
var location: Label
var toast_label: Label
var toast_time: float = 0
var hp_bar: LumenMeter
var stamina_bar: LumenMeter
var hp_label: Label
var current_name: Label
var shield_label: Label
var energy_label: Label
var e_label: Label
var q_label: Label
var coin_label: Label
var minimap: LumenAtlas
var map_canvas: LumenAtlas
var party_panels: Array[Panel] = []
var boss_bar: LumenMeter
var boss_container: Control
var damage_flash: ColorRect
var dialogue_name: Label
var dialogue_text: Label
var dialogue_hint: Label
var journal_page: String = ""
var modal_buttons: Array[Button] = []
var dialogue_button: Button
var dialogue_portrait: Control
var dialogue_elapsed = 0.0
var party_names: Array[Label] = []
var boss_title: Label
var potion_label: Label
var chapter_label: Label

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme = Theme.new()
	theme.default_font = load("res://assets/ui_font.tres")
	theme.default_font_size = 18
	root.theme = theme
	add_child(root)
	_build_hud()
	_build_menu()
	_build_dialogue()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	overlay.visible = false
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(0.8, 0.18, 0.09, 0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_flash)
	hud.visible = false

func _process(delta: float) -> void:
	if not is_instance_valid(game.player):
		return
	if dialogue.visible and dialogue_text.visible_ratio < 1.0:
		dialogue_elapsed += delta
		dialogue_text.visible_characters = int(dialogue_elapsed*34)
	var player: LumenPlayer = game.player
	if hud.visible:
		hp_bar.value = player.hp / player.max_hp * 100
		stamina_bar.value = player.stamina
		hp_label.text = "%d / %d" % [ceili(player.hp), int(player.max_hp)]
		current_name.text = GameData.character(player.character_index)["name"] + "  Lv.%d  /  " % game.growth.levels[player.character_index] + GameData.character(player.character_index)["title"]
		shield_label.text = "护盾  %d" % int(player.shield) if player.shield > 1 else ""
		energy_label.text = "%d%%" % int(player.energy)
		e_label.text = "E   " + ("%.1fs" % player.skill_cooldowns[player.character_index] if player.skill_cooldowns[player.character_index] > 0 else GameData.character(player.character_index)["skill"])
		q_label.text = "Q   " + ("%.1fs" % player.burst_cooldown if player.burst_cooldown > 0 else GameData.character(player.character_index)["burst"])
		if game.sea.active:
			e_label.text="E   潮汐声波"
			q_label.text="空格 上浮 / Ctrl 下潜"
		coin_label.text = "%03d  金币" % game.coins
		potion_label.text = "G 星海祈愿    R 药剂 ×%d" % game.wishes.potions
		interact.text = game.interaction_prompt
		interact.visible = game.interaction_prompt != "" and not dialogue.visible
		minimap.queue_redraw()
		for i in range(5):
			party_panels[i].modulate.a = 1.0 if game.party[i] == player.character_index else 0.64
			party_names[i].text = GameData.character(game.party[i])["name"]
		var active: HollowEnemy = game.active_boss()
		boss_container.visible = active != null
		if active != null:
			boss_bar.value = active.hp / active.max_hp * 100
			boss_title.text = active.display_name
		toast_label.position.y = 179 if boss_container.visible else 114
	toast_time -= delta
	toast_label.modulate.a = clampf(toast_time, 0, 1)
	damage_flash.color.a = maxf(0, damage_flash.color.a - delta * 0.7)
	if is_instance_valid(map_canvas) and overlay.visible:
		map_canvas.queue_redraw()

func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	_rect(menu, Rect2(0, 0, 565, 900), Color(0.04, 0.12, 0.15, 0.94))
	_rect(menu, Rect2(565, 0, 1, 900), Color(0.88, 0.80, 0.60, 0.5))
	_label(menu, "L  U  M  E  N  W  I  L  D", Vector2(72, 67), 19, GOLD, Vector2(430, 30))
	_label(menu, "一 场 与 元 素 同 行 的 冒 险", Vector2(72, 114), 15, MUTED, Vector2(400, 28))
	for i in range(5):
		_glyph(menu, i, Rect2(70 + i * 63, 208, 40, 40), GameData.element_color(i))
	title_label = _label(menu, "逐光之野", Vector2(66, 276), 78, CREAM, Vector2(485, 118))
	_rect(menu, Rect2(74, 425, 54, 2), GOLD)
	_label(menu, "第一章  /  风停之日", Vector2(146, 410), 21, GOLD, Vector2(330, 38))
	_label(menu, "当天空失去回声，\n你将循着五道微光，\n找回这片土地遗忘的黎明。", Vector2(74, 484), 22, MUTED, Vector2(400, 124))
	var button_text = "继续旅程" if game.has_save() else "踏上旅程"
	_button(menu, button_text + "    →", Rect2(74, 667, 352, 62), func(): game.start_game(true), true)
	if game.has_save():
		_button(menu, "重新启程", Rect2(74, 746, 155, 39), func(): show_new_game_confirmation())
	_label(menu, "六章主线  ·  海底探索  ·  五种元素  ·  二十三位同行者", Vector2(74, 837), 13, MUTED, Vector2(560, 22))
	_label(menu, "风铃村", Vector2(1090, 742), 31, CREAM, Vector2(280, 46), HORIZONTAL_ALIGNMENT_RIGHT)
	_label(menu, "风尚未归来，旅程已经开始。", Vector2(1000, 798), 15, CREAM, Vector2(370, 30), HORIZONTAL_ALIGNMENT_RIGHT)
	_label(menu, "WASD 移动   ·   鼠标转动视角", Vector2(1020, 848), 13, CREAM, Vector2(350, 24), HORIZONTAL_ALIGNMENT_RIGHT)

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	_label(hud, "逐光之野", Vector2(38, 27), 25, CREAM, Vector2(200, 43))
	chapter_label = _label(hud, "风  停  之  日", Vector2(39, 69), 12, GOLD, Vector2(200, 24))
	var quest_panel = _panel(hud, Rect2(34, 118, 323, 155), Color(0.05, 0.15, 0.17, 0.82), Color(0.85, 0.77, 0.55, 0.4))
	_rect(quest_panel, Rect2(0, 0, 3, 155), GOLD)
	quest_title = _label(quest_panel, "第一章 · 风停之日", Vector2(20, 13), 19, CREAM, Vector2(285, 32))
	quest_text = _label(quest_panel, "与守灯人阿芙交谈", Vector2(20, 54), 17, MUTED, Vector2(280, 67))
	quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_count = _label(quest_panel, "[J] 旅途手记", Vector2(20, 118), 12, GOLD, Vector2(280, 24))
	_label(hud, "N", Vector2(711, 25), 15, GOLD, Vector2(20, 25), HORIZONTAL_ALIGNMENT_CENTER)
	_rect(hud, Rect2(621, 40, 69, 1), Color(0.9, 0.9, 0.8, 0.4))
	_rect(hud, Rect2(751, 40, 69, 1), Color(0.9, 0.9, 0.8, 0.4))
	minimap = LumenAtlas.new()
	minimap.game = game
	minimap.position = Vector2(1218, 30)
	minimap.size = Vector2(186, 186)
	hud.add_child(minimap)
	_label(hud, "M  世界地图", Vector2(1244, 220), 13, CREAM, Vector2(148, 26), HORIZONTAL_ALIGNMENT_CENTER)
	coin_label = _label(hud, "000  金币", Vector2(1040, 34), 16, GOLD, Vector2(150, 30), HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(5):
		var p = _panel(hud, Rect2(1247, 294 + i * 70, 162, 59), Color(0.055, 0.14, 0.17, 0.8), GameData.element_color(i).darkened(0.24))
		party_panels.append(p)
		_glyph(p, i, Rect2(9, 9, 40, 40), GameData.element_color(i))
		party_names.append(_label(p, GameData.CHARACTERS[i]["name"], Vector2(58, 6), 20, CREAM, Vector2(70, 30)))
		_label(p, GameData.CHARACTERS[i]["element"] + "元素", Vector2(60, 35), 10, MUTED, Vector2(70, 20))
		_label(p, str(i + 1), Vector2(131, 17), 15, GOLD, Vector2(20, 25), HORIZONTAL_ALIGNMENT_CENTER)
	current_name = _label(hud, "岚羽", Vector2(487, 778), 17, CREAM, Vector2(470, 30), HORIZONTAL_ALIGNMENT_CENTER)
	hp_bar = _bar(hud, Rect2(519, 822, 402, 9), Color("a9d894"))
	hp_label = _label(hud, "180 / 180", Vector2(626, 839), 12, CREAM, Vector2(190, 24), HORIZONTAL_ALIGNMENT_CENTER)
	stamina_bar = _bar(hud, Rect2(565, 870, 310, 3), GOLD)
	shield_label = _label(hud, "", Vector2(923, 807), 13, GOLD, Vector2(118, 26))
	var ep = _panel(hud, Rect2(1110, 760, 135, 72), Color(0.05, 0.15, 0.17, 0.85), Color("93b9ab"))
	e_label = _label(ep, "E 回风刃", Vector2(9, 22), 17, CREAM, Vector2(117, 30), HORIZONTAL_ALIGNMENT_CENTER)
	var qp = _panel(hud, Rect2(1258, 760, 150, 72), Color(0.05, 0.15, 0.17, 0.85), GOLD)
	q_label = _label(qp, "Q 千风回响", Vector2(5, 8), 16, CREAM, Vector2(140, 30), HORIZONTAL_ALIGNMENT_CENTER)
	energy_label = _label(qp, "65%", Vector2(35, 39), 13, GOLD, Vector2(80, 23), HORIZONTAL_ALIGNMENT_CENTER)
	_label(hud, "鼠标左键 攻击  /  Shift 冲刺", Vector2(1112, 847), 12, CREAM, Vector2(296, 25), HORIZONTAL_ALIGNMENT_CENTER)
	location = _label(hud, "风铃村", Vector2(38, 767), 27, CREAM, Vector2(350, 42))
	_label(hud, "C 图鉴    U 培养    J 手记    Esc 暂停", Vector2(39, 845), 12, CREAM, Vector2(430, 25))
	potion_label = _label(hud, "G 星海祈愿    R 药剂 ×0", Vector2(39, 808), 15, GOLD, Vector2(430, 28))
	interact = _label(hud, "", Vector2(420, 640), 20, CREAM, Vector2(600, 58), HORIZONTAL_ALIGNMENT_CENTER)
	interact.add_theme_stylebox_override("normal", _style(Color(0.06, 0.16, 0.18, 0.87), Color(0.8, 0.76, 0.61, 0.6), 4))
	toast_label = _label(root, "", Vector2(360, 114), 19, CREAM, Vector2(720, 58), HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.add_theme_stylebox_override("normal", _style(Color(0.07, 0.18, 0.20, 0.91), Color(0.8, 0.76, 0.61, 0.4), 4))
	toast_label.modulate.a = 0
	toast_label.z_index = 20
	boss_container = Control.new()
	hud.add_child(boss_container)
	boss_title = _label(boss_container, "失律的天穹守卫", Vector2(468, 55), 23, CREAM, Vector2(505, 40), HORIZONTAL_ALIGNMENT_CENTER)
	_label(boss_container, "旧日的承诺 · 星核污染", Vector2(468, 94), 12, MUTED, Vector2(505, 24), HORIZONTAL_ALIGNMENT_CENTER)
	boss_bar = _bar(boss_container, Rect2(477, 131, 486, 7), Color("d3a182"))
	boss_container.visible = false

func _build_dialogue() -> void:
	dialogue = Control.new()
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dialogue)
	_rect(dialogue,Rect2(0,0,1440,60),Color(0.015,0.04,0.08,0.88))
	_rect(dialogue,Rect2(0,867,1440,33),Color(0.015,0.04,0.08,0.88))
	_label(dialogue,"L U M E N W I L D   /   旅 途 中 的 回 声",Vector2(76,17),14,GOLD,Vector2(1100,28))
	var panel = _panel(dialogue, Rect2(95, 625, 1250, 228), Color(0.025, 0.075, 0.13, 0.96), Color("7d9397"))
	_rect(panel,Rect2(0,0,1250,2),GOLD)
	dialogue_portrait = Control.new()
	dialogue_portrait.position = Vector2(0,-70)
	dialogue_portrait.size = Vector2(235,290)
	panel.add_child(dialogue_portrait)
	dialogue_name = _label(panel, "阿芙", Vector2(254, 19), 26, GOLD, Vector2(900, 42))
	_rect(panel,Rect2(254,64,64,2),GOLD)
	dialogue_text = _label(panel, "", Vector2(254, 80), 23, CREAM, Vector2(932, 91))
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_hint = _label(panel, "", Vector2(254, 184), 13, MUTED, Vector2(550, 25))
	dialogue_button = _button(panel, "继续  →  [F / 空格]", Rect2(964, 178, 245, 37), func(): game.advance_dialogue())
	dialogue.visible = false

func update_quest() -> void:
	game.sync_wish_banner()
	chapter_label.text = "群  星  归  航" if game.quest_stage >= 9 else ("沉  潮  来  信" if game.quest_stage >= 4 else "风  停  之  日")
	if game.quest_stage >= 14:
		chapter_label.text = "晨  钟  之  约" if game.quest_stage >= 19 else "森  心  苏  醒"
	if game.quest_stage>=24:
		chapter_label.text = "沉  星  海  书"
	var active_count = game.active_shrine_count()
	if game.quest_stage == 0:
		quest_title.text = "序章 · 未寄出的信"
		quest_text.text = "前往村中，与守灯人阿芙交谈。"
	elif game.quest_stage == 1:
		quest_title.text = "主线 · 唤醒五道微光"
		quest_text.text = "清除遗迹周围的蚀光体，\n用对应元素与星核共鸣。"
	elif game.quest_stage == 2:
		quest_title.text = "主线 · 天穹的回声"
		quest_text.text = "前往北方星陨观测庭，\n唤醒并净化失律的守卫。"
	elif game.quest_stage == 3:
		quest_title.text = "主线 · 风归之时"
		quest_text.text = "回到风铃村，将黎明的消息\n带给守灯人阿芙。"
	else:
		var info: Array = game.campaign.quest_info()
		quest_title.text = info[0]
		quest_text.text = info[1]
	quest_count.text = "星核共鸣 %d / 5     [J] 旅途手记" % active_count
	if game.quest_stage >= 4:
		quest_count.text = "线索 / 机关 %d / 3     [J] 旅途手记" % game.campaign.stage_progress(game.quest_stage) if game.quest_stage in [5, 6, 10, 11] else "[J] 旅途手记     [G] 星海祈愿"

func show_toast(message: String, duration: float = 3.0) -> void:
	toast_label.text = message
	toast_time = duration

func flash_damage() -> void:
	damage_flash.color.a = 0.2

func show_dialogue(speaker: String, content: String, hint: String) -> void:
	toast_time=0
	dialogue.visible = true
	dialogue_name.text = speaker
	dialogue_text.text = content
	dialogue_hint.text = "STORY  /  "+hint+"     ·     点击或按 F 显示全文 / 继续"
	dialogue_elapsed=0
	dialogue_text.visible_characters=0
	if game.test_mode: dialogue_text.visible_ratio=1
	for node in dialogue_portrait.get_children():
		dialogue_portrait.remove_child(node)
		node.queue_free()
	var id = 0
	for i in range(GameData.CHARACTER_COUNT):
		if speaker.contains(GameData.character(i)["name"]): id=i; break
	if speaker.begins_with("阿芙"): id=17
	var face=CharacterPortrait.new()
	face.character_id=id
	face.closeup=true
	face.position=Vector2(8,0)
	face.size=Vector2(215,285)
	dialogue_portrait.add_child(face)

func clear_overlay() -> void:
	for child in overlay.get_children():
		if child is WishAnimation:
			child.set_process(false)
		if child is Control:
			child.hide()
		child.queue_free()
	map_canvas = null
	modal_buttons.clear()
	overlay.visible = false
	journal_page = ""

func _modal_base(title: String, subtitle: String) -> void:
	clear_overlay()
	hud.visible = false
	toast_time = 0
	toast_label.position.y = 821
	overlay.visible = true
	_rect(overlay, Rect2(0, 0, 1440, 900), Color(0.025, 0.085, 0.11, 0.95))
	_label(overlay, title, Vector2(67, 45), 40, CREAM, Vector2(1050, 68))
	_label(overlay, subtitle, Vector2(71, 119), 15, MUTED, Vector2(1100, 33))
	_rect(overlay, Rect2(72, 174, 1296, 1), Color(0.83, 0.75, 0.53, 0.4))
	_button(overlay, "关闭  ×", Rect2(1240, 60, 126, 44), func(): game.close_overlay())

func show_map() -> void:
	if game.sea.active:
		show_sea_map()
		return
	_modal_base("星屿全图", "五道星核散落于岛屿各处。已唤醒的遗迹可通过右侧列表传送。")
	journal_page = "map"
	map_canvas = LumenAtlas.new()
	map_canvas.full_map = true
	map_canvas.game = game
	map_canvas.position = Vector2(94, 195)
	map_canvas.size = Vector2(628, 628)
	overlay.add_child(map_canvas)
	_label(overlay, "共 鸣 之 路", Vector2(845, 211), 23, GOLD, Vector2(460, 40))
	for i in range(5):
		var shrine: Dictionary = game.world.shrines[i]
		var text = GameData.SHRINES[i]["name"] + ("    传送 →" if shrine["active"] else "    尚未唤醒")
		var index = i
		var b = _button(overlay, text, Rect2(842, 284 + i * 76, 461, 55), func(): game.fast_travel(index))
		b.disabled = not shrine["active"]
		_glyph(overlay, i, Rect2(800, 295 + i * 76, 32, 32), GameData.element_color(i))
	_button(overlay, "风铃村    传送 →", Rect2(842, 700, 461, 55), func(): game.fast_travel(-1))
	_label(overlay, "浅蓝点：采集材料 · 紫方块：掉落经验书\n宝箱 %d/18 · 野怪 %d/14，清空八成后补充\n近敌、战斗或腾空时，传送暂不可用。" % [game.opened_chest_count(), game.renewal.dead_count()], Vector2(846, 777), 13, MUTED, Vector2(470, 95))
	if game.growth.tracked_material >= 0:
		_button(overlay,"取消材料追踪",Rect2(102,828,230,37),func():
			game.growth.tracked_material = -1
			show_map())

func show_characters(limited: bool = false, batch: int = -1) -> void:
	_modal_base("与光同行的人", "数字键 1—5 随时切换角色 · 每位角色拥有独立的元素战技冷却 · 队伍共享生命与共鸣能量")
	journal_page = "characters"
	_button(overlay, "常驻同行者", Rect2(72, 190, 176, 39), func(): show_characters(false), not limited)
	_button(overlay, "限定同行者", Rect2(262, 190, 176, 39), func(): show_characters(true), limited)
	_button(overlay, "前往星海祈愿 →", Rect2(1133, 190, 233, 39), func(): show_wish())
	_button(overlay,"P 角色画廊",Rect2(884,128,235,39),func(): show_gallery())
	_button(overlay, "U 角色培养", Rect2(1144, 128, 222, 39), func(): show_growth(game.player.character_index))
	if limited:
		show_limited_cards(GameData.rotation_for_quest(game.quest_stage) if batch < 0 else batch)
		return
	for i in range(5):
		var data: Dictionary = GameData.CHARACTERS[i]
		var color: Color = data["color"]
		var p = _panel(overlay, Rect2(72 + i * 262, 245, 248, 561), Color("18363e"), color.darkened(0.4))
		_rect(p, Rect2(0, 0, 248, 5), color)
		_glyph(p, i, Rect2(81, 36, 86, 86), color)
		_label(p, data["name"], Vector2(20, 143), 39, CREAM, Vector2(208, 56), HORIZONTAL_ALIGNMENT_CENTER)
		_label(p, data["title"], Vector2(12, 207), 15, color, Vector2(224, 29), HORIZONTAL_ALIGNMENT_CENTER)
		_label(p, data["element"] + " / " + data["weapon"] + " · 共鸣 %d 阶" % game.wishes.rank_of(i), Vector2(20, 251), 13, GOLD, Vector2(208, 25), HORIZONTAL_ALIGNMENT_CENTER)
		var desc = _label(p, data["description"], Vector2(23, 306), 16, MUTED, Vector2(201, 80))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label(p, "E  " + data["skill"], Vector2(23, 409), 19, CREAM, Vector2(204, 35))
		_label(p, "Q  " + data["burst"], Vector2(23, 451), 19, CREAM, Vector2(204, 35))
		var index = i
		_button(p, "培养角色 · Lv.%d" % game.growth.levels[index], Rect2(22, 504, 204, 39), func(): show_growth(index))
	_label(overlay, "元素共鸣： 焰 + 潮 = 蒸腾（1.8 倍）    潮 + 雷 = 感电（控制）    焰 + 雷 = 超载（击退）    风 = 扩散    岩 = 结晶护盾", Vector2(74, 814), 16, GOLD, Vector2(1290, 45), HORIZONTAL_ALIGNMENT_CENTER)

func show_growth(index: int = 0) -> void:
	GrowthScreen.show(self,clampi(index,0,GameData.CHARACTER_COUNT-1))

func show_bestiary() -> void:
	_modal_base("星屿生物手记", "B 打开 / 关闭 · 新怪物分布在野外与主线营地，击败后参与各自区域的刷新规则。")
	journal_page = "bestiary"
	var habitats = ["", "火绒团 · 近身跳砸", "苔角兽 · 蓄力冲撞", "潮灯灵 · 远程水弹", "晶甲蟹 · 双钳守势"]
	var hints = ["", "身体跃起时离开地面的红圈。落地后有短暂空隙。", "看见长条预警就向两侧闪开。撞上树木或石头后会停下。", "保持距离并发射三枚水弹。横向移动，或利用树干、石头挡住水弹。", "蓄力时护甲减伤。用岩元素打断守势，或绕开前方两个钳击圆圈。"]
	for kind in range(1, 5):
		var x = 72 + (kind - 1) * 331
		var color: Color = BeastSculpt.COLORS[kind]
		_panel(overlay, Rect2(x, 210, 310, 560), Color("17303b"), color.darkened(0.28))
		var portrait = CharacterPortrait.new()
		portrait.beast_kind = kind
		portrait.position = Vector2(x + 12, 225)
		portrait.size = Vector2(286, 300)
		overlay.add_child(portrait)
		_label(overlay, BeastSculpt.NAMES[kind], Vector2(x + 22, 516), 31, color, Vector2(266, 50))
		_label(overlay, habitats[kind], Vector2(x + 22, 577), 16, GOLD, Vector2(266, 43))
		_label(overlay, hints[kind], Vector2(x + 22, 636), 19, CREAM, Vector2(266, 115))
	_label(overlay, "树干和石头现在可以挡住角色、冲撞与水弹。绕过障碍，利用空隙反击。", Vector2(78, 808), 19, MUTED, Vector2(1250, 43))

func show_journal(chapter: int = 0) -> void:
	if chapter==6 or (game.quest_stage>=24 and chapter==0):
		show_sea_journal()
		return
	if chapter == 0:
		chapter = mini(5, GameData.rotation_for_quest(game.quest_stage) + 1)
	if chapter > 1:
		show_campaign_journal(chapter)
		return
	_modal_base("旅途手记", "第一章 · 风停之日     /     拾起失落的回声，让五道微光重新汇聚。")
	journal_page = "journal"
	_label(overlay, "未寄出的信", Vector2(75, 213), 29, GOLD, Vector2(530, 52))
	var story = "七天前，星屿的风停了。\n悬在观测庭上空的天穹之环逐渐暗淡，\n没有人再听见风铃声。\n\n你在一封没有署名的信中读到：\n「当五道光再度交汇，黎明便会回来。」\n\n五位同行者，一座遗忘过往的岛屿。\n答案，就藏在元素留下的记忆里。"
	_label(overlay, story, Vector2(77, 283), 21, CREAM, Vector2(563, 404))
	_label(overlay, "已唤醒的记忆", Vector2(751, 213), 26, GOLD, Vector2(570, 42))
	for i in range(5):
		var active: bool = game.world.shrines[i]["active"]
		var p = _panel(overlay, Rect2(750, 276 + i * 96, 576, 84), Color("19363d"), Color("3b5353"))
		_glyph(p, i, Rect2(12, 18, 44, 44), GameData.element_color(i) if active else Color("657977"))
		var content = GameData.SHRINES[i]["memory"] if active else GameData.SHRINES[i]["name"] + " · 尚未唤醒"
		var label = _label(p, content, Vector2(73, 15), 16, CREAM if active else MUTED, Vector2(481, 63))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(overlay, "探索记录 / 宝箱第 %d 轮 %d/18 · 累计 %d   /   野怪第 %d 轮 %d/14   /   击败 %d · 反应 %d" % [game.renewal.chest_wave, game.opened_chest_count(), game.renewal.collected_total, game.renewal.enemy_wave, game.renewal.dead_count(), game.enemies_defeated, game.reactions_triggered], Vector2(78, 780), 16, GOLD, Vector2(1250, 38))
	journal_tabs(1)

func show_pause() -> void:
	_modal_base("在此刻，歇一歇", "旅途会在启程、星核共鸣、开启宝箱及主线推进时自动保存。")
	journal_page = "pause"
	_label(overlay, "旅 行 指 南", Vector2(753, 236), 24, GOLD, Vector2(430, 47))
	_label(overlay, "W A S D        移动\n鼠标 / 滚轮    转动视角 / 缩放\nShift              冲刺\n空格               跳跃 / 空中再次按下滑翔\n鼠标左键        普通攻击\nE / Q              元素战技 / 元素爆发\n1 — 5             切换角色\nF                     交互 / 继续对话\nM / C / J        地图 / 角色 / 手记", Vector2(756, 316), 21, CREAM, Vector2(596, 410))
	_button(overlay, "继续旅程", Rect2(111, 264, 440, 65), func(): game.close_overlay(), true)
	_button(overlay, "保存旅途", Rect2(111, 353, 440, 57), func():
		if game.save_game():
			show_toast("旅途已保存"))
	_button(overlay, "声音：" + ("关闭" if game.audio.muted else "开启"), Rect2(111, 434, 440, 57), func():
		game.audio.muted = not game.audio.muted
		show_pause())
	_button(overlay, "返回标题", Rect2(111, 515, 440, 57), func(): game.return_to_title())
	_button(overlay, "保存并退出", Rect2(111, 596, 440, 57), func():
		game.save_game()
		game.get_tree().quit())
	_button(overlay, "G  星海祈愿 · 60 金币 / 次", Rect2(111, 683, 440, 57), func(): show_wish(), true)
	_button(overlay, "B  生物手记 · 查看怪物与应对", Rect2(111, 764, 440, 57), func(): show_bestiary())
	_label(overlay, "战斗提示：\n先用一种元素攻击，再切换角色施放战技。\n澜音的战技可治疗，砾川的战技可生成护盾。", Vector2(754, 752), 16, GOLD, Vector2(590, 97))
	_label(overlay,"水下：空格上浮 / Ctrl 下潜 / E 声波\nP 角色海报画廊   ·   U 角色培养",Vector2(754,681),17,GOLD,Vector2(590,66))

func show_ending() -> void:
	_modal_base("风，终于回来了。", "第 一 章  完 成    /    THE WIND RETURNS")
	journal_page = "ending"
	for i in range(5):
		_glyph(overlay, i, Rect2(487 + i * 96, 239, 70, 70), GameData.element_color(i))
	_label(overlay, "天穹之环重新亮起。\n风铃村的第一声风铃，回应了远方的海。", Vector2(236, 374), 30, CREAM, Vector2(968, 112), HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay, "有些旅程，是为了找回世界。\n有些相遇，让世界值得被找回。", Vector2(236, 515), 22, MUTED, Vector2(968, 99), HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay, "获得 200 金币 · 再与阿芙交谈，开启第二章「沉潮来信」", Vector2(235, 650), 17, GOLD, Vector2(970, 40), HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay, "本期限定已轮换：沧璃 · 砚山 · 烬翎   /   按 G 祈愿，保底继承", Vector2(235, 699), 16, MUTED, Vector2(970, 35), HORIZONTAL_ALIGNMENT_CENTER)
	_button(overlay, "继续探索这片原野    →", Rect2(510, 754, 420, 63), func(): game.close_overlay(), true)

func show_new_game_confirmation() -> void:
	_modal_base("重新启程", "这将替换本机已有的旅途存档。")
	journal_page = "new_game"
	_button(overlay, "开始新的旅途", Rect2(471, 373, 498, 64), func():
		clear_overlay()
		game.start_game(false), true)
	_button(overlay, "保留存档，返回标题", Rect2(471, 465, 498, 53), func(): clear_overlay())

func portrait(parent: Node, index: int, bounds: Rect2) -> void:
	var view = CharacterPortrait.new()
	view.character_id = index
	view.position = bounds.position
	view.size = bounds.size
	parent.add_child(view)

func show_limited_cards(batch: int = 0) -> void:
	var current = GameData.rotation_for_quest(game.quest_stage)
	for i in range(GameData.BANNER_BATCHES.size()):
		_button(overlay, GameData.BATCH_NAMES[i], Rect2(452 + i * 109, 190, 103, 39), func(): show_characters(true, i), i == batch)
	_label(overlay, "本期 · " + GameData.BATCH_NAMES[current] + " / 每完成一章主线轮换一批 · 保底继承 · 已获得的角色永久保留", Vector2(75, 843), 15, MUTED, Vector2(1270, 30))
	for slot in range(3):
		var id: int = GameData.BANNER_BATCHES[batch][slot]
		var data = GameData.character(id)
		var color: Color = data["color"]
		var owned: bool = game.wishes.has_character(id)
		var p = _panel(overlay, Rect2(72 + slot * 440, 245, 414, 586), Color("18313e"), color.darkened(0.3))
		_rect(p, Rect2(0, 0, 414, 4), color)
		portrait(p, id, Rect2(26, 5, 360, 259))
		_label(p, "限定 · " + data["element"] + "元素", Vector2(23, 17), 14, color, Vector2(195, 28))
		_label(p, data["name"], Vector2(24, 262), 36, CREAM, Vector2(155, 53))
		_label(p, "共鸣 %d 阶" % game.wishes.rank_of(id) if owned else "尚未获得", Vector2(246, 275), 16, GOLD, Vector2(144, 31), HORIZONTAL_ALIGNMENT_RIGHT)
		_label(p, data["title"], Vector2(25, 319), 15, color, Vector2(363, 30))
		_label(p, data["description"], Vector2(25, 360), 16, MUTED, Vector2(363, 72))
		_label(p, "E " + data["skill"] + "  /  Q " + data["burst"], Vector2(25, 438), 17, CREAM, Vector2(366, 31))
		_label(p, data["ability"], Vector2(25, 475), 13, GOLD, Vector2(366, 44))
		_button(p, "培养 · Lv.%d" % game.growth.levels[id], Rect2(24, 531, 145, 39), func(): show_growth(id))
		var action = _button(p, "编入队伍" if owned else ("前往祈愿 · 解锁" if current == batch else ("已轮替" if batch < current else "通关第 %d 章开放" % batch)), Rect2(183, 531, 207, 39), func():
			if owned:
				game.equip_character(id)
				game.close_overlay()
			else:
				game.wishes.banner = id
				show_wish(), owned)
		action.disabled = not owned and current != batch

func show_arts(index: int) -> void:
	var data = GameData.character(index)
	_modal_base(data["name"] + " · 元素技艺", data["element"] + "元素 / " + data["title"] + " · 限定角色，抽取后可编入队伍")
	journal_page = "arts"
	portrait(overlay, index, Rect2(80, 221, 425, 455))
	_label(overlay, data["tagline"], Vector2(85, 695), 21, GOLD, Vector2(423, 78), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(2):
		var p = _panel(overlay, Rect2(549, 221 + i * 263, 777, 237), Color("19333e"), data["color"])
		_label(p, ("E  " if i == 0 else "Q  ") + data["skill" if i == 0 else "burst"], Vector2(28, 23), 29, data["color"], Vector2(720, 55))
		_label(p, GameData.skill_details(index)[i], Vector2(30, 99), 21, CREAM, Vector2(713, 117))
	_label(overlay, "持续技能切换角色后仍然生效，菜单暂停时停止计时。爆发需要 100% 能量，冷却 14 秒。", Vector2(552, 740), 15, MUTED, Vector2(775, 47))
	_button(overlay, "返回限定角色", Rect2(562, 814, 316, 45), func(): show_characters(true, GameData.batch_of(index)), true)

func show_wish() -> void:
	game.sync_wish_banner()
	var id: int = game.wishes.banner
	var data = GameData.character(id)
	var color: Color = data["color"]
	_modal_base("星海祈愿", "本期 · " + GameData.BATCH_NAMES[GameData.rotation_for_quest(game.quest_stage)] + " / 通关一章主线即轮换三位限定 · 换期继承保底，已获得角色永久保留")
	journal_page = "wish"
	for slot in range(3):
		var selected: int = GameData.banner_ids(game.quest_stage)[slot]
		_button(overlay, GameData.character(selected)["banner"], Rect2(72 + slot * 245, 192, 229, 46), func():
			game.wishes.banner = selected
			game.save_game()
			show_wish(), selected == id)
	_label(overlay, "持有金币  %d" % game.coins, Vector2(982, 194), 24, GOLD, Vector2(385, 44), HORIZONTAL_ALIGNMENT_RIGHT)
	var panel = _panel(overlay, Rect2(72, 257, 1295, 381), Color("102534"), color.darkened(0.5))
	var stars = WishBackdrop.new()
	stars.size = Vector2(1295, 381)
	stars.tint = color
	panel.add_child(stars)
	portrait(panel, id, Rect2(742, -10, 489, 388))
	_label(panel, "限定角色祈愿  /  " + data["element"] + "元素", Vector2(37, 26), 16, color, Vector2(640, 32))
	_label(panel, data["banner"], Vector2(33, 67), 52, CREAM, Vector2(683, 85))
	_label(panel, data["name"] + "  ·  " + data["title"], Vector2(39, 169), 26, color, Vector2(680, 42))
	_label(panel, data["tagline"], Vector2(40, 228), 20, MUTED, Vector2(660, 57))
	_label(panel, "E  " + data["skill"] + "     Q  " + data["burst"], Vector2(40, 309), 17, CREAM, Vector2(653, 37))
	_label(panel, "已获得 · 共鸣 %d 阶" % game.wishes.rank_of(id) if game.wishes.has_character(id) else "抽取后解锁", Vector2(937, 331), 16, GOLD, Vector2(307, 30), HORIZONTAL_ALIGNMENT_RIGHT)
	var guaranteed: bool = game.wishes.guaranteed
	_label(overlay, "角色保底  %d / 20" % game.wishes.pity, Vector2(76, 655), 23, CREAM, Vector2(400, 42))
	var meter = _bar(overlay, Rect2(79, 709, 428, 5), color)
	meter.value = game.wishes.pity * 5
	_label(overlay, "再抽至多 %d 次必得%s" % [WishSystem.SOFT_PITY - game.wishes.pity, data["name"] if guaranteed else "角色"], Vector2(79, 726), 16, color, Vector2(565, 31))
	_label(overlay, "大保底已生效 · 下次角色必为当前限定" if guaranteed else "小保底 · 出角色时 50% 为当前限定", Vector2(79, 762), 15, GOLD, Vector2(596, 30))
	var single = _button(overlay, "祈愿一次  ·  60 金币", Rect2(754, 684, 290, 65), func(): game.perform_wish(1))
	single.disabled = game.coins < 60
	var ten = _button(overlay, "祈愿十次  ·  600 金币", Rect2(1060, 684, 307, 65), func(): game.perform_wish(10), true)
	ten.disabled = game.coins < 600
	_label(overlay, "每只宝箱 +30 金币 · 每轮开启 15/18 后补充", Vector2(754, 766), 15, MUTED, Vector2(613, 29), HORIZONTAL_ALIGNMENT_CENTER)
	_button(overlay, "祈愿规则", Rect2(76, 822, 173, 39), func(): show_wish_rules())
	_button(overlay, "抽卡记录", Rect2(266, 822, 173, 39), func(): show_wish_history())
	_button(overlay, "查看限定角色 →", Rect2(1102, 822, 264, 39), func(): show_characters(true))

func show_wish_rules() -> void:
	_modal_base("祈愿规则", "金币来自探索与主线奖励 · 本游戏没有充值")
	journal_page = "wish_rules"
	var rules = [
		["60 / 600 金币", "单抽 60 金币，十连 600 金币。每箱 30 金币；每轮开启 15/18 只后补充宝箱，击败 12/14 只野怪后补充野怪。剩余目标保留。"],
		["1% 基础概率", "每次非保底祈愿有 1% 概率获得角色；其他结果为旅行药剂 ×1，按 R 恢复 45 生命。"],
		["20 次小保底", "连续 19 次没有角色，第 20 次必出角色。任何一次提前出角色，都会重新计算这 20 次。"],
		["40 次内大保底", "出角色时 50% 为当前限定，50% 为五位常驻角色之一（各等概率）。若未出限定，下次角色必为当前限定，因此至多 40 抽必得限定。"],
		["通关轮换限定", "共 18 位限定，分六批，每批三位。初始及每章通关各换一批，旧卡池关闭；已拥有角色永久可用。所有批次共享保底，大保底跟随当前所选限定。"],
		["重复角色与编队", "重复角色提升 1 阶共鸣，每阶伤害 +3%，最多 5 阶；满阶后转为药剂 ×2。抽到限定后按 C 编入同元素位置，初始五位角色始终可用。"]
	]
	for i in range(rules.size()):
		var y = 204 + i * 92
		_label(overlay, rules[i][0], Vector2(81, y), 22, GOLD, Vector2(264, 64))
		_label(overlay, rules[i][1], Vector2(365, y), 19, CREAM, Vector2(953, 76))
	_button(overlay, "返回祈愿", Rect2(560, 802, 320, 49), func(): show_wish(), true)

func show_wish_animation(results: Array) -> void:
	clear_overlay()
	hud.visible = false
	overlay.visible = true
	toast_time = 0
	journal_page = "wish_animation"
	var animation = WishAnimation.new()
	animation.size = Vector2(1440, 900)
	animation.pull_count = results.size()
	for result in results:
		animation.tier = maxi(animation.tier, 2 if result["limited"] else (1 if result["type"] == "character" else 0))
	overlay.add_child(animation)
	animation.finished.connect(game.finish_wish_animation)
	_label(overlay, "星  海  正  在  回  应", Vector2(350, 680), 27, CREAM, Vector2(740, 55), HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay, "STELLAR WISH  /  " + ("TEN WISHES" if results.size() == 10 else "ONE WISH"), Vector2(400, 743), 13, MUTED, Vector2(640, 30), HORIZONTAL_ALIGNMENT_CENTER)
	_button(overlay, "跳过动画  [Esc]", Rect2(1160, 47, 217, 43), func(): animation.skip())
	game.audio.tone(520, 0.6, 0.22)

func show_wish_results(results: Array) -> void:
	_modal_base("星光回应了你", "祈愿结果已保存 · 剩余 %d 金币 · 旅行药剂 ×%d" % [game.coins, game.wishes.potions])
	journal_page = "wish_results"
	var single = results.size() == 1
	for i in range(results.size()):
		var item: Dictionary = results[i]
		var character = item["type"] == "character"
		var color: Color = GameData.character_color(item["character"]) if character else Color("90b4bd")
		var bounds = Rect2(450, 212, 540, 524) if single else Rect2(73 + (i % 5) * 263, 206 + (i / 5) * 271, 244, 252)
		var p = _panel(overlay, bounds, Color("19323e"), GOLD if item["limited"] else color.darkened(0.15))
		_rect(p, Rect2(0, 0, bounds.size.x, 4), GOLD if item["limited"] else color)
		var tag = "限定 · 初次相遇" if item["new"] else ("角色 · 共鸣提升" if character else "旅途补给")
		_label(p, tag, Vector2(16, 12), 14, GOLD if character else MUTED, Vector2(bounds.size.x - 32, 29), HORIZONTAL_ALIGNMENT_CENTER)
		if character and single:
			portrait(p, item["character"], Rect2(100, 46, 340, 296))
		elif character:
			_glyph(p, GameData.element_of(item["character"]), Rect2(98, 56, 48, 48), color)
		else:
			_label(p, "✦", Vector2(0, 65 if not single else 146), 43 if not single else 84, color, Vector2(bounds.size.x, 78 if not single else 118), HORIZONTAL_ALIGNMENT_CENTER)
		var name_y = 337 if single else 119
		_label(p, item["name"], Vector2(15, name_y), 33 if single else 25, CREAM, Vector2(bounds.size.x - 30, 46), HORIZONTAL_ALIGNMENT_CENTER)
		_label(p, item["detail"], Vector2(18, name_y + 53), 17 if single else 13, MUTED, Vector2(bounds.size.x - 36, 66 if single else 49), HORIZONTAL_ALIGNMENT_CENTER)
		_label(p, "大保底兑现" if item.get("big_pity", false) else ("20 次保底" if item["pity"] else "星海的馈赠"), Vector2(15, bounds.size.y - 35), 12, GOLD if character else MUTED, Vector2(bounds.size.x - 30, 23), HORIZONTAL_ALIGNMENT_CENTER)
		p.modulate.a = 0
		create_tween().tween_property(p, "modulate:a", 1.0, 0.25).set_delay(i * 0.07)
	_button(overlay, "返回祈愿", Rect2(383, 789, 320, 59), func(): show_wish(), true)
	_button(overlay, "查看角色 · 编入队伍", Rect2(735, 789, 320, 59), func(): show_characters(true))

func show_wish_history(page: int = 0) -> void:
	_modal_base("星海中的相遇", "保存最近 60 次祈愿 · 累计祈愿 %d 次 · 最新结果在前" % game.wishes.total_pulls)
	journal_page = "wish_history"
	var history: Array = game.wishes.history
	if history.is_empty():
		_label(overlay, "星海尚未收到你的祈愿。", Vector2(350, 381), 30, MUTED, Vector2(740, 74), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(page * 10, mini(page * 10 + 10, history.size())):
		var row: Dictionary = history[i]
		var y = 204 + (i % 10) * 54
		_label(overlay, "第 %d 抽" % int(row["pull"]), Vector2(90, y), 17, MUTED, Vector2(147, 39))
		_label(overlay, row["name"] + (" · 限定" if row["limited"] else ""), Vector2(260, y), 19, GOLD if row["type"] == "character" else CREAM, Vector2(295, 39))
		_label(overlay, row["detail"], Vector2(592, y), 16, MUTED, Vector2(717, 39))
	var previous = _button(overlay, "上一页", Rect2(81, 804, 174, 46), func(): show_wish_history(page - 1))
	previous.disabled = page == 0
	var next = _button(overlay, "下一页", Rect2(272, 804, 174, 46), func(): show_wish_history(page + 1))
	next.disabled = (page + 1) * 10 >= history.size()
	_button(overlay, "返回祈愿", Rect2(1045, 804, 321, 46), func(): show_wish(), true)

func journal_tabs(selected: int) -> void:
	for i in range(1, 7):
		var chapter = i
		_button(overlay, ["", "一 · 风停之日", "二 · 沉潮来信", "三 · 群星归航", "四 · 森心苏醒", "五 · 晨钟之约", "六 · 沉星海书"][i], Rect2(77 + (i - 1) * 217, 830, 205, 40), func(): show_journal(chapter), selected == chapter)

func show_campaign_journal(chapter: int) -> void:
	if chapter >= 4:
		show_afterlight_journal(chapter)
		return
	var second = chapter == 2
	_modal_base("旅途手记", "第二章 · 沉潮来信" if second else "第三章 · 群星归航")
	journal_page = "journal"
	var unlocked: bool = game.quest_stage >= (4 if second else 9)
	_label(overlay, "给归人一盏灯" if second else "给明天一片星空", Vector2(78, 208), 35, GOLD, Vector2(625, 64))
	var story = "风归来后，镜潮湖畔出现了来自沉没旧港的信。\n\n栖月的航记、褪色的船票、未寄出的家书……\n将三张残页拼起，你听见了潮汐中的等待。\n\n以潮、风、焰点亮三座潮灯，\n前往旧港遗址，净化忘潮的回声。\n\n这一次，要让每一封信找到归途。" if second else "观测庭的最后一封信，来自霁霆的导师。\n星环复苏，也唤醒了藏在星隙里的无光者。\n\n寻回绯曜与镜夜留下的三片星图，\n以岩、雷、风重新点亮星航标。\n\n回到一切开始的观测庭，面对无光的司辰。\n\n守护星星，也守护仰望星星的人。"
	_label(overlay, story if unlocked else "完成上一章后，与风铃村的阿芙交谈，\n即可拆开下一封来信。", Vector2(81, 295), 21, CREAM, Vector2(613, 405))
	_label(overlay, "主线进程", Vector2(752, 214), 25, GOLD, Vector2(560, 49))
	var stages = [5, 6, 7, 8] if second else [10, 11, 12, 13]
	for i in range(stages.size()):
		var stage: int = stages[i]
		var data: Array = LumenCampaign.QUESTS[stage]
		var state = "已完成" if game.quest_stage > stage else ("进行中" if game.quest_stage == stage else "待开启")
		var p = _panel(overlay, Rect2(750, 288 + i * 116, 570, 100), Color("17323c"), Color("3d5b61"))
		_label(p, data[0].split(" · ")[1] + "  /  " + state, Vector2(20, 10), 20, GOLD if state == "进行中" else CREAM, Vector2(530, 37))
		_label(p, data[1].replace("\n", ""), Vector2(20, 53), 15, MUTED, Vector2(530, 40))
	_label(overlay, "完成本章谢礼：%d 金币 · 主线不要求持有限定角色" % (600 if second else 800), Vector2(81, 769), 17, GOLD, Vector2(1241, 42))
	journal_tabs(chapter)

func show_chapter_ending(chapter: int) -> void:
	var second = chapter == 2
	_modal_base("每一盏灯，都在等你归来。" if second else "群星归航，长夜已尽。", "第 二 章 完 成  /  沉潮来信" if second else "第 三 章 完 成  /  群星归航")
	journal_page = "ending"
	for i in range(5):
		_glyph(overlay, i, Rect2(487 + i * 96, 246, 70, 70), GameData.element_color(i))
	_label(overlay, "潮汐送来了最后一封信。\n所有等待，都在天明之前得到了回答。" if second else "裂隙合拢，天空再一次属于仰望它的人。\n这封跨越长夜的信，终于送达。", Vector2(211, 390), 30, CREAM, Vector2(1018, 124), HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay, "获得 600 金币 · 再与阿芙交谈，开启第三章" if second else "获得 800 金币 · 再与阿芙交谈，开启第四章", Vector2(215, 569), 23, GOLD, Vector2(1010, 60), HORIZONTAL_ALIGNMENT_CENTER)
	_label(overlay, "本期限定已轮换：霜汐 · 朔风 · 玄霆" if second else "本期限定已轮换：曜岚 · 丹砂 · 燎原", Vector2(215, 653), 20, CREAM, Vector2(1010, 45), HORIZONTAL_ALIGNMENT_CENTER)
	_button(overlay, "继续旅程 →", Rect2(379, 753, 328, 60), func(): game.close_overlay(), true)
	_button(overlay, "前往星海祈愿", Rect2(733, 753, 328, 60), func(): show_wish())

func show_afterlight_journal(chapter: int) -> void:
	var grove = chapter == 4
	_modal_base("旅途手记", "第四章 · 森心苏醒" if grove else "第五章 · 晨钟之约")
	journal_page = "journal"
	var start = 15 if grove else 20
	_label(overlay, "陪森林等一个春天" if grove else "让明天听见今天", Vector2(78, 208), 35, GOLD, Vector2(625, 64))
	var story = "星空重燃，森林却仍在枯萎。\n丝萝与珀砂带来最后三枚森心种的消息。\n\n找回种子后，陪伴萤灵穿过三站：\n风桥 → 露泉 → 根庭。\n\n在它身边慢慢前行，等它抵达再激活路标。\n唤醒守林者，把森林的新芽带回村庄。" if grove else "昭璃点亮的灯台，终于等来了钟声。\n夜弦找到旧日曲谱，青羽记下新的航向。\n\n按顺序用风、潮、雷元素敲响晨钟：\n风 → 潮 → 星。已奏响的旋律会保留。\n\n清除三处灯台的全部巡卫，以焰、岩、潮点灯。\n直面堕曜圣像，让它听见属于今天的和声。"
	_label(overlay, story if game.quest_stage >= start - 1 else "完成上一章后，与阿芙交谈，\n即可开启新的旅程。", Vector2(81, 295), 21, CREAM, Vector2(613, 405))
	for i in range(4):
		var stage = start + i
		var data: Array = Afterlight.QUESTS[stage]
		var state = "已完成" if game.quest_stage > stage else ("进行中" if game.quest_stage == stage else "待开启")
		var panel = _panel(overlay, Rect2(750, 250 + i * 122, 570, 108), Color("17323c"), Color("557164"))
		_label(panel, data[0].split(" · ")[1] + " / " + state, Vector2(20, 11), 21, GOLD, Vector2(530, 36))
		_label(panel, data[1].replace("\n", ""), Vector2(20, 55), 15, CREAM, Vector2(530, 45))
	_label(overlay, "完成本章谢礼：%d 金币 · 新增三位限定卡池 · 初始角色即可完成" % (1000 if grove else 1200), Vector2(81, 769), 17, GOLD, Vector2(1240, 42))
	journal_tabs(chapter)

func show_afterlight_ending(chapter: int) -> void:
	var grove = chapter == 4
	_modal_base("森林记住了你的脚步。" if grove else "今天的晨钟，为每一个人响起。", "第四章完成 / 森心苏醒" if grove else "第五章完成 / 晨钟之约")
	journal_page = "ending"
	portrait(overlay, 17 if grove else 20, Rect2(90, 185, 405, 515))
	_label(overlay, "枯枝长出第一片新叶。\n萤灵在风铃下，找到了新的家。" if grove else "旧钟的回声穿过森林与湖泊。\n这一次，没有谁被留在长夜里。", Vector2(562, 278), 31, CREAM, Vector2(754, 150))
	_label(overlay, "获得 1000 金币 · 回村交谈开启第五章" if grove else "获得 1200 金币 · 回村拆开海底的来信", Vector2(562, 485), 23, GOLD, Vector2(754, 60))
	_label(overlay, "本期限定：丝萝 · 珀砂 · 溟弦" if grove else "本期限定：昭璃 · 夜弦 · 青羽", Vector2(562, 589), 23, CREAM, Vector2(754, 60))
	_button(overlay, "继续探索 →", Rect2(566, 744, 330, 61), func(): game.close_overlay(), true)
	_button(overlay, "前往本期祈愿", Rect2(922, 744, 330, 61), func(): show_wish())

func _label(parent: Node, content: String, pos: Vector2, font_size: int, color: Color, dimensions: Vector2, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text = content
	label.position = pos
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.025, 0.08, 0.10, 0.36))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _rect(parent: Node, bounds: Rect2, color: Color) -> ColorRect:
	var rect = ColorRect.new()
	rect.position = bounds.position
	rect.size = bounds.size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func _style(bg: Color, border: Color, radius: int = 4) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style

func _panel(parent: Node, bounds: Rect2, bg: Color, border: Color) -> Panel:
	var panel = Panel.new()
	panel.position = bounds.position
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(bg, border))
	parent.add_child(panel)
	return panel

func _button(parent: Node, content: String, bounds: Rect2, callback: Callable, primary: bool = false) -> Button:
	var button = Button.new()
	button.text = content
	button.position = bounds.position
	button.size = bounds.size
	button.add_theme_font_size_override("font_size", 19 if primary else 16)
	button.add_theme_color_override("font_color", INK if primary else CREAM)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else Color("24454a"), GOLD if primary else Color("6d8177")))
	button.add_theme_stylebox_override("hover", _style(CREAM, CREAM))
	button.add_theme_stylebox_override("pressed", _style(Color("c6b47f"), GOLD))
	button.add_theme_stylebox_override("focus", _style(Color(1, 1, 1, 0.08), CREAM))
	button.add_theme_stylebox_override("disabled", _style(Color("1c333b"), Color("435851")))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _bar(parent: Node, bounds: Rect2, color: Color) -> LumenMeter:
	var bar = LumenMeter.new()
	bar.position = bounds.position
	bar.size = bounds.size
	bar.value = 100
	bar.tint = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar

func _glyph(parent: Node, element: int, bounds: Rect2, color: Color) -> void:
	var glyph = ElementGlyph.new()
	glyph.element = element
	glyph.tint = color
	glyph.position = bounds.position
	glyph.size = bounds.size
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glyph)

func show_sea_map() -> void:
	_modal_base("沉星海 · 遗城航图","空格上浮 · Ctrl 下潜 · 高度不同的遗迹需要自由潜游抵达")
	journal_page="map"
	var map = LumenAtlas.new()
	map.game=game
	map.full_map=true
	map.position=Vector2(96,216)
	map.size=Vector2(590,590)
	overlay.add_child(map)
	map_canvas=map
	_label(overlay,game.sea.info()[0],Vector2(762,250),29,GOLD,Vector2(575,60))
	_label(overlay,game.sea.info()[1]+"\n\n宝箱：%d / 12\n每箱 30 金币 + 冒险心得 ×1\n\n回到入口的发光圆环，按 F 返回海面。" % game.sea.opened.size(),Vector2(764,342),22,CREAM,Vector2(550,260))
	_button(overlay,"返回风铃村",Rect2(764,680,470,58),func(): game.fast_travel(-1),true)

func show_sea_journal() -> void:
	_modal_base("第六章 · 沉星海书","海底寄来的明信片，为什么盖着明天的邮戳？")
	journal_page="journal"
	_label(overlay,"寄往明天",Vector2(86,225),40,GOLD,Vector2(520,75))
	_label(overlay,"那些潮湿的旧信、地上失控的守卫、\n迟迟不肯停下的晨钟，原来指向同一个愿望：\n留住所有来不及告别的人。\n\n这一次，澜音必须回到自己逃离的城市。\n在回声里辨认真相，陪最后的信使完成航程，\n再决定，如何替旧城写下明天。",Vector2(86,324),23,CREAM,Vector2(625,350))
	_label(overlay,"你的回答："+(game.sea.choice if game.sea.choice!="" else "尚未写下"),Vector2(86,742),20,GOLD,Vector2(640,60))
	for i in range(10):
		var color = GOLD if game.quest_stage==24+i else (MUTED if game.quest_stage>24+i else Color("708993"))
		_label(overlay,("✓  " if game.quest_stage>24+i else "◇  ")+DeepSea.TITLES[i],Vector2(790,220+i*53),21,color,Vector2(550,45))
	_button(overlay,"回顾前五章",Rect2(820,790,440,44),func(): show_journal(5))

func show_gallery(index: int = 0) -> void:
	_modal_base("同行者 · 角色画廊","P 打开画廊 · 可预览未拥有角色，预览不解锁角色。")
	journal_page="gallery"
	var ids = [2,5,20]
	var id: int = ids[index]
	var data = GameData.character(id)
	var path = "res://assets/posters/"+["lanyin","qiyue","zhaoli"][index]+".png"
	_panel(overlay,Rect2(77,186,655,640),Color("102838"),GOLD)
	if ResourceLoader.exists(path):
		var art=TextureRect.new()
		art.texture=load(path)
		art.position=Vector2(78,187)
		art.size=Vector2(653,638)
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay.add_child(art)
	else:
		portrait(overlay,id,Rect2(90,195,620,620))
	_label(overlay,data["name"],Vector2(803,260),60,CREAM,Vector2(510,90))
	_label(overlay,data["title"],Vector2(810,371),25,GOLD,Vector2(510,65))
	_label(overlay,data["description"],Vector2(810,480),23,MUTED,Vector2(510,130))
	_label(overlay,"已拥有" if game.wishes.has_character(id) else "限定同行者 · 需在对应祈愿中获得",Vector2(810,625),18,GOLD,Vector2(510,50))
	for i in range(3):
		_button(overlay,GameData.character(ids[i])["name"],Rect2(798+i*180,752,163,52),func(): show_gallery(i),i==index)
