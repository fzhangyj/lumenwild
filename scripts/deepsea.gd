class_name DeepSea
extends Node3D

const CENTER = Vector3(600, -40, 0)
const ENTRY = Vector3(600, -27, 36)
const TITLES = ["海底寄来的明信片", "沿光下潜", "没有收件人的邮局", "城市说了一个谎", "替沉默的人回答", "追上最后一封信", "守护者的心跳", "让钟声穿过海面", "最后的收件人", "明天的第一班船", "潮水记得我们的名字"]
const TASKS = ["与阿芙交谈，调查来自海底的新信。", "前往旧港的潜潮门，按 F 下潜。", "潜入珍珠邮局，读取沉没前的录音。", "调查高处档案馆，查明撤离命令。", "按录音的顺序鸣响三座声纹钟。", "陪伴信使鳐穿过遗城，太远它会等待。", "躲开红色潮汐冲击，靠近三枚锁链用 E 解开。", "进入中央钟庭，决定如何回应旧城。", "回到海面的阿芙身边，把真相带回。", "再次与阿芙交谈，为旧港写下新航期。", "第六章已完成。潜潮门仍然开放，海底宝藏等待探索。"]
const BELL_ORDER = [1, 0, 2]
var game: LumenGame
var active = false
var outside_env: Environment
var sea_env: Environment
var realm: Node3D
var portal: Vector3
var sites: Array[Vector3] = [CENTER+Vector3(-23,8,13), CENTER+Vector3(23,20,1), CENTER+Vector3(-15,10,-14), CENTER+Vector3(0,17,-17), CENTER+Vector3(15,10,-14), CENTER+Vector3(0,12,-34)]
var bell_count = 0
var rescued: Array[int] = []
var opened: Array[int] = []
var choice = ""
var escort = 0.0
var hazard_clock = 0.0
var chest_round = 1
var ray: Node3D
var rings: Array[MeshInstance3D] = []
var locks: Array[Node3D] = []
var treasures: Array[Node3D] = []
var fish: Array[Node3D] = []
var caption: Label

func _ready() -> void:
	portal = WildWorld.ground(-97,-66,0.2)
	var gate = Node3D.new()
	add_child(gate)
	gate.position = portal
	Models.ring(gate,Vector3(0,2,0),1.7,Color("8fece7"),0.13).rotation.x = PI/2
	for side in [-1,1]:
		Models.cylinder(gate,Vector3(side*2,1.5,0),0.35,3,Color("d1dccc"),0.26,16)
	game.world._label(gate,"潜潮门 · F 探索沉星海",Vector3(0,4.4,0),Color("aeefef"),28)
	outside_env = game.world.environment.environment
	sea_env = outside_env.duplicate()
	sea_env.background_mode = Environment.BG_COLOR
	sea_env.background_color = Color("064354")
	sea_env.ambient_light_color = Color("c1e3dc")
	sea_env.ambient_light_energy = 0.75
	sea_env.fog_light_color = Color("0e4d64")
	sea_env.fog_density = 0.005
	realm = Node3D.new()
	add_child(realm)
	realm.position = CENTER
	_build_city()
	apply_environment(false)

func _solid(pos: Vector3, size: Vector3, color: Color) -> void:
	if size.y<45:
		var visual = Models.cylinder(realm,pos,size.x*0.62,size.y,color,-1,24) if size.x<1.2 and size.y>4 else Models.box(realm,pos,size,color)
		var mat=ShaderMaterial.new()
		mat.shader=load("res://shaders/sea_stone.gdshader")
		mat.set_shader_parameter("stone_color",color)
		visual.material_override=mat
	var solid = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	solid.position = pos
	solid.add_child(shape)
	realm.add_child(solid)

func _build_city() -> void:
	_solid(Vector3(0,-2,0),Vector3(120,3,120),Color("5b8589"))
	for x in [-61,61]:
		_solid(Vector3(x,23,0),Vector3(2,50,124),Color("215965"))
	for z in [-61,61]:
		_solid(Vector3(0,23,z),Vector3(124,50,2),Color("215965"))
	# Terraces, open colonnades and broken arches are navigable at multiple heights.
	for k in range(7):
		var z = 30-k*10
		_solid(Vector3(0,0.4,z),Vector3(12,0.3,8),Color("a4bbaf"))
	for x in [-26,26]:
		for z in [-24,-4,16]:
			_solid(Vector3(x,2,z),Vector3(17,1,15),Color("93b5b1"))
			for side in [-1,1]:
				for front in [-1,1]:
					var p = Vector3(x+side*6,8,z+front*5)
					_solid(p,Vector3(0.8,11,0.8),Color("bccdc1"))
					for h in [3.0,12.5]:
						Models.cylinder(realm,Vector3(p.x,h,p.z),0.8,0.35,Color("d4c79b"),-1,16)
			_solid(Vector3(x,14,z),Vector3(16,0.7,14),Color("80a4a6"))
			Models.ring(realm,Vector3(x,14.6,z),4.7,Color("b6e2d6"),0.08)
	for i in range(10):
		var a = TAU*i/10
		var p = Vector3(sin(a)*11,13,-34+cos(a)*11)
		_solid(p,Vector3(0.85,25,0.85),Color("adc5bd"))
		Models.crystal(realm,p+Vector3.UP*13,0.8,Color("9ae9d8"))
	for h in [2,24,28]:
		Models.ring(realm,Vector3(0,h,-34),12,Color("bfbe99"),0.22)
	var astrolabe = Models.ring(realm,Vector3(0,15,-37),7,Color("a7e9df"),0.22)
	astrolabe.rotation.x = PI/2
	Models.ring(realm,Vector3(0,15,-37),5.8,Color("d4bf87"),0.12).rotation.x = PI/2
	var rng = RandomNumberGenerator.new()
	rng.seed = 60821
	for i in range(100):
		var p = Vector3(rng.randf_range(-54,54),0,rng.randf_range(-52,48))
		if absf(p.x)<9: continue
		var c = Color("d58cba") if i%3==0 else Color("6dd9c0")
		for stem in range(3):
			var h = rng.randf_range(1,3.8)
			CharacterSculpt.leaf(realm,p+Vector3(stem*0.28,0,0),p+Vector3(stem*0.5,h,0.5),0.20,c,0.06)
		if i%4==0:
			Models.sphere(realm,p+Vector3.UP*0.25,Vector3(2.7,1.2,2),Color("709f98"))
	for i in range(32):
		var f = Node3D.new()
		realm.add_child(f)
		f.position = Vector3(rng.randf_range(-45,45),rng.randf_range(6,30),rng.randf_range(-40,40))
		Models.sphere(f,Vector3.ZERO,Vector3(0.65,0.25,0.19),Color("b8ead8"),0.25)
		CharacterSculpt.leaf(f,Vector3(0.2,0,0),Vector3(0.65,0.18,0),0.12,Color("d8dfb4"))
		fish.append(f)
	for i in range(sites.size()):
		var node = Node3D.new()
		realm.add_child(node)
		node.position = sites[i]-CENTER
		Models.cylinder(node,Vector3(0,-1,0),1.1,1.5,Color("91bbb2"),0.8,16)
		Models.crystal(node,Vector3.ZERO,0.75,Color("bde9dc"))
		Models.ring(node,Vector3.ZERO,1.5,Color("dccb97"),0.04)
		game.world._label(node,["珍珠邮局","潮汐档案馆","低音钟 · 海","中音钟 · 风","高音钟 · 星","归航钟庭"][i],Vector3(0,2,0),Color("e2f0db"),25)
	ray = Node3D.new()
	realm.add_child(ray)
	Models.sphere(ray,Vector3.ZERO,Vector3(1.4,0.3,1.8),Color("c6ede6"),0.3)
	for side in [-1,1]:
		CharacterSculpt.leaf(ray,Vector3(side*0.4,0,0),Vector3(side*2.1,0.25,0.6),0.65,Color("70bdd1"))
	CharacterSculpt.leaf(ray,Vector3(0,0,0.6),Vector3(0,-0.2,3),0.13,Color("c6ede6"))
	for i in range(3):
		var node = Node3D.new()
		realm.add_child(node)
		node.position = Vector3((i-1)*12,8+i*4,-28)
		Models.crystal(node,Vector3.ZERO,1.4,Color("e39ec9"))
		var ring = Models.ring(node,Vector3.ZERO,3,Color("ed91aa"),0.06)
		locks.append(node)
		rings.append(ring)
	for i in range(12):
		var chest = Node3D.new()
		realm.add_child(chest)
		chest.position = Vector3(-44+(i%4)*28,4+(i%3)*6,-43+(i/4)*34)
		Models.box(chest,Vector3.ZERO,Vector3(1.3,0.8,0.8),Color("284e62"))
		for x in [-0.47,0.47]:
			Models.box(chest,Vector3(x,0,0),Vector3(0.09,0.84,0.84),Color("dbcc9a"))
		Models.crystal(chest,Vector3(0,0.58,0),0.23,Color("b8eee0"))
		treasures.append(chest)
	Models.ring(realm,ENTRY-CENTER,2,Color("c4eeeb"),0.12).rotation.x = PI/2
	game.world._label(realm,"返回海面 · F",ENTRY-CENTER+Vector3.UP*3,Color("d6ede5"),28)
	_embellish()

func _embellish() -> void:
	var limestone=Color("b4c6b5")
	var rng=RandomNumberGenerator.new()
	rng.seed=9124
	for i in range(8):
		var z=24-i*8
		for side in [-1,1]:
			var x=side*10
			Models.cylinder(realm,Vector3(x,3.8,z),0.27,7.4,limestone,-1,20)
			Models.sphere(realm,Vector3(x,7.7,z),Vector3.ONE*0.7,Color("b7ecd6"),0.6)
			for h in [0.5,7.3]: Models.cylinder(realm,Vector3(x,h,z),0.49,0.2,Color("c8bd91"),-1,20)
	# Carved arcade bridges, each arch formed from separate curved stone sections.
	for z in [-8,12]:
		for i in range(18):
			var a=PI*i/17
			var brick=Models.box(realm,Vector3(cos(a)*10,7.3+sin(a)*6,z),Vector3(1.75,0.68,1.2),limestone)
			brick.rotation.z=atan2(cos(a)*6,-sin(a)*10)
			var trim=Models.box(realm,Vector3(cos(a)*10,7.3+sin(a)*6,z-0.64),Vector3(1.60,0.09,0.08),Color("c8bd91"))
			trim.rotation.z=brick.rotation.z
	# An open scalloped dome gives the central chamber a landmark silhouette.
	for i in range(12):
		var a=TAU*i/12
		for row in range(8):
			var t=row/8.0*PI/2
			var next=(row+1)/8.0*PI/2
			var from=Vector3(sin(a)*12*cos(t),24+sin(t)*10,-34+cos(a)*12*cos(t))
			var to=Vector3(sin(a)*12*cos(next),24+sin(next)*10,-34+cos(a)*12*cos(next))
			CharacterSculpt.leaf(realm,from,to,0.17,Color("c8c8a1"),0.09)
	for i in range(40):
		var a=TAU*i/40
		var p=Vector3(sin(a)*55,-0.5,cos(a)*55)
		Models.sphere(realm,p,Vector3(rng.randf_range(8,17),rng.randf_range(9,25),rng.randf_range(7,15)),Color("335e69"))
	for i in range(70):
		var x=rng.randf_range(-52,52)
		var z=rng.randf_range(-50,48)
		if absf(x)<13: continue
		var p=Vector3(x,0,z)
		for stem in range(5):
			var h=rng.randf_range(0.8,3)
			CharacterSculpt._lock(realm,p+Vector3(stem*0.1,0,0),p+Vector3(0.3,h*0.3,0.1),p+Vector3(-0.2,h*0.7,0.1),p+Vector3(0.4,h,0),0.15,0.018,Color("367f78"))
		if i%3==0:
			for branch in range(4):
				var top=p+Vector3(branch*0.25-0.3,0.8+branch*0.23,0)
				CharacterSculpt.leaf(realm,p,top,0.075,Color("db9aa8"),0.055)
				for side in [-1,1]: CharacterSculpt.leaf(realm,top-Vector3.UP*0.35,top+Vector3(side*0.32,0.23,0.1),0.055,Color("e5b1c2"),0.04)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-60,28,0)
	sun.light_color=Color("cdf8eb")
	sun.light_energy=0.65
	realm.add_child(sun)
	for i in range(5):
		var beam=Models.cylinder(realm,Vector3(-35+i*17,19,-18+i*8),2.5,36,Color.WHITE,0.3,24)
		beam.rotation.z=-0.25
		var mat=StandardMaterial3D.new()
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=Color(0.60,0.91,0.83,0.045)
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		beam.material_override=mat
		beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func apply_environment(value: bool) -> void:
	active = value
	realm.visible = value
	game.world.environment.environment = sea_env if value else outside_env
	game.player.camera.environment = sea_env if value else null

func contains(p: Vector3) -> bool:
	var q = p-CENTER
	return p.is_finite() and absf(q.x)<59 and absf(q.z)<59 and q.y>=0 and q.y<=42

func enter() -> void:
	if game.quest_stage<9:
		game.toast("完成第二章后，潜潮门将回应你。")
		return
	game.arts.clear()
	apply_environment(true)
	game.player.position = ENTRY
	game.player.velocity = Vector3.ZERO
	game.player.yaw = 0
	game.player.gliding = false
	game.player.dash_time = 0
	if game.quest_stage==25: game.quest_stage = 26
	game.ui.update_quest()
	game.save_game()
	game.toast("沉星海 · WASD 潜游 · 空格上浮 · Ctrl 下潜 · Shift 加速 · E 声波",8)

func leave() -> void:
	apply_environment(false)
	game.player.position = portal+Vector3(0,1,4)
	game.player.velocity = Vector3.ZERO
	game.player.avatar.rotation.x = 0
	game.last_safe_position = game.player.position
	game.ui.update_quest()
	game.save_game()

func nearby() -> Dictionary:
	var p = game.player.position
	if not active:
		return {"kind":"sea","index":-1,"prompt":"F   下潜 · 沉星海"} if p.distance_to(portal)<4 else {}
	if p.distance_to(ENTRY)<4: return {"kind":"sea","index":-2,"prompt":"F   返回海面"}
	for i in range(treasures.size()):
		if i not in opened and p.distance_to(treasures[i].global_position)<3:
			return {"kind":"sea","index":100+i,"prompt":"F   开启沉海宝箱 · 30 金币"}
	for i in range(sites.size()):
		if p.distance_to(sites[i])<4: return {"kind":"sea","index":i,"prompt":"F   聆听 / 共鸣"}
	return {}

func interact(id: int) -> void:
	if id==-1: enter(); return
	if id==-2: leave(); return
	if id>=100:
		var slot = id-100
		if slot<0 or slot>=treasures.size() or slot in opened: return
		opened.append(slot)
		game.coins+=30
		game.growth.books[1]+=1
		if not game.save_game():
			opened.erase(slot); game.coins-=30; game.growth.books[1]-=1; return
		treasures[slot].hide()
		game.toast("沉海宝箱 · 30 金币 · 冒险心得 ×1")
		return
	if game.quest_stage==26 and id==0:
		story([["澜音","这座邮局没有收件人，只有一封封写着『明天见』的信。可这里的人，已经等了一百年。"],["邮局录音","撤离船还有一个位置。小歌者，你先走。替我们记住海面上的风。"],["澜音","那个孩子……是我？我一直以为，是自己把大家遗忘了。"]],27)
	elif game.quest_stage==27 and id==1:
		story([["潮汐档案","撤离失败。守护装置启动『永恒晴日』，将全城的记忆锁在同一天。"],["霁霆","地上的守卫保护天空，海底的钟保护昨天。它们都在执行一道无法完成的命令：不许任何人离开。"],["澜音","我记起来了。妈妈教我的不是挽歌，是开门的旋律：先风，再海，最后星。三座钟的高度也各不相同。"]],28)
	elif game.quest_stage==28 and id in [2,3,4]:
		if bell_count>=3:
			story([["沧璃","三座钟已回应。跟上信使鳐，让它完成最后的航程。"]],29)
			return
		if id-2==BELL_ORDER[bell_count]:
			bell_count+=1
			game.audio.tone(430+bell_count*130,0.5,0.2)
			game.pulse(sites[id],Color("a1e9dd"),4,0.8)
			if bell_count==3:
				story([["沧璃","信使鳐醒了！它每年都在这条海路上来回，却一次也没能抵达终点。"],["澜音","跟上它吧。不是为了把昨天带回来，是为了让它终于抵达明天。"]],29)
			else: game.toast("声纹吻合 · %d / 3" % bell_count)
		else:
			bell_count=0
			game.toast("回声散开了。提示：风（中）→ 海（低）→ 星（高）",5)
		game.save_game()
	elif game.quest_stage==31 and id==5:
		game.begin_dialogue([["守潮者","若钟声停止，城里的人就会消失。你还要打开门吗？"],["澜音","记忆不该成为牢笼。让他们留下故事，也让活着的人能继续出发。"]],show_choice)
	else:
		game.begin_dialogue([["海城残响",["明日首航。请记得带上你想寄出的信。","『永恒晴日』并非让人复生，只让最后一天一遍遍重演。","海是低音。","风在中间。","星在最高处。","每一场告别，也可以是一次启程。"][clampi(id,0,5)]]])

func story(lines: Array, next: int) -> void:
	game.begin_dialogue(lines,func():
		var before = game.quest_stage
		game.quest_stage=next
		if not game.save_game(): game.quest_stage=before
		game.ui.update_quest())

func talk() -> void:
	match game.quest_stage:
		24:
			story([["阿芙 · 守灯人","今天收到一张从海底寄来的明信片。上面的邮戳是明天，落款却是……我的曾祖母。"],["澜音","『当第六声钟响起，别相信灯火通明的街道。』这不是邀请，是求救。"],["阿芙 · 守灯人","第二章那些未送达的信，原来还有后半句。去西北旧港的潜潮门吧，把答案带回来。"]],25)
		32:
			story([["阿芙 · 守灯人","我梦见了一座安静的海底城。她告诉我，不必替她守着旧灯，去点亮自己的。"],["澜音","我终于记起她的歌，也终于可以不再每天重复唱最后一句。"],["阿芙 · 守灯人","那封来自明天的信，原来是我们自己要写的。"]],33)
		33:
			game.begin_dialogue([["阿芙 · 守灯人","旧港的新船，明天清晨起航。第一位收件人，是愿意走向海面的你。"],["澜音","明天见。这一次，我们是真的在说——明天见。"]],finish)
		_:
			game.begin_dialogue([["阿芙 · 守灯人",info()[1]]])

func finish() -> void:
	if game.quest_stage!=33: return
	game.quest_stage=34
	game.coins+=900
	game.growth.books[2]+=3
	if not game.save_game():
		game.quest_stage=33; game.coins-=900; game.growth.books[2]-=3; return
	game.ui.update_quest()
	game.toast("第六章 · 沉星海书 完成 · 900 金币 · 星辉典藏 ×3",8)

func show_choice() -> void:
	game.mode="overlay"
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	game.ui._modal_base("寄往明天的信", "第六章 · 沉星海书 / 你的回答会记录在旅途手记里。")
	game.ui.journal_page="sea_choice"
	game.ui._label(game.ui.overlay,"旧城的故事，该怎样被记住？",Vector2(210,250),36,LumenUI.CREAM,Vector2(1040,90))
	game.ui._label(game.ui.overlay,"你不必替所有人决定如何告别。\n但可以为后来的人，留下一扇愿意倾听的门。",Vector2(210,365),24,LumenUI.MUTED,Vector2(1040,130))
	for i in range(2):
		var answer = ["将歌声寄向海面", "把旧城留作记忆的灯塔"][i]
		game.ui._button(game.ui.overlay,answer,Rect2(220+i*520,570,490,70),func(): choose(answer),true)

func choose(answer: String) -> void:
	if game.quest_stage!=31: return
	choice=answer
	game.quest_stage=32
	if not game.save_game(): game.quest_stage=31; choice=""; return
	game.close_overlay()
	story([["澜音","让歌替他们去看看新的世界。" if answer.begins_with("将") else "灯会留在这里。今后每一个迷航的人，都能听见他们的故事。"],["沧璃","看，海面亮起来了。回去吧，有人在等你的信。"]],32)

func info() -> Array:
	var i = clampi(game.quest_stage-24,0,10)
	return ["第六章 · "+TITLES[i],TASKS[i]]

func target() -> Dictionary:
	if not active:
		return {"pos": game.world.npc_position if game.quest_stage in [24,32,33,34] else portal,"name":"阿芙" if game.quest_stage in [24,32,33,34] else "潜潮门"}
	var p = ENTRY
	var label = "返回海面"
	match game.quest_stage:
		26: p=sites[0]; label="珍珠邮局"
		27: p=sites[1]; label="潮汐档案馆 · 向上潜游"
		28: p=sites[2+BELL_ORDER[mini(bell_count,2)]]; label="声纹钟 · 风 → 海 → 星"
		29: p=ray.global_position; label="信使鳐 · 保持 12 米内"
		30:
			for i in range(3):
				if i not in rescued: p=locks[i].global_position; label="潮汐锁链 · 靠近按 E"; break
		31: p=sites[5]; label="归航钟庭"
	return {"pos":p,"name":label}

func sonar() -> void:
	game.pulse(game.player.position,Color("a9ede5"),7,0.8)
	game.audio.tone(640,0.22,0.15)
	if game.quest_stage!=30: return
	if rescued.size()==3:
		story([["澜音","锁链已经全部解开。去中央钟庭，给旧城一个回答。"]],31)
		return
	for i in range(3):
		if i not in rescued and game.player.position.distance_to(locks[i].global_position)<6:
			rescued.append(i)
			if not game.save_game(): rescued.erase(i); return
			locks[i].hide()
			game.toast("潮汐锁链解开 · %d / 3" % rescued.size())
			if rescued.size()==3:
				story([["守潮者","保护……不是挽留？"],["澜音","你已经守了很久。接下来的海路，我们会陪他们走。"]],31)
			return

func _process(delta: float) -> void:
	if not active or not game.is_playing(): return
	if opened.size()>=10:
		var old = opened.duplicate()
		opened.clear()
		chest_round+=1
		if game.save_game():
			for chest in treasures: chest.show()
			game.toast("潮流带来新的沉海宝箱 · 第 %d 轮" % chest_round)
		else:
			opened.assign(old)
			chest_round-=1
	for i in range(fish.size()):
		fish[i].position.x += delta*(0.5+i%3*0.2)
		if fish[i].position.x>52: fish[i].position.x=-52
	if game.quest_stage==29 and game.player.position.distance_to(ray.global_position)<12:
		escort=minf(1,escort+delta/32.0)
		if escort>=1:
			story([["沧璃","它把信送到了。可钟庭还被锁着——那些红色的脉冲就是守护装置的心跳。"],["澜音","靠近锁链，用 E 声波解开。红环亮起后向上或向下躲避；不用伤害它。"]],30)
	ray.position = Vector3(-15,10,-14).lerp(Vector3(0,18,-31),escort)+Vector3(sin(escort*TAU)*7,0,0)
	if game.quest_stage==30:
		hazard_clock+=delta
		for i in range(rings.size()):
			rings[i].scale=Vector3.ONE*(1.0+fmod(hazard_clock,4.0)*0.9)
		if hazard_clock>=4:
			hazard_clock=0
			for i in range(3):
				if i in rescued: continue
				var q = game.player.position-locks[i].global_position
				if Vector2(q.x,q.z).length()<13 and absf(q.y)<1.8: game.player.take_damage(18)

func to_dict() -> Dictionary:
	return {"active":active,"bells":bell_count,"rescued":rescued,"opened":opened,"escort":escort,"choice":choice,"chest_round":chest_round}

func restore(data: Dictionary) -> void:
	bell_count=clampi(int(data.get("bells",0)),0,3)
	escort=clampf(float(data.get("escort",0)),0,1)
	choice=str(data.get("choice",""))
	chest_round=maxi(1,int(data.get("chest_round",1)))
	rescued.clear(); opened.clear()
	for id in data.get("rescued",[]):
		if int(id) in [0,1,2] and int(id) not in rescued: rescued.append(int(id))
	for id in data.get("opened",[]):
		if int(id)>=0 and int(id)<12 and int(id) not in opened: opened.append(int(id))
	for i in range(3): locks[i].visible=i not in rescued
	for i in range(12): treasures[i].visible=i not in opened
	ray.position=Vector3(-15,10,-14).lerp(Vector3(0,18,-31),escort)+Vector3(sin(escort*TAU)*7,0,0)
	# A save made before the closing dialogue must not strand a completed puzzle.
	if game.quest_stage==28 and bell_count==3: game.quest_stage=29
	if game.quest_stage==29 and escort>=1: game.quest_stage=30
	if game.quest_stage==30 and rescued.size()==3: game.quest_stage=31
	apply_environment(bool(data.get("active",false)))
