class_name GrowthScreen
extends RefCounted

static func show(ui: LumenUI, index: int) -> void:
	var game: LumenGame = ui.game
	var growth: CharacterGrowth = game.growth
	var data = GameData.character(index)
	var color: Color = data["color"]
	var owned = game.wishes.has_character(index)
	ui._modal_base("角色培养", "U 打开 / 关闭 · 经验书来自怪物掉落 · 20 / 40 级突破 · 最高 60 级")
	ui.journal_page = "growth"
	var selector = OptionButton.new()
	selector.name = "GrowthCharacterSelect"
	selector.position = Vector2(78,192)
	selector.size = Vector2(390,47)
	for id in range(GameData.CHARACTER_COUNT):
		selector.add_item("%s  ·  %s  ·  %s" % [GameData.character(id)["name"],GameData.character(id)["element"],"Lv.%d" % growth.levels[id] if game.wishes.has_character(id) else "未获得"],id)
	selector.select(index)
	selector.item_selected.connect(func(id: int): ui.show_growth(id))
	ui.overlay.add_child(selector)
	ui.portrait(ui.overlay,index,Rect2(83,242,380,391))
	ui._label(ui.overlay,data["name"],Vector2(82,630),36,ui.CREAM,Vector2(380,54),HORIZONTAL_ALIGNMENT_CENTER)
	ui._label(ui.overlay,data["title"],Vector2(82,684),17,color,Vector2(380,35),HORIZONTAL_ALIGNMENT_CENTER)
	ui._label(ui.overlay,data["description"],Vector2(83,727),16,ui.MUTED,Vector2(379,60),HORIZONTAL_ALIGNMENT_CENTER)
	var equip = ui._button(ui.overlay,"编入队伍",Rect2(80,813,180,45),func():
		game.equip_character(index)
		game.close_overlay(),true)
	equip.disabled = not owned
	ui._button(ui.overlay,"角色图鉴",Rect2(279,813,182,45),func(): ui.show_characters(index>=5,GameData.batch_of(index) if index>=5 else 0))
	ui._panel(ui.overlay,Rect2(511,192,821,134),Color("19333f"),color.darkened(0.4))
	ui._label(ui.overlay,"Lv. %d / %d" % [growth.levels[index],growth.cap(index)],Vector2(533,210),33,ui.CREAM,Vector2(295,51))
	ui._label(ui.overlay,"伤害 ×%.2f    受伤 −%d%%" % [growth.damage_multiplier(index),roundi((1-growth.damage_taken(index))*100)],Vector2(875,215),23,color,Vector2(425,40),HORIZONTAL_ALIGNMENT_RIGHT)
	var xp_text = "经验 %d / %d" % [growth.experience[index],growth.needed(growth.levels[index])]
	if growth.levels[index] == growth.cap(index):
		xp_text = ("已达满级" if growth.cap(index)==60 else "需要突破") + " · 暂存经验 %d" % growth.experience[index]
	ui._label(ui.overlay,xp_text,Vector2(536,269),16,ui.MUTED,Vector2(751,30))
	var bar = ui._bar(ui.overlay,Rect2(536,307,772,5),color)
	bar.value = 100 if growth.levels[index]==growth.cap(index) else minf(100,100.0*growth.experience[index]/growth.needed(growth.levels[index]))
	ui._label(ui.overlay,"使用经验书  ·  批量最多用 10 本，达到当前上限即停止",Vector2(516,333),16,ui.MUTED,Vector2(810,30))
	for kind in range(3):
		var x = 512 + kind*277
		var panel = ui._panel(ui.overlay,Rect2(x,373,267,155),Color("19323e"),CharacterGrowth.BOOK_COLORS[kind].darkened(0.3))
		ui._rect(panel,Rect2(16,18,30,40),CharacterGrowth.BOOK_COLORS[kind])
		ui._rect(panel,Rect2(20,23,3,29),ui.GOLD)
		ui._label(panel,CharacterGrowth.BOOK_NAMES[kind],Vector2(59,11),22,ui.CREAM,Vector2(194,34))
		ui._label(panel,"经验 +%d   持有 %d" % [CharacterGrowth.BOOK_XP[kind],growth.books[kind]],Vector2(17,60),16,ui.MUTED,Vector2(235,31))
		var one = ui._button(panel,"使用 1 本",Rect2(15,103,112,37),func():
			growth.use_book(index,kind,1)
			ui.show_growth(index))
		one.name = "UseBook%d" % kind
		var many = ui._button(panel,"最多 10 本",Rect2(138,103,115,37),func():
			growth.use_book(index,kind,10)
			ui.show_growth(index))
		one.disabled = not owned or growth.books[kind] == 0 or growth.levels[index] == growth.cap(index)
		many.disabled = one.disabled
	ui._panel(ui.overlay,Rect2(512,549,821,241),Color("182f3a"),ui.GOLD.darkened(0.5))
	ui._label(ui.overlay,"突破材料" + ("  ·  当前已完成全部突破" if growth.ascensions[index]>=2 else "  ·  等级上限 %d → %d" % [growth.cap(index),growth.cap(index)+20]),Vector2(534,562),22,ui.GOLD,Vector2(771,41))
	var row = 0
	for item in growth.costs(index):
		var y = 610 + row*57
		var need: int = growth.costs(index)[item]
		ui._label(ui.overlay,growth.material_name(item),Vector2(538,y),18,ui.CREAM,Vector2(215,30))
		ui._label(ui.overlay,"%d / %d" % [growth.materials[item],need] if growth.ascensions[index]<2 else "持有 %d" % growth.materials[item],Vector2(757,y),18,color if growth.materials[item]>=need else Color("e5a494"),Vector2(115,31),HORIZONTAL_ALIGNMENT_RIGHT)
		ui._label(ui.overlay,growth.material_region(item),Vector2(891,y),13,ui.MUTED,Vector2(272,31))
		if item != CharacterGrowth.COMMON:
			ui._button(ui.overlay,"追踪采集",Rect2(1173,y,140,35),func(): growth.track(item))
		else:
			ui._label(ui.overlay,"打怪掉落",Vector2(1173,y),15,ui.GOLD,Vector2(140,35),HORIZONTAL_ALIGNMENT_CENTER)
		row += 1
	var ascend = ui._button(ui.overlay,"突破" if growth.ascensions[index]<2 else "已突破至 60 级",Rect2(1137,813,193,46),func():
		growth.ascend(index)
		ui.show_growth(index),true)
	ascend.name = "AscendCharacter"
	ascend.disabled = not growth.can_ascend(index)
	var message = growth.notice if owned else "尚未获得此角色，需通过祈愿解锁后培养。"
	ui._label(ui.overlay,message,Vector2(516,802),16,ui.GOLD,Vector2(599,49))
	ui._label(ui.overlay,"升级不消耗金币 · 溢出经验暂存，突破后结算 · 采集点探索 10 分钟后再生",Vector2(516,855),12,ui.MUTED,Vector2(815,28))
	if index>=5:
		ui._button(ui.overlay,"技能详情",Rect2(1198,127,134,37),func(): ui.show_arts(index))
