extends SceneTree

var game: LumenGame
var checks=0
var failures=0
func _initialize() -> void: run.call_deferred()
func check(condition: bool,label: String) -> void:
	checks+=1
	if not condition: failures+=1; push_error("FAIL "+label)
	else: print("PASS "+label)
func dialogue() -> void:
	var count=0
	while game.mode=="dialogue" and count<20:
		game.advance_dialogue()
		count+=1
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	game.test_mode=true
	game.save_path="user://lumenwild_deepsea_test.json"
	root.add_child(game)
	current_scene=game
	game.audio.muted=true
	game.start_game(false)
	game.player.set_physics_process(false)
	for e in game.enemies: e.set_physics_process(false)
	check(game.enemies.size()==37,"Original enemy/save slot indices preserved")
	game.sea.enter()
	check(not game.sea.active,"Portal locked before chapter two completion")
	game.quest_stage=24
	game.campaign.talk_to_npc(); dialogue()
	check(game.quest_stage==25,"Existing finished save continues into sixth chapter")
	game.sea.enter()
	check(game.sea.active and game.quest_stage==26,"Portal loads underwater world and advances arrival")
	check(game.sea.contains(game.player.position),"Underwater arrival inside valid swim volume")
	check(game.world.environment.environment==game.sea.sea_env,"Underwater lighting applied")
	var coast=game.last_safe_position
	game.player.position=game.sea.sites[0]
	game._update_interaction()
	check(game.interaction_kind=="sea","Physical proximity resolves underwater story interaction")
	game.interact(); dialogue()
	check(game.quest_stage==27,"Postal recording reveals singer past")
	game.player.position=game.sea.sites[1]
	game.interact(); dialogue()
	check(game.quest_stage==28,"Archive reveals command and bell clue")
	game.sea.interact(2)
	check(game.sea.bell_count==0,"Wrong bell resets without soft lock")
	for i in [3,2,4]: game.sea.interact(i)
	dialogue()
	check(game.quest_stage==29 and game.sea.bell_count==3,"Three-dimensional melody puzzle advances in correct order")
	game.player.position=DeepSea.ENTRY
	game.sea._process(1)
	check(game.sea.escort==0,"Escort waits when swimmer is far away")
	for i in range(34):
		game.player.position=game.sea.ray.global_position
		game.sea._process(1)
	dialogue()
	check(game.quest_stage==30,"Following ray completes escort")
	game.player.invulnerability=0
	game.player.position=game.sea.locks[0].global_position+Vector3.UP*30
	game.player.invulnerability=0
	var life=game.player.hp
	game.sea.hazard_clock=3.9
	game.sea._process(0.2)
	check(game.player.hp==life,"Swimming above the pulse avoids damage")
	game.player.position=game.sea.locks[0].global_position
	game.sea.hazard_clock=3.9
	game.sea._process(0.2)
	check(game.player.hp<life,"Remaining in pulse plane causes damage")
	for i in range(3):
		game.player.position=game.sea.locks[i].global_position
		game.sea.sonar()
	dialogue()
	check(game.quest_stage==31 and game.sea.rescued.size()==3,"Sonar unseals three locks without combat dependency")
	game.sea.interact(5); dialogue()
	check(game.mode=="overlay" and game.ui.journal_page=="sea_choice","Final scene opens player choice")
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Final choice releases the mouse for clickable answers")
	game.sea.choose("将歌声寄向海面"); dialogue()
	check(game.quest_stage==32 and game.sea.choice!="","Player choice persists and story asks to return")
	var coins=game.coins
	game.sea.interact(100)
	game.sea.interact(100)
	check(game.coins==coins+30 and game.growth.books[1]==1,"Treasure awards thirty coins and one book once")
	game.player.position=DeepSea.CENTER+Vector3(15,22,20)
	var position=game.player.position
	check(game.save_game(),"Underwater save writes successfully")
	game.sea.leave()
	check(not game.sea.active and game.player.position.x<0,"Return portal restores island position")
	check(game.player.camera.environment==null,"Return restores normal camera environment")
	game.load_game()
	# leave() also saves, so explicitly create a new underwater roundtrip snapshot.
	game.sea.enter(); game.player.position=position; game.save_game()
	game._reset_progress(); game.load_game()
	check(game.sea.active and game.player.position.distance_to(position)<0.3,"Reload restores negative underwater height and distant x coordinate")
	check(game.sea.opened==[0] and game.sea.choice=="将歌声寄向海面","Underwater treasure and narrative choice restored")
	check(game.quest_stage==32,"Reload preserves sixth chapter stage")
	game.recover_player("test")
	check(game.sea.active and game.player.position==DeepSea.ENTRY,"Underwater defeat returns to underwater entrance")
	game.sea.leave()
	game.campaign.talk_to_npc(); dialogue()
	check(game.quest_stage==33,"Return conversation advances epilogue")
	coins=game.coins
	game.campaign.talk_to_npc(); dialogue(); game.sea.finish()
	check(game.quest_stage==34 and game.coins==coins+900,"Chapter reward is granted exactly once")
	check(game.growth.books[2]==3,"Chapter completion grants three high-tier books")
	game.sea.enter()
	check(game.sea.active,"Underwater exploration remains available after ending")
	check(game.fast_travel(-1) and not game.sea.active,"Map travel exits swimming mode")
	# Old save conversion and interrupted puzzle recovery.
	var file=FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":4,"quest":24,"coins":558,"character":0,"position":[0,8,77]})); file.close()
	game.load_game()
	check(game.quest_stage==24 and game.coins==558 and not game.sea.active,"Version four save retains progress and currency")
	game.quest_stage=28; game.sea.restore({"bells":3})
	check(game.quest_stage==29,"Interrupted final bell dialogue recovers safely")
	game.quest_stage=30; game.sea.restore({"rescued":[0,1,2]})
	check(game.quest_stage==31,"Interrupted lock dialogue recovers safely")
	game.sea.enter()
	game.sea.restore({"active":true,"opened":[0,1,2,3,4,5,6,7,8,9]})
	game.mode="playing"; game.sea._process(0.1)
	check(game.sea.opened.is_empty() and game.sea.chest_round==2,"Eighty percent cleared renews underwater chests")
	game.sea.leave()
	game.open_overlay("gallery")
	check(game.ui.journal_page=="gallery" and game.wishes.owned.size()==5,"Gallery previews never grant limited ownership")
	# Exercise actual swim motion through the physics server.
	game.close_overlay(); game.sea.enter()
	game.player.position=DeepSea.CENTER+Vector3(40,20,35)
	game.player.set_physics_process(true)
	var before=game.player.position.y
	Input.action_press("jump")
	for i in range(15): await physics_frame
	Input.action_release("jump")
	check(game.player.position.y>before+0.3,"Space physically swims upward")
	Input.action_press("dive_down")
	for i in range(75): await physics_frame
	Input.action_release("dive_down")
	check(game.player.position.y<before,"Ctrl physically dives downward")
	game.player.set_physics_process(false)
	game.sea.leave()
	game.test_mode=false
	game.begin_dialogue([["澜音","按一次显示全文，再按一次继续。"]])
	game.advance_dialogue()
	check(game.mode=="dialogue" and game.ui.dialogue_text.visible_ratio==1,"First dialogue advance reveals text")
	game.advance_dialogue()
	check(game.mode=="playing","Second dialogue advance closes line")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	print("DEEPSEA RESULT: ",checks-failures,"/",checks)
	quit(1 if failures else 0)

