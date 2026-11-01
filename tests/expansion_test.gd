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

func dialogue_done() -> void:
	for i in range(10):
		if game.mode == "dialogue":
			game.advance_dialogue()

func npc() -> void:
	game.close_overlay()
	game.player.position = game.world.npc_position + Vector3(0, 0, 3)
	game.interact()
	dialogue_done()

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_expansion_test.json"
	root.add_child(game)
	current_scene = game
	game.audio.muted = true
	game.start_game(false)
	game.player.set_character(5, false)
	check(game.player.character_index == 0 and not game.equip_character(5), "Locked character cannot be selected or equipped")
	check(not game.campaign.bosses[7].visible and not game.campaign.bosses[12].visible, "Later bosses stay hidden at new game")
	game.coins = 600
	game.wishes.pity = WishSystem.SOFT_PITY - 1
	game.wishes.guaranteed = true
	game.open_overlay("wish")
	var result = game.perform_wish(10)
	check(result["ok"] and game.coins == 0 and game.wishes.has_character(5), "Wish UI transaction charges coins and unlocks limited")
	game.finish_wish_animation()
	check(game.ui.journal_page == "wish_results", "Wish transaction displays result screen")
	check(not game.perform_wish(10)["ok"] and game.wishes.total_pulls == 10, "Repeated press on old draw screen cannot draw again")
	check(game.equip_character(5) and game.party[0] == 5 and game.player.character_index == 5, "Owned limited replaces only matching elemental party slot")
	game.save_game()
	game._reset_progress()
	game.load_game()
	check(game.coins == 0 and game.party[0] == 5 and game.wishes.total_pulls == 10 and game.player.character_index == 5, "Save restores coins, banner results, character and party")
	game.coins = 60
	game.open_overlay("wish")
	var snapshot = game.wishes.to_dict()
	var path = game.save_path
	game.save_path = "user://directory_that_does_not_exist/wish.json"
	check(not game.perform_wish(1)["ok"] and game.coins == 60 and game.wishes.to_dict() == snapshot, "Save failure rolls back pull and coin charge")
	game.save_path = path
	game.close_overlay()
	game.wishes.potions = 2
	game.player.hp = 100
	game.use_potion()
	check(game.player.hp == 145 and game.wishes.potions == 1, "Potion heals forty-five and consumes one")
	game.player.hp = game.player.max_hp
	game.use_potion()
	check(game.wishes.potions == 1, "Full health does not consume potion")
	game.quest_stage = 1
	for enemy in game.enemies:
		if enemy.shrine_index == 0:
			enemy.damage(10000, -1, false)
	game.player.position = game.world.shrines[0]["pos"]
	game.player.set_character(5, false)
	game.interact()
	dialogue_done()
	check(game.world.shrines[0]["active"], "Limited wind character activates wind shrine")
	# Version-one fixture uses the separate test save, never the player's save.
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "quest": 4, "coins": 90, "opened": [0, 1, 2], "active": [0, 1, 2, 3, 4], "defeated": [14]}))
	file.close()
	check(game.load_game() and game.coins == 90 and game.wishes.owned.size() == 5, "Old save preserves balance and has no free limited")
	game.load_game()
	check(game.coins == 90, "Reload never awards old chest compensation")
	game.campaign.interact_point(0)
	check(game.campaign.completed.is_empty(), "Future chapter objective cannot be completed early")
	npc()
	check(game.quest_stage == 5, "Chapter two starts at NPC after first ending")
	for chapter in [2, 3]:
		var clue_stage = 5 if chapter == 2 else 10
		for stage in [clue_stage, clue_stage + 1]:
			for i in range(game.campaign.points.size()):
				var point: Dictionary = game.campaign.points[i]
				if point["data"]["stage"] != stage:
					continue
				game.player.position = point["pos"]
				var guard = point["guard"]
				if is_instance_valid(guard):
					game.interact()
					check(point["id"] not in game.campaign.completed, "Clue requires defeating its guard " + point["id"])
					guard.damage(10000, 1)
				else:
					var element: int = point["data"]["element"]
					game.player.set_character((element + 1) % 5, false)
					game.interact()
					check(point["id"] not in game.campaign.completed, "Beacon rejects wrong element " + point["id"])
					game.player.set_character(element, false)
				game.interact()
				dialogue_done()
				check(point["id"] in game.campaign.completed, "Objective completes " + point["id"])
				var coins = game.coins
				game.campaign.interact_point(i)
				check(game.coins == coins, "Objective reward cannot repeat " + point["id"])
			check(game.quest_stage == stage + 1, "Three objectives advance stage " + str(stage))
			game.save_game()
			game.load_game()
			check(game.campaign.stage_progress(stage) == 3, "Completed clues or beacons survive reload " + str(stage))
		var boss: HollowEnemy = game.campaign.bosses[clue_stage + 2]
		game.player.position = boss.home + Vector3(0, 0, 10)
		game.interact()
		dialogue_done()
		check(boss.awakened and game.active_boss() == boss, "Chapter boss awakens and drives HUD " + str(chapter))
		game.player.position = boss.position + Vector3(0, 0, 5)
		for attack in range(50):
			if boss.dead:
				break
			game.player.set_character(attack % 5, false)
			game.perform_attack("skill")
		check(boss.dead and game.quest_stage == clue_stage + 3, "Elemental combat completes chapter boss " + str(chapter))
		var coins = game.coins
		npc()
		check(game.quest_stage == clue_stage + 4 and game.coins == coins + (600 if chapter == 2 else 800), "Chapter ending pays correct coins " + str(chapter))
		check(game.ui.journal_page == "ending", "Chapter ending screen appears " + str(chapter))
		game.save_game()
		game.load_game()
		check(game.quest_stage == clue_stage + 4, "Ending survives reload " + str(chapter))
		coins = game.coins
		npc()
		check(game.coins == coins, "Ending reward is not repeated " + str(chapter))
	check(game.quest_stage == 15 and game.campaign.completed.size() == 12, "Three completed chapters open the fourth chapter")
	game.open_overlay("wish")
	game.ui.show_characters(true)
	game.ui.show_wish_rules()
	game.ui.show_wish_history()
	for i in range(3):
		await process_frame
	print("EXPANSION RESULT: ", checks - failures, "/", checks, " checks passed")
	DirAccess.remove_absolute(path)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
