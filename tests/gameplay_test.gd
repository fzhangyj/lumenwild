extends SceneTree

var game: LumenGame
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS ", message)
	else:
		failures.append(message)
		push_error("FAIL " + message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func finish_dialogue() -> void:
	var guard = 0
	while game.mode == "dialogue" and guard < 10:
		game.advance_dialogue()
		guard += 1

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_integration_test.json"
	root.add_child(game)
	current_scene = game
	game.audio.muted = true
	await frames(3)
	check(game.mode == "title" and game.ui.menu.visible, "Title scene loads")
	check(game.world.shrines.size() == 5 and game.world.chests.size() == 18, "Five elemental shrines and eighteen chests exist")
	check(game.enemies.size() == 37, "Thirty-two enemies and five bosses exist")
	game.start_game(false)
	await frames(45)
	check(game.player.is_on_floor(), "Terrain collision supports player")
	var before = game.player.position
	Input.action_press("move_forward")
	await frames(50)
	Input.action_release("move_forward")
	check(game.player.position.z < before.z - 4, "W movement follows camera")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await frames(6)
	check(not game.player.is_on_floor(), "Jump leaves ground")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	check(game.player.gliding, "Second jump deploys glider")
	await frames(15)
	check(game.player.stamina < 100, "Gliding consumes stamina")
	game.player.position = game.world.npc_position + Vector3(0, 0.5, 3)
	game.player.velocity = Vector3.ZERO
	game.interact()
	check(game.mode == "dialogue", "NPC interaction starts prologue")
	finish_dialogue()
	check(game.quest_stage == 1, "Prologue opens shrine quest")
	game.player.position = game.world.shrines[0]["pos"]
	game.player.set_character(0, false)
	game.interact()
	check(not game.world.shrines[0]["active"], "Living guardians block shrine activation")
	var enemy: HollowEnemy = game.enemies[0]
	game.player.position = enemy.position + Vector3(0, 0, 2)
	game.player.set_character(1, false)
	game.player.cast_skill()
	check(enemy.hp < enemy.max_hp and enemy.element == 1, "Fire skill deals damage and applies element")
	var cooldown = game.player.skill_cooldowns[1]
	var enemy_hp = enemy.hp
	game.player.cast_skill()
	check(enemy.hp == enemy_hp and cooldown > 0, "Skill cooldown prevents repeated casting")
	game.player.hp = 70
	game.player.set_character(2, false)
	game.player.cast_skill()
	check(game.player.hp == 105, "Water skill heals")
	check(game.reactions_triggered > 0, "Fire plus water triggers elemental reaction")
	game.player.set_character(4, false)
	game.player.cast_skill()
	check(game.player.shield >= 65, "Earth skill creates shield")
	var hp_before = game.player.hp
	game.player.invulnerability = 0
	game.player.take_damage(20)
	check(game.player.hp == hp_before and game.player.shield < 65, "Shield absorbs incoming damage")
	game.player.energy = 20
	game.player.cast_burst()
	check(game.player.energy == 20, "Burst requires full energy")
	game.player.energy = 100
	game.player.cast_burst()
	check(game.player.energy == 0 and game.player.burst_cooldown > 0, "Charged burst consumes energy")
	for i in range(5):
		for guard in game.enemies:
			if guard.shrine_index == i and not guard.dead:
				game.player.position = guard.position + Vector3(0, 0, 2)
				game.player.set_character((i + 1) % 5, false)
				var safety = 0
				while not guard.dead and safety < 10:
					game.perform_attack("normal")
					safety += 1
		game.player.position = game.world.shrines[i]["pos"] + Vector3(0, 0, 4)
		game.player.set_character((i + 1) % 5, false)
		game.interact()
		check(not game.world.shrines[i]["active"], "Shrine %d rejects wrong element" % i)
		game.player.set_character(i, false)
		game.interact()
		finish_dialogue()
		check(game.world.shrines[i]["active"], "Shrine %d accepts matching element" % i)
	check(game.quest_stage == 2 and game.active_shrine_count() == 5, "Five shrines unlock final quest")
	game.player.position = game.world.chests[0]["pos"]
	var coins_before = game.coins
	game.interact()
	check(game.opened_chest_count() == 1 and game.coins == coins_before + 30, "Chest grants thirty coins once")
	game.interact()
	check(game.coins == coins_before + 30, "Opened chest cannot be farmed")
	game.player.position = game.world.boss_position + Vector3(0, 0, 10)
	game.interact()
	finish_dialogue()
	check(game.boss_enemy.awakened, "Final dialogue awakens boss")
	game.open_overlay("map")
	check(not game.fast_travel(-1), "Fast travel blocked near active boss")
	game.close_overlay()
	game.player.position = game.boss_enemy.position + Vector3(0, 0, 4)
	game.player.invulnerability = 0
	game.player.shield = 0
	var hp_start = game.player.hp
	game.boss_enemy._start_attack()
	game.boss_enemy._finish_attack()
	check(game.player.hp < hp_start, "Boss telegraphed strike damages player in radius")
	game.player.position = game.boss_enemy.position + Vector3(0, 0, 4)
	game.boss_enemy._start_attack()
	game.player.position += Vector3(14, 0, 0)
	game.player.invulnerability = 0
	hp_start = game.player.hp
	game.boss_enemy._finish_attack()
	check(game.player.hp == hp_start, "Leaving telegraph avoids boss damage")
	game.player.position = game.boss_enemy.position + Vector3(0, 0, 5)
	for i in range(25):
		if game.boss_enemy.dead:
			break
		game.player.set_character(i % 5, false)
		game.perform_attack("skill")
	check(game.boss_enemy.dead and game.quest_stage == 3, "Elemental combat defeats boss and advances quest")
	game.player.position = game.world.npc_position + Vector3(0, 0, 3)
	game.interact()
	finish_dialogue()
	check(game.quest_stage == 4 and game.ui.journal_page == "ending", "Return to NPC completes story and shows ending")
	game.close_overlay()
	var saved_coins = game.coins
	game.save_game()
	game._reset_progress()
	check(game.load_game(), "Save file loads")
	check(game.quest_stage == 4 and game.coins == saved_coins and game.active_shrine_count() == 5 and game.opened_chest_count() == 1, "Save preserves story, currency, shrines and chests")
	check(game.boss_enemy.dead and not game.boss_enemy.visible, "Save preserves defeated boss")
	game.open_overlay("characters")
	check(game.ui.overlay.visible and not game.is_playing(), "Character roster pauses game")
	game.close_overlay()
	game.player.hp = 1
	game.player.invulnerability = 0
	game.player.shield = 0
	game.player.take_damage(80)
	check(game.player.hp == game.player.max_hp and game.player.position.distance_to(game.last_safe_position) < 0.1, "Death recovers at safe checkpoint")
	game.open_overlay("map")
	check(game.fast_travel(-1), "Unlocked village fast travel succeeds out of combat")
	game.return_to_title()
	check(game.mode == "title" and game.ui.menu.visible, "Return to title restores menu")
	await frames(4)
	print("RESULT: ", checks - failures.size(), "/", checks, " checks passed")
	# Remove only the isolated test save created by this test.
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
