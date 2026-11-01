extends SceneTree

var game: LumenGame
var checks = 0
var failures = 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, name: String) -> void:
	checks += 1
	if value:
		print("PASS ", name)
	else:
		failures += 1
		push_error("FAIL " + name)

func settle() -> void:
	await process_frame
	await physics_frame
	await process_frame

func collect(index: int) -> void:
	game.player.position = game.world.chests[index]["pos"] + Vector3.UP * 0.2
	game.interact()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_renewal_test.json"
	root.add_child(game)
	current_scene = game
	game.audio.muted = true
	game.start_game(false)
	game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	await settle()
	for i in range(14):
		collect(i)
	await settle()
	check(game.coins == 420 and game.opened_chest_count() == 14, "Fourteen chests each award exactly thirty coins")
	check(game.renewal.chest_wave == 1, "Below eighty percent does not replenish chests")
	var remaining: Array = []
	for i in range(15, 18):
		remaining.append(game.world.chests[i]["pos"])
	collect(14)
	check(game.renewal.chest_wave == 1, "Replenishment is deferred until interaction finishes")
	await settle()
	check(game.renewal.chest_wave == 2 and game.opened_chest_count() == 0, "Fifteenth chest replenishes all fifteen cleared slots")
	check(game.world.chests.size() == 18 and game.coins == 450 and game.renewal.collected_total == 15, "Renewal neither adds rewards nor accumulates nodes")
	var preserved = true
	var safe = true
	for i in range(18):
		var chest: Dictionary = game.world.chests[i]
		if i >= 15:
			preserved = preserved and chest["pos"] == remaining[i - 15] and not chest["opened"]
		else:
			safe = safe and game.renewal._safe_ground(chest["pos"]) and chest["pos"].distance_to(game.player.position) >= 22
			safe = safe and chest["lid"].rotation == Vector3.ZERO and chest["lid"].position.z == 0
	check(preserved, "Three unopened chests retain positions and availability")
	check(safe, "New chests use dry clear ground away from the player with closed lids")
	for i in range(15):
		collect(i)
	await settle()
	check(game.renewal.chest_wave == 3 and game.renewal.collected_total == 30 and game.coins == 900, "Second wave can also replenish and preserve lifetime totals")
	var alive_home = game.enemies[13].home
	game.arts._mark(game.enemies[0])
	for i in range(11):
		game.enemies[i].damage(10000, -1, false)
	await settle()
	check(game.renewal.enemy_wave == 1 and game.renewal.dead_count() == 11, "Eleven of fourteen ordinary enemies do not trigger renewal")
	game.enemies[11].damage(10000, -1, false)
	check(game.enemies[11].dead and not game.enemies[11].visible, "Death callback finishes before respawn")
	await settle()
	check(game.renewal.enemy_wave == 2 and game.renewal.dead_count() == 0, "Twelfth defeated ordinary enemy renews twelve slots")
	check(game.enemies.size() == 37 and game.enemies[13].home == alive_home, "Enemy node count stays bounded and survivors keep homes")
	var reset_ok = true
	for i in range(12):
		var enemy: HollowEnemy = game.enemies[i]
		reset_ok = reset_ok and enemy.visible and enemy.awakened and enemy.collision_layer == 4 and enemy.hp == enemy.max_hp and enemy.shrine_index == -1
		reset_ok = reset_ok and enemy.position.distance_to(game.player.position) >= 22 and enemy.burn_time == 0 and enemy.element == -1
	check(reset_ok, "Respawn restores combat, collisions and roaming assignment away from player")
	check(game.shrine_guard_count(0) == 0 and not game.arts.marks.has(game.enemies[0].get_instance_id()), "Renewed shrine guards no longer block shrines or retain old marks")
	check(not game.enemies[15].visible and not game.boss_enemy.awakened and not game.campaign.bosses[7].visible, "Later story guards and bosses are excluded from renewal")
	var snapshot = game.renewal.to_dict()
	game.save_game()
	game._reset_progress()
	check(game.renewal.chest_wave == 1 and game.renewal.enemy_wave == 1 and game.renewal.collected_total == 0 and game.enemies[0].shrine_index == 0, "New game resets waves, original positions and shrine assignments")
	game.load_game()
	await settle()
	check(game.renewal.to_dict() == snapshot, "Save restores both wave positions, assignments and lifetime count")
	for i in range(12):
		game.enemies[i].damage(10000, -1, false)
	await settle()
	check(game.renewal.enemy_wave == 3, "Second ordinary-enemy wave renews repeatedly")
	await settle()
	check(game.renewal.enemy_wave == 3 and game.renewal.chest_wave == 3, "Idle frames cannot repeatedly renew completed waves")
	for version in [1, 2]:
		var file = FileAccess.open(game.save_path, FileAccess.WRITE)
		file.store_string(JSON.stringify({"version": version, "quest": 4, "coins": 1234, "opened": range(15), "defeated": range(12)}))
		file.close()
		game.load_game()
		await settle()
		check(game.coins == 1234 and game.renewal.chest_wave == 2 and game.renewal.enemy_wave == 2, "Old save keeps balance and renews exhausted map, version %d" % version)
		game.load_game()
		await settle()
		check(game.coins == 1234 and game.renewal.chest_wave == 2, "Migrated save reload cannot repeat rewards or renewal, version %d" % version)
	game._reset_progress()
	game.mode = "playing"
	game.coins = 600
	game.open_overlay("wish")
	game.wishes.pity = 19
	game.wishes.guaranteed = true
	var outcome = game.perform_wish(1)
	check(outcome["ok"] and game.ui.journal_page == "wish_animation" and game.wish_busy, "Successful pull starts cinematic and locks transaction")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(saved["coins"] == 540 and 5.0 in saved["wishes"]["owned"] and saved["wishes"]["total_pulls"] == 1, "Coins and earned character are saved before cinematic completes")
	check(not game.perform_wish(1)["ok"] and game.coins == 540, "Second press during animation cannot charge twice")
	game.close_overlay()
	check(not game.wish_busy and game.ui.journal_page == "wish_results", "Escape skips animation to earned results")
	game.finish_wish_animation()
	check(game.coins == 540 and game.wishes.total_pulls == 1, "Repeated completion is harmless")
	game.open_overlay("wish")
	game.perform_wish(1)
	for child in game.ui.overlay.get_children():
		if child is WishAnimation and not child.is_queued_for_deletion():
			child._process(4)
	check(not game.wish_busy and game.ui.journal_page == "wish_results", "Cinematic completes automatically")
	game.open_overlay("wish")
	game.perform_wish(1)
	game.load_game()
	check(game.coins == 420 and game.wishes.total_pulls == 3 and game.wishes.has_character(5), "Reload during animation retains all earned rewards")
	game.wishes.pity = 17
	game.wishes.guaranteed = true
	var previous = 5
	for stage in [4, 9, 14]:
		game.campaign._set_stage(stage)
		var rotation = GameData.rotation_for_quest(stage)
		check(game.wishes.banner == GameData.BANNER_BATCHES[rotation][0] and game.wishes.pity == 17 and game.wishes.guaranteed, "Chapter rotates banner without resetting pity %d" % rotation)
		game.open_overlay("wish")
		game.wishes.banner = previous
		var before_coins = game.coins
		check(not game.perform_wish(1)["ok"] and game.coins == before_coins, "Retired banner is rejected before coin charge %d" % rotation)
		game.sync_wish_banner()
		check(game.equip_character(5) and game.party[0] == 5, "Owned retired character remains equipable %d" % rotation)
		previous = game.wishes.banner
	game.save_game()
	game.load_game()
	check(game.wishes.banner == 14 and game.wishes.pity == 17 and game.wishes.guaranteed, "Final batch and shared pity survive reload")
	for id in GameData.LIMITED_IDS:
		if not game.wishes.has_character(id):
			game.wishes.owned.append(id)
	for id in range(GameData.CHARACTER_COUNT):
		game.player.set_character(id, false)
		check(game.player.character_index == id and game.player.avatar != null and game.player.skill_cooldowns.size() == GameData.CHARACTER_COUNT, "Character model and cooldown slot %d" % id)
	game.arts.set_process(false)
	for enemy in game.enemies:
		enemy.awakened = false
	var target: HollowEnemy = game.enemies[10]
	for id in GameData.LIMITED_IDS:
		for burst in [false, true]:
			game.close_overlay()
			game.arts.clear()
			game.player.position = WildWorld.ground(8, 35, 0.2)
			game.player.hp = 80
			game.player.shield = 0
			game.player.energy = 100
			game.player.burst_cooldown = 0
			game.player.skill_cooldowns.fill(0)
			game.player.set_character(id, false)
			target.awakened = true
			target.dead = false
			target.hp = 10000
			target.element = -1
			target.position = game.player.position + Vector3(0, 0, -3)
			if burst:
				game.player.cast_burst()
			else:
				game.player.cast_skill()
			var started = game.arts.active.size() == 1
			for frame in range(220):
				game.arts._process(0.05)
			check(started and target.hp < 10000 and game.arts.active.is_empty(), "Limited skill deals damage and cleans up %d/%s" % [id, "Q" if burst else "E"])
			if id in [8, 11]:
				var healing = 40 if burst else (36 if id == 11 else 24)
				check(game.player.hp == 80 + healing, "Tide healing matches described pulses %d/%s" % [id, burst])
			if id in [9, 15] and not burst:
				check(game.player.shield == 55, "Stone skill grants shield %d" % id)
	game.ui.show_characters(true, 0)
	game.ui.show_characters(true, 5)
	game.ui.show_arts(22)
	game.equip_character(22)
	game.save_game()
	game.load_game()
	check(game.player.character_index == 22 and game.party[0] == 22 and game.wishes.has_character(22), "Newest limited ownership and equipped character survive reload")
	await settle()
	print("RENEWAL RESULT: ", checks - failures, "/", checks, " checks passed")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
