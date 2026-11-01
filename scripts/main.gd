class_name LumenGame
extends Node3D

var world: WildWorld
var player: LumenPlayer
var ui: LumenUI
var audio: LumenAudio
var title_camera: Camera3D
var enemies: Array[HollowEnemy] = []
var boss_enemy: HollowEnemy
var mode: String = "title"
var quest_stage: int = 0
var coins: int = 0
var enemies_defeated: int = 0
var reactions_triggered: int = 0
var interaction_prompt: String = ""
var interaction_kind: String = ""
var interaction_index: int = -1
var dialogue_lines: Array = []
var dialogue_index: int = 0
var dialogue_callback: Callable
var current_region: String = "风铃村"
var last_safe_position: Vector3
var save_path: String = GameData.SAVE_PATH
var test_mode: bool = false
var play_time: float = 0
var title_time: float = 0
var auto_shot: bool = false
var shot_clock: float = 0
var shot_taken: bool = false
var debug_frames: int = 0
var waypoint: Label3D
var wishes = WishSystem.new()
var party: Array[int] = [0, 1, 2, 3, 4]
var wish_rng = RandomNumberGenerator.new()
var wish_busy: bool = false
var campaign: LumenCampaign
var arts: ElementArts
var renewal: WorldRenewal
var pending_wish_results: Array = []
var growth: CharacterGrowth
var sea: DeepSea

func _ready() -> void:
	_setup_inputs()
	wish_rng.randomize()
	world = WildWorld.new()
	add_child(world)
	player = LumenPlayer.new()
	player.game = self
	add_child(player)
	player.position = world.spawn_position
	last_safe_position = world.spawn_position
	_spawn_enemies()
	campaign = LumenCampaign.new()
	campaign.game = self
	add_child(campaign)
	arts = ElementArts.new()
	arts.game = self
	add_child(arts)
	renewal = WorldRenewal.new()
	renewal.game = self
	add_child(renewal)
	growth = CharacterGrowth.new()
	growth.game = self
	add_child(growth)
	sea = DeepSea.new()
	sea.game = self
	add_child(sea)
	audio = LumenAudio.new()
	add_child(audio)
	ui = LumenUI.new()
	ui.game = self
	add_child(ui)
	title_camera = Camera3D.new()
	title_camera.fov = 59
	title_camera.far = 1200
	add_child(title_camera)
	title_camera.position = WildWorld.ground(34, 109, 20)
	title_camera.look_at(WildWorld.ground(-3, 48, 3))
	title_camera.make_current()
	waypoint = Label3D.new()
	waypoint.font = load("res://assets/ui_font.tres")
	waypoint.font_size = 36
	waypoint.pixel_size = 0.012
	waypoint.modulate = Color("ffe2a0")
	waypoint.outline_modulate = Color("263e44")
	waypoint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	waypoint.no_depth_test = true
	waypoint.visible = false
	add_child(waypoint)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.update_quest()
	auto_shot = "--capture" in OS.get_cmdline_user_args()
	if "--demo" in OS.get_cmdline_user_args():
		start_game(false)
	if "--map-preview" in OS.get_cmdline_user_args():
		start_game(false)
		open_overlay("map")
	if "--characters-preview" in OS.get_cmdline_user_args():
		start_game(false)
		open_overlay("characters")
	if "--combat-preview" in OS.get_cmdline_user_args():
		start_game(false)
		quest_stage = 2
		for i in range(5):
			world.activate_shrine(i)
		player.position = WildWorld.ground(0, -92, 0.4)
		player.set_character(3, false)
		player.yaw = -0.15
		boss_enemy.awakened = true
		boss_enemy.attack_timer = 100
		ui.update_quest()
	if auto_shot:
		# Preview captures are isolated from the user's save.
		save_path = "user://preview_unused.json"
	for preview in ["wish", "wish-results", "limited", "chapter"]:
		if ("--" + preview + "-preview") in OS.get_cmdline_user_args():
			start_game(false)
			coins = 1800
			open_overlay("wish")
			if preview == "wish-results":
				wishes.pity = WishSystem.SOFT_PITY - 1
				wishes.guaranteed = true
				perform_wish(10)
			elif preview == "limited":
				ui.show_characters(true)
			elif preview == "chapter":
				quest_stage = 6
				campaign.sync_stage()
				ui.show_journal(2)

func _setup_inputs() -> void:
	var keys = {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "jump": KEY_SPACE, "sprint": KEY_SHIFT, "skill": KEY_E, "burst": KEY_Q, "interact": KEY_F, "map": KEY_M, "characters": KEY_C, "journal": KEY_J, "pause": KEY_ESCAPE, "wish": KEY_G, "potion": KEY_R}
	keys["bestiary"] = KEY_B
	keys["growth"] = KEY_U
	keys["dive_down"] = KEY_CTRL
	keys["gallery"] = KEY_P
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event = InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for i in range(5):
		var action = "character_" + str(i + 1)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event = InputEventKey.new()
		event.physical_keycode = KEY_1 + i
		InputMap.action_add_event(action, event)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mouse)

func _spawn_enemies() -> void:
	for i in range(5):
		var center: Vector3 = world.shrines[i]["pos"]
		for j in range(2):
			var p = WildWorld.ground(center.x + (-5.6 if j == 0 else 5.8), center.z + 7.7, 0.3)
			_create_enemy(p, i, false)
	for p in [Vector2(23, 14), Vector2(-23, -4), Vector2(39, -21), Vector2(-79, 66)]:
		_create_enemy(WildWorld.ground(p.x, p.y, 0.3), -1, false)
	boss_enemy = _create_enemy(world.boss_position, -2, true)
	boss_enemy.awakened = false

func _create_enemy(pos: Vector3, shrine_index: int, is_boss: bool) -> HollowEnemy:
	var enemy = HollowEnemy.new()
	enemy.game = self
	enemy.boss = is_boss
	enemy.kind = 0 if is_boss else enemies.size() % 5
	enemy.shrine_index = shrine_index
	enemy.position = world.solids.resolve(pos, 1.0)
	enemy.set_meta("enemy_id", enemies.size())
	add_child(enemy)
	enemies.append(enemy)
	return enemy

func _process(delta: float) -> void:
	if mode == "title":
		title_time += delta
		title_camera.position = WildWorld.ground(34 + sin(title_time * 0.055) * 3, 109, 20)
		title_camera.look_at(WildWorld.ground(-3, 48, 3))
	if is_playing():
		play_time += delta
		_update_interaction()
		_update_region()
		_update_waypoint()
	if auto_shot and not shot_taken:
		shot_clock += delta
		debug_frames += 1
		if shot_clock > 7 and debug_frames > 20:
			shot_taken = true
			_capture_preview.call_deferred()

func _capture_preview() -> void:
	await RenderingServer.frame_post_draw
	var label = "title"
	for kind in ["demo", "map-preview", "characters-preview", "combat-preview", "wish-preview", "wish-results-preview", "limited-preview", "chapter-preview"]:
		if ("--" + kind) in OS.get_cmdline_user_args():
			label = kind
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var path = "res://artifacts/" + label + ".png"
	var err = get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE ", path, " ", err, " fps=", Engine.get_frames_per_second())
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if mode == "dialogue":
		if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
			advance_dialogue()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if mode == "playing":
			open_overlay("pause")
		elif mode == "overlay":
			close_overlay()
		elif mode == "title":
			ui.clear_overlay()
		get_viewport().set_input_as_handled()
		return
	for key in ["map", "characters", "journal", "wish", "bestiary", "growth", "gallery"]:
		if event.is_action_pressed(key):
			if mode == "playing":
				open_overlay(key)
			elif mode == "overlay":
				close_overlay()
			get_viewport().set_input_as_handled()
			return
	if is_playing() and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()

func is_playing() -> bool:
	return mode == "playing"

func start_game(load_existing: bool = true) -> void:
	if not load_existing:
		_reset_progress()
	elif has_save():
		load_game()
	mode = "playing"
	ui.menu.visible = false
	ui.hud.visible = true
	ui.clear_overlay()
	player.enabled = true
	player.camera.make_current()
	waypoint.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ui.update_quest()
	save_game()
	toast("WASD 移动 · 空格跳跃 · F 交互 · Esc 查看操作", 6)
	renewal.request_check()

func _reset_progress() -> void:
	arts.clear()
	growth.reset()
	sea.restore({})
	renewal.reset()
	pending_wish_results.clear()
	wishes = WishSystem.new()
	party = [0, 1, 2, 3, 4]
	wish_busy = false
	quest_stage = 0
	coins = 0
	enemies_defeated = 0
	reactions_triggered = 0
	play_time = 0
	for shrine in world.shrines:
		shrine["active"] = false
		shrine["beam"].visible = true
		shrine["halo"].material_override = Models.material(GameData.element_color(shrine["element"]), 0.45)
	for chest in world.chests:
		chest["opened"] = false
		chest["lid"].rotation = Vector3.ZERO
		chest["lid"].position = Vector3(0, 0.98, 0)
	for enemy in enemies:
		if is_instance_valid(enemy.telegraph):
			enemy.telegraph.queue_free()
		if enemy.beast:
			enemy.beast.reset()
		enemy.dead = false
		enemy.visible = true
		enemy.collision_layer = 4
		enemy.hp = enemy.max_hp
		enemy.health_bar.scale.x = 1
		enemy.position = enemy.home
		enemy.velocity = Vector3.ZERO
		enemy.engaged = false
		enemy.element = -1
		enemy.element_time = 0
		enemy.burn_time = 0
		enemy.windup = -1
		enemy.attack_timer = 2
		enemy.awakened = not enemy.boss
	boss_enemy.awakened = false
	campaign.completed.clear()
	campaign.afterlight.reset_escort()
	campaign.sync_stage()
	world.beacon.visible = false
	player.position = world.spawn_position
	player.velocity = Vector3.ZERO
	player.hp = player.max_hp
	player.energy = 65
	player.stamina = 100
	player.shield = 0
	player.yaw = 0
	player.pitch = -0.22
	player.gliding = false
	player.dash_time = 0
	player.skill_cooldowns.fill(0)
	player.burst_cooldown = 0
	player.set_character(0, false)
	last_safe_position = world.spawn_position

func return_to_title() -> void:
	save_game()
	sea.apply_environment(false)
	arts.clear()
	mode = "title"
	player.enabled = false
	ui.clear_overlay()
	ui.hud.visible = false
	ui.menu.queue_free()
	ui._build_menu()
	title_camera.make_current()
	waypoint.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func open_overlay(kind: String) -> void:
	mode = "overlay"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	match kind:
		"map": ui.show_map()
		"characters": ui.show_characters()
		"growth": ui.show_growth(player.character_index)
		"gallery": ui.show_gallery()
		"bestiary": ui.show_bestiary()
		"journal": ui.show_journal()
		"wish": ui.show_wish()
		_: ui.show_pause()

func close_overlay() -> void:
	if wish_busy:
		finish_wish_animation()
		return
	ui.clear_overlay()
	if mode != "title":
		mode = "playing"
		ui.hud.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _update_interaction() -> void:
	interaction_kind = ""
	interaction_index = -1
	interaction_prompt = ""
	var p = player.global_position
	var sea_interaction = sea.nearby()
	if not sea_interaction.is_empty():
		interaction_kind = "sea"
		interaction_index = sea_interaction["index"]
		interaction_prompt = sea_interaction["prompt"]
		return
	if sea.active:
		return
	if p.distance_to(world.npc_position) < 4.4:
		interaction_kind = "npc"
		interaction_prompt = "F   与阿芙交谈"
		return
	var extra = campaign.get_interaction()
	if not extra.is_empty():
		interaction_kind = extra["kind"]
		interaction_index = extra["index"]
		interaction_prompt = extra["prompt"]
		return
	for i in range(5):
		if p.distance_to(world.shrines[i]["pos"]) < 6.0:
			interaction_kind = "shrine"
			interaction_index = i
			if world.shrines[i]["active"]:
				interaction_prompt = "F   在星核旁休息 · 恢复生命"
			elif quest_stage == 0:
				interaction_prompt = "尚未解读星核 · 先与村中的阿芙交谈"
			elif shrine_guard_count(i) > 0:
				interaction_prompt = "清除附近的蚀光体  ·  剩余 %d" % shrine_guard_count(i)
			elif GameData.element_of(player.character_index) != i:
				interaction_prompt = "切换 %d  %s · 使用%s元素共鸣" % [i + 1, GameData.CHARACTERS[i]["name"], GameData.CHARACTERS[i]["element"]]
			else:
				interaction_prompt = "F   唤醒" + GameData.SHRINES[i]["name"] + "星核"
			return
	for i in range(world.chests.size()):
		if not world.chests[i]["opened"] and p.distance_to(world.chests[i]["pos"]) < 3.2:
			interaction_kind = "chest"
			interaction_index = i
			interaction_prompt = "F   开启金币宝箱"
			return
	var gathering = growth.nearby()
	if gathering >= 0:
		interaction_kind = "material"
		interaction_index = gathering
		interaction_prompt = "F   采集 " + growth.material_name(growth.nodes[gathering]["item"])
		return
	if quest_stage <= 2 and p.distance_to(world.boss_position) < 18 and not boss_enemy.awakened:
		interaction_kind = "boss"
		interaction_prompt = "F   汇聚五道星光 · 唤醒天穹守卫" if quest_stage == 2 else "天穹之门需要五座星核的共鸣"

func interact() -> void:
	_update_interaction()
	match interaction_kind:
		"sea":
			sea.interact(interaction_index)
		"material":
			growth.gather(interaction_index)
		"npc":
			_npc_dialogue()
		"campaign":
			campaign.interact_point(interaction_index)
		"campaign_boss":
			campaign.start_boss(interaction_index)
		"shrine":
			_interact_shrine(interaction_index)
		"chest":
			world.open_chest(interaction_index)
			coins += GameData.CHEST_COINS
			player.energy = minf(100, player.energy + 25)
			player.hp = minf(player.max_hp, player.hp + 20)
			pulse(world.chests[interaction_index]["pos"] + Vector3.UP, Color("ffe3a5"), 2.8, 0.8)
			audio.tone(880, 0.5, 0.3)
			toast("获得 30 金币 · 25 共鸣能量 · 恢复 20 生命")
			renewal.collected_total += 1
			renewal.request_check()
			save_game()
		"boss":
			if quest_stage == 2:
				begin_dialogue([["霁霆", "导师留下的警告是真的。守卫一直在保护天空，却忘了脚下还有我们。"], ["岚羽", "那就让它听见——这片土地，还在呼吸。"]], func():
					boss_enemy.awakened = true
					player.energy = 100
					toast("天穹守卫已苏醒 · 留意地面的红色预警", 5))

func _npc_dialogue() -> void:
	if quest_stage >= 4:
		campaign.talk_to_npc()
		return
	if quest_stage == 0:
		begin_dialogue([
			["阿芙 · 守灯人", "你也收到了那封没有署名的信？七天前，风停下来的时候，它出现在每个人的窗前。奇怪的是，每一封的邮戳都是明天。"],
			["阿芙 · 守灯人", "星屿曾被五座星核守护。现在，蚀光体盘踞在遗迹周围，天空的回声也消失了。"],
			["阿芙 · 守灯人", "带上你的伙伴。清除蚀光体，再用对应的元素唤醒星核。风、焰、潮、雷、岩……缺一不可。"],
			["岚羽", "信里那句「别让明天再来一次」，是什么意思？我会把答案带回来。请你为我们留一盏灯。"]
		], func():
			quest_stage = 1
			ui.update_quest()
			save_game()
			toast("主线开启 · 唤醒五道微光 · M 查看地图", 5))
	elif quest_stage == 1:
		begin_dialogue([["阿芙 · 守灯人", "还有 %d 座星核没有回应。用地图寻找遗迹，记得先清除蚀光体，再切换对应元素的伙伴。" % (5 - active_shrine_count())], ["阿芙 · 守灯人", "累了就回村休息。澜音的潮汐环能治疗伤势，砾川的磐石能保护大家。"]], func():
			player.hp = player.max_hp
			toast("阿芙为你恢复了全部生命"))
	elif quest_stage == 2:
		begin_dialogue([["阿芙 · 守灯人", "五道光都亮起来了。北方观测庭里的守卫，还在等待最后一次唤醒。"]])
	elif quest_stage == 3:
		begin_dialogue([
			["阿芙 · 守灯人", "听见了吗？风铃响了。整整七天，我几乎要忘记这个声音。"],
			["澜音", "守卫不是我们的敌人。它只是独自守了太久，忘记了如何放下。"],
			["阿芙 · 守灯人", "信上还有一行字，只有迎着光才能看见：『谢谢你，没有忘记回家的路。』"],
			["岚羽", "走吧。风已经回来，而我们的旅途才刚刚开始。"]
		], func():
			quest_stage = 4
			coins += 200
			ui.update_quest()
			save_game()
			mode = "overlay"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			ui.show_ending())
	else:
		begin_dialogue([["阿芙 · 守灯人", "风铃总会为你留一首歌。去看看岛上的角落吧，那些宝箱和未走过的路，也在等待你。"]], func(): player.hp = player.max_hp)

func _interact_shrine(index: int) -> void:
	if world.shrines[index]["active"]:
		player.hp = player.max_hp
		player.stamina = 100
		last_safe_position = world.shrines[index]["pos"] + Vector3(0, 0.5, 4.5)
		toast("星核共鸣 · 生命与体力已恢复")
		save_game()
		return
	if quest_stage != 1 or shrine_guard_count(index) > 0 or GameData.element_of(player.character_index) != index:
		return
	world.activate_shrine(index)
	coins += 60
	player.hp = player.max_hp
	player.energy = 100
	last_safe_position = world.shrines[index]["pos"] + Vector3(0, 0.5, 4.5)
	pulse(world.shrines[index]["pos"], GameData.element_color(index), 8, 1.4)
	spark(world.shrines[index]["pos"] + Vector3.UP * 3, GameData.element_color(index), 24)
	audio.tone(660, 0.7, 0.3)
	if active_shrine_count() == 5:
		quest_stage = 2
		world.beacon.visible = true
	begin_dialogue([[GameData.CHARACTERS[index]["name"], GameData.SHRINES[index]["memory"]]], func():
		if quest_stage == 2:
			toast("五道微光已汇聚 · 前往北方的星陨观测庭", 6)
		else:
			toast("星核已唤醒 · 获得 60 金币 · 传送点已解锁", 5))
	ui.update_quest()
	save_game()

func begin_dialogue(lines: Array, callback: Callable = Callable()) -> void:
	ui.hud.visible=false
	waypoint.visible=false
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_callback = callback
	mode = "dialogue"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_display_dialogue_line()

func _display_dialogue_line() -> void:
	var line = dialogue_lines[dialogue_index]
	ui.show_dialogue(line[0], line[1], "%d / %d" % [dialogue_index + 1, dialogue_lines.size()])

func advance_dialogue() -> void:
	if mode != "dialogue":
		return
	if ui.dialogue_text.visible_ratio < 1.0:
		ui.dialogue_text.visible_ratio = 1.0
		return
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		ui.dialogue.visible = false
		ui.hud.visible=true
		mode = "playing"
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if dialogue_callback.is_valid():
			var callback = dialogue_callback
			dialogue_callback = Callable()
			callback.call()
	else:
		_display_dialogue_line()

func perform_attack(kind: String) -> void:
	var character_id = player.character_index
	var index = GameData.element_of(character_id)
	var color = GameData.character_color(character_id)
	var reach = 5.3 if kind == "normal" else (13.0 if kind == "skill" else 19.0)
	if index in [1, 2, 3] and kind == "skill":
		reach = 20.0
	if character_id == 7 and kind != "normal":
		reach += 5.0
	var damage_amount = 22.0 if kind == "normal" else (51.0 if kind == "skill" else 124.0)
	damage_amount *= wishes.damage_multiplier(character_id) * growth.damage_multiplier(character_id) * (1.3 if character_id >= 5 else 1.0)
	var nearest: HollowEnemy = null
	var nearest_distance = reach + 1
	for enemy in enemies:
		if enemy.dead or not enemy.awakened:
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if is_instance_valid(nearest):
		var direction = nearest.global_position - player.global_position
		player.avatar.rotation.y = atan2(-direction.x, -direction.z)
	var forward = -player.avatar.global_basis.z
	if kind == "normal":
		var slash = Models.ring(self, player.global_position + Vector3.UP * 1.05 + forward * 1.5, 1.5, color, 0.095)
		slash.rotation.x = 0.2
		var tween = create_tween()
		tween.tween_property(slash, "scale", Vector3(1.5, 0.1, 1.5), 0.21)
		tween.tween_callback(slash.queue_free)
	else:
		pulse(player.global_position + Vector3.UP * 0.3, color, 4.0 if kind == "skill" else 12.0, 0.6 if kind == "skill" else 1.0)
		spark(player.global_position + Vector3.UP * 1.5, color, 12 if kind == "skill" else 30)
		toast(GameData.character(character_id)["skill"] if kind == "skill" else GameData.character(character_id)["burst"], 1.5)
		if index == 0 and kind == "skill":
			player.velocity.y = 6.5
		if index == 4:
			for i in range(5):
				var p = player.position + Vector3(sin(i * TAU / 5) * 2.4, -0.6, cos(i * TAU / 5) * 2.4)
				var pillar = Models.crystal(self, p, 1.8, color)
				var tween = create_tween()
				tween.tween_property(pillar, "position:y", p.y + 2.0, 0.25)
				tween.tween_property(pillar, "scale", Vector3.ONE * 0.01, 0.55).set_delay(0.5)
				tween.tween_callback(pillar.queue_free)
	for enemy in enemies:
		if enemy.dead or not enemy.awakened:
			continue
		var difference = enemy.global_position - player.global_position
		var distance = difference.length()
		var effective_reach = reach + (2.0 if enemy.boss else 0.0)
		if distance <= effective_reach and (kind != "normal" or difference.normalized().dot(forward) > -0.1):
			enemy.damage(damage_amount, index)
			if kind != "normal":
				if index == 3:
					lightning(player.global_position + Vector3.UP * 1.4, enemy.global_position + Vector3.UP * 1.4, color)
				else:
					projectile(player.global_position + Vector3.UP * 1.3, enemy.global_position + Vector3.UP * 1.4, color)
			if index == 0 and kind != "normal" and not enemy.boss and not enemy.dead:
				enemy.position = enemy.position.lerp(player.position + forward * 3, 0.32)
	audio.tone(180 + index * 80 if kind == "normal" else 520 + index * 90, 0.1 if kind == "normal" else 0.3, 0.17)

func spread_damage(source: HollowEnemy, amount: float) -> void:
	for enemy in enemies:
		if enemy != source and not enemy.dead and enemy.awakened and enemy.global_position.distance_to(source.global_position) < 7:
			enemy.damage(amount, -1, false)

func on_enemy_defeated(enemy: HollowEnemy) -> void:
	renewal.request_check()
	growth.spawn_drop(enemy)
	enemies_defeated += 1
	coins += 12 if not enemy.boss else 150
	player.energy = minf(100, player.energy + 18)
	if campaign.on_enemy_defeated(enemy):
		pass
	elif enemy == boss_enemy:
		quest_stage = 3
		world.beacon.visible = true
		ui.update_quest()
		toast("天穹守卫已净化 · 回到风铃村，与阿芙分享消息", 8)
		audio.tone(784, 0.8, 0.3)
	elif enemy.shrine_index >= 0 and shrine_guard_count(enemy.shrine_index) == 0:
		toast("遗迹已净化 · 切换对应元素，靠近星核按 F 共鸣", 5)
	save_game()

func active_shrine_count() -> int:
	var count = 0
	for shrine in world.shrines:
		if shrine["active"]:
			count += 1
	return count

func opened_chest_count() -> int:
	var count = 0
	for chest in world.chests:
		if chest["opened"]:
			count += 1
	return count

func shrine_guard_count(index: int) -> int:
	var count = 0
	for enemy in enemies:
		if enemy.shrine_index == index and not enemy.dead:
			count += 1
	return count

func _update_region() -> void:
	var region = "逐光原野"
	if player.position.distance_to(world.spawn_position) < 39:
		region = "风铃村"
	elif player.position.distance_to(world.boss_position) < 29:
		region = "星陨观测庭"
	else:
		for i in range(5):
			if player.position.distance_to(world.shrines[i]["pos"]) < 27:
				region = GameData.SHRINES[i]["name"]
	if sea.active:
		region = "沉星海 · 深度 %d m" % int(42-(player.position.y-DeepSea.CENTER.y))
	if region != current_region:
		current_region = region
		ui.location.text = region

func _update_waypoint() -> void:
	var target = world.npc_position
	var content = "阿芙"
	if quest_stage == 1:
		var shortest = INF
		for i in range(5):
			if not world.shrines[i]["active"]:
				var distance = player.position.distance_to(world.shrines[i]["pos"])
				if distance < shortest:
					shortest = distance
					target = world.shrines[i]["pos"]
					content = GameData.SHRINES[i]["name"]
	elif quest_stage == 2:
		target = world.boss_position
		content = "天穹守卫"
	elif quest_stage >= 4:
		var objective = campaign.current_target()
		target = objective["pos"]
		content = objective["name"]
	waypoint.visible = quest_stage < GameData.LAST_QUEST and mode == "playing"
	if growth.tracked_material >= 0 and not sea.active:
		var gathering_target = growth.target()
		if not gathering_target.is_empty():
			target = gathering_target["pos"]
			content = growth.material_name(gathering_target["item"])
			if gathering_target["ready_at"] > play_time:
				content += " · %d 秒后再生" % ceili(gathering_target["ready_at"]-play_time)
			waypoint.visible = mode == "playing"
	if sea.active:
		var destination = sea.target()
		target = destination["pos"]
		content = destination["name"]
		waypoint.visible = mode == "playing"
	if active_boss() != null:
		waypoint.visible = false
	if quest_stage == 2 and boss_enemy.awakened and player.position.distance_to(target) < 28:
		waypoint.visible = false
	waypoint.position = target + Vector3.UP * (2.4 if sea.active else 7.7)
	var distance = int(player.position.distance_to(target))
	waypoint.text = "◇  %s\n%d m" % [content, distance]
	waypoint.fixed_size = true
	waypoint.pixel_size = 0.0006

func fast_travel(index: int) -> bool:
	if index >= 0 and (index >= 5 or not world.shrines[index]["active"]):
		return false
	for enemy in enemies:
		if not enemy.dead and enemy.awakened and player.position.distance_to(enemy.position) < 20:
			toast("附近有敌人 · 脱离战斗后再传送", 4)
			return false
	if not player.is_on_floor() and not test_mode and not sea.active:
		toast("站稳之后才能传送", 3)
		return false
	sea.apply_environment(false)
	player.avatar.rotation.x = 0
	var destination = world.spawn_position if index < 0 else world.shrines[index]["pos"] + Vector3(0, 1, 5)
	arts.clear()
	player.dash_time = 0
	player.position = destination
	player.velocity = Vector3.ZERO
	player.hp = player.max_hp
	player.stamina = 100
	last_safe_position = destination
	close_overlay()
	pulse(destination, Color("f6dc9b"), 3.0, 0.7)
	save_game()
	return true

func recover_player(message: String) -> void:
	arts.clear()
	player.dash_time = 0
	player.position = DeepSea.ENTRY if sea.active else last_safe_position
	player.velocity = Vector3.ZERO
	player.hp = player.max_hp
	player.stamina = 100
	player.energy = maxf(player.energy, 50)
	player.gliding = false
	player.invulnerability = 3.0
	for enemy in enemies:
		if not enemy.dead:
			if enemy.beast:
				enemy.beast.reset()
			enemy.position = enemy.home
			enemy.engaged = false
			enemy.windup = -1
			enemy.attack_timer = 2.0
			if is_instance_valid(enemy.telegraph):
				enemy.telegraph.queue_free()
	toast(message, 5)

func pulse(pos: Vector3, color: Color, radius: float, duration: float) -> void:
	var ring = Models.ring(self, pos, 1, color, 0.055)
	ring.scale = Vector3.ONE * 0.2
	var tween = create_tween()
	tween.tween_property(ring, "scale", Vector3(radius, 0.1, radius), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(ring.queue_free)

func spark(pos: Vector3, color: Color, count: int) -> void:
	for i in range(count):
		var shard = Models.crystal(self, pos, randf_range(0.08, 0.18), color)
		var target = pos + Vector3(randf_range(-2, 2), randf_range(0.3, 3), randf_range(-2, 2))
		var tween = create_tween().set_parallel(true)
		tween.tween_property(shard, "position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "scale", Vector3.ONE * 0.02, 0.65)
		tween.chain().tween_callback(shard.queue_free)

func projectile(from: Vector3, to: Vector3, color: Color) -> void:
	var effect = Models.crystal(self, from, 0.4, color)
	var tween = create_tween()
	tween.tween_property(effect, "position", to, 0.2)
	tween.tween_callback(effect.queue_free)

func floating_text(pos: Vector3, content: String, color: Color) -> void:
	var label = Label3D.new()
	label.font = load("res://assets/ui_font.tres")
	label.font_size = 49
	label.text = content
	label.modulate = color
	label.outline_modulate = Color("293c47")
	label.outline_size = 8
	label.pixel_size = 0.011
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = pos + Vector3(randf_range(-0.3, 0.3), 0, 0)
	add_child(label)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.5, 0.85)
	tween.tween_property(label, "modulate:a", 0.0, 0.85)
	tween.chain().tween_callback(label.queue_free)

func lightning(from: Vector3, to: Vector3, color: Color) -> void:
	var previous = from
	for i in range(1, 8):
		var next = from.lerp(to, float(i) / 7.0)
		if i < 7:
			next += Vector3(randf_range(-0.6, 0.6), randf_range(-0.5, 0.5), 0)
		var segment = Models.box(self, previous.lerp(next, 0.5), Vector3(0.09, 0.09, previous.distance_to(next)), color)
		segment.material_override = Models.material(color, 1.2)
		segment.look_at(next)
		var tween = create_tween()
		tween.tween_interval(0.18)
		tween.tween_callback(segment.queue_free)
		previous = next

func toast(message: String, duration: float = 3.0) -> void:
	if is_instance_valid(ui):
		ui.show_toast(message, duration)

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func save_game() -> bool:
	if auto_shot or "--capture" in OS.get_cmdline_user_args():
		return true
	var active: Array = []
	var opened: Array = []
	var defeated: Array = []
	for i in range(5):
		if world.shrines[i]["active"]:
			active.append(i)
	for i in range(world.chests.size()):
		if world.chests[i]["opened"]:
			opened.append(i)
	for i in range(enemies.size()):
		if enemies[i].dead:
			defeated.append(i)
	var safe = player.position
	if not (sea.active and sea.contains(safe)) and (safe.y < -0.5 or Vector2(safe.x, safe.z).length() > 163):
		safe = last_safe_position
	var data = {"version": 5, "deepsea": sea.to_dict(), "quest": quest_stage, "coins": coins, "character": player.character_index, "active": active, "opened": opened, "defeated": defeated, "position": [safe.x, safe.y, safe.z], "safe_position": [last_safe_position.x, last_safe_position.y, last_safe_position.z], "hp": player.hp, "energy": player.energy, "enemies_defeated": enemies_defeated, "reactions": reactions_triggered, "play_time": play_time, "wishes": wishes.to_dict(), "party": party, "campaign": campaign.completed, "renewal": renewal.to_dict(), "growth": growth.to_dict()}
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.flush()
		var write_error = file.get_error()
		file.close()
		if write_error != OK:
			toast("存档写入失败", 5)
			return false
		var err = DirAccess.rename_absolute(save_path + ".tmp", save_path)
		if err != OK:
			toast("存档写入失败，请检查用户目录权限", 5)
			return false
		return true
	else:
		toast("存档写入失败，请检查用户目录权限", 5)
	return false

func load_game() -> bool:
	if not has_save():
		return false
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("version", 0)) not in [1, 2, 3, 4, 5]:
		toast("存档无法读取，已开启新的旅途", 5)
		return false
	_reset_progress()
	quest_stage = clampi(int(data.get("quest", 0)), 0, GameData.LAST_QUEST)
	coins = maxi(0, int(data.get("coins", 0)))
	enemies_defeated = maxi(0, int(data.get("enemies_defeated", 0)))
	reactions_triggered = maxi(0, int(data.get("reactions", 0)))
	play_time = maxf(0, float(data.get("play_time", 0)))
	growth.restore(data.get("growth", {}))
	renewal.restore(data.get("renewal", {}))
	for i in data.get("active", []):
		if int(i) >= 0 and int(i) < 5:
			world.activate_shrine(int(i))
	for i in data.get("opened", []):
		if int(i) >= 0 and int(i) < world.chests.size():
			world.open_chest(int(i))
	for i in data.get("defeated", []):
		if int(i) >= 0 and int(i) < enemies.size():
			enemies[int(i)].dead = true
			enemies[int(i)].visible = false
			enemies[int(i)].collision_layer = 0
	sea.restore(data.get("deepsea", {}))
	var p = data.get("position", [0, 8, 77])
	if p is Array and p.size() == 3:
		player.position = Vector3(float(p[0]), float(p[1]) + 0.15, float(p[2]))
		if sea.active:
			if not sea.contains(player.position): player.position = DeepSea.ENTRY
		elif not player.position.is_finite() or Vector2(player.position.x, player.position.z).length() > 163:
			player.position = world.spawn_position
	var safe = data.get("safe_position", [0, 8, 77])
	if safe is Array and safe.size() == 3:
		last_safe_position = Vector3(float(safe[0]), float(safe[1]), float(safe[2]))
		if not last_safe_position.is_finite() or Vector2(last_safe_position.x, last_safe_position.z).length() > 163:
			last_safe_position = world.spawn_position
	player.hp = clampf(float(data.get("hp", 180)), 1, player.max_hp)
	if not sea.active:
		player.position = world.solids.resolve(player.position)
	last_safe_position = world.solids.resolve(last_safe_position)
	player.energy = clampf(float(data.get("energy", 65)), 0, 100)
	wishes.restore(data.get("wishes", {}))
	var saved_party = data.get("party", [])
	if saved_party is Array and saved_party.size() == 5:
		for i in range(5):
			var id = int(saved_party[i])
			if wishes.has_character(id) and GameData.element_of(id) == i:
				party[i] = id
	var character_id = clampi(int(data.get("character", 0)), 0, GameData.CHARACTER_COUNT - 1)
	player.set_character(character_id if character_id in party else party[0], false)
	campaign.restore(data.get("campaign", []))
	renewal.collected_total = maxi(renewal.collected_total, opened_chest_count())
	world.beacon.visible = quest_stage >= 2
	ui.update_quest()
	renewal.request_check()
	return true

func active_boss() -> HollowEnemy:
	for enemy in enemies:
		if enemy.boss and enemy.awakened and not enemy.dead and player.position.distance_to(enemy.position) < 35:
			return enemy
	return null

func equip_character(index: int) -> bool:
	if not wishes.has_character(index):
		return false
	party[GameData.element_of(index)] = index
	player.switch_cooldown = 0
	player.set_character(index)
	save_game()
	return true

func use_potion() -> void:
	if not is_playing():
		return
	if wishes.potions <= 0:
		toast("没有旅行药剂 · 可通过祈愿获得")
		return
	if player.hp >= player.max_hp:
		toast("生命已满，无需使用药剂")
		return
	wishes.potions -= 1
	player.hp = minf(player.max_hp, player.hp + 45)
	pulse(player.position, Color("a6e4b8"), 2.2, 0.5)
	toast("使用旅行药剂 · 恢复 45 生命")
	save_game()

func perform_wish(count: int) -> Dictionary:
	if wish_busy or mode != "overlay" or ui.journal_page != "wish":
		return {"ok": false}
	wish_busy = true
	var before = wishes.to_dict()
	var before_coins = coins
	var outcome = wishes.draw_many(count, wishes.banner, coins, wish_rng, GameData.rotation_for_quest(quest_stage))
	if not outcome["ok"]:
		toast(outcome["error"], 4)
		wish_busy = false
		return outcome
	coins -= outcome["spent"]
	if not save_game():
		wishes.restore(before)
		coins = before_coins
		wish_busy = false
		toast("祈愿未完成，金币已保留 · 请检查存档目录", 5)
		return {"ok": false}
	pending_wish_results = outcome["results"].duplicate(true)
	ui.show_wish_animation(pending_wish_results)
	return outcome

func finish_wish_animation() -> void:
	if not wish_busy or pending_wish_results.is_empty():
		return
	var results = pending_wish_results.duplicate(true)
	pending_wish_results.clear()
	wish_busy = false
	ui.show_wish_results(results)

func sync_wish_banner() -> void:
	var available = GameData.banner_ids(quest_stage)
	if wishes.banner not in available:
		wishes.banner = available[0]

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if mode != "title" and is_instance_valid(player):
			save_game()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mode == "playing" and is_instance_valid(ui) and not auto_shot and not test_mode:
			open_overlay("pause")
