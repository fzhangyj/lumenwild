extends SceneTree

var game: LumenGame
var checks = 0
var failures = 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS ",label)
	else:
		failures += 1
		push_error("FAIL " + label)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	game.save_path = "user://lumenwild_growth_test.json"
	root.add_child(game)
	current_scene = game
	game.start_game(false)
	game.audio.muted = true
	game.player.set_physics_process(false)
	game.growth.set_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	await physics_frame
	await process_frame
	var g = game.growth
	check(g.levels.size()==23 and g.books==[0,0,0] and g.levels.count(1)==23,"All 23 characters start at level one with an empty book inventory")
	var coverage: Dictionary = {}
	var positions_valid = true
	for point in g.nodes:
		coverage[point["item"]] = int(coverage.get(point["item"],0))+1
		positions_valid = positions_valid and game.world.solids.clear_at(point["pos"],0.5) and point["pos"].y>=1
	check(coverage.size()==28 and g.nodes.size()==84 and positions_valid,"Every character specialty and element crystal has three dry accessible outdoor nodes")
	var interactions_valid = true
	var physics_clear = true
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.9
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	for i in range(g.nodes.size()):
		game.player.position = g.nodes[i]["pos"]
		game._update_interaction()
		interactions_valid = interactions_valid and game.interaction_kind=="material" and game.interaction_index==i
		query.transform = Transform3D(Basis(),g.nodes[i]["pos"]+Vector3.UP*1.15)
		physics_clear = physics_clear and game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	check(interactions_valid and physics_clear,"All 84 gathering points accept F and are outside building, tree and rock colliders")
	var point: Dictionary = g.nodes[0]
	game.player.position = point["pos"]
	game.interact()
	check(g.materials[0]==2 and not point["root"].visible,"F interaction gathers specialty into inventory and hides node")
	check(not g.gather(0) and g.materials[0]==2,"Collected node cannot pay twice")
	var ready: float = point["ready_at"]
	game.save_game()
	game.load_game()
	check(g.nodes[0]["ready_at"]==ready and not g.nodes[0]["root"].visible,"Gathering cooldown persists after reload")
	game.mode = "overlay"
	var time = game.play_time
	g._process(601)
	check(game.play_time==time and not g.nodes[0]["root"].visible,"Paused menus do not grow materials")
	game.mode = "playing"
	game.play_time = ready+1
	g._process(0.01)
	check(g.nodes[0]["root"].visible and g.gather(0),"Exploration time restores a collected node")
	game.player.position = WildWorld.ground(0,77)
	var enemy = game.enemies[0]
	enemy.position = WildWorld.ground(0,35)
	enemy.damage(10000,-1,false)
	check(g.drops.size()==1 and g.drops[0]["books"][0]==2 and g.drops[0]["shards"]==1,"Monster death creates physical guaranteed books and a common fragment")
	enemy.damage(10000,-1,false)
	check(g.drops.size()==1,"Defeated monster cannot duplicate its drop")
	game.save_game()
	game.load_game()
	check(g.drops.size()==1,"Uncollected drops survive closing and reloading")
	var drop: Dictionary = g.drops[0]
	game.player.position = drop["pos"]
	check(g.collect_drop(drop["id"]) and g.books[0]==2 and g.materials[28]==1,"Nearby drop transfers books and fragments exactly once")
	check(not g.collect_drop(drop["id"]),"Collected drop id is no longer claimable")
	g.spawn_drop(game.boss_enemy)
	check(g.drops[0]["books"]==[0,4,1] and g.drops[0]["shards"]==4,"Boss rewards higher rarity books and extra fragments")
	g.books.assign([10,10,10])
	var old_coins = game.coins
	check(g.use_book(0,0) and g.levels[0]==2 and g.experience[0]==0 and g.books[0]==9,"A book crosses the exact level-two boundary")
	check(game.coins==old_coins and g.levels[1]==1,"Cultivation leaves gold and other characters untouched")
	var before = g.to_dict()
	check(not g.use_book(5,2) and g.books==before["books"],"Unowned limited characters cannot consume experience books")
	check(not g.use_book(-1,0) and not g.use_book(0,3) and not g.use_book(0,0,-1),"Invalid book actions are rejected")
	check(g.use_book(0,2,10) and g.levels[0]==20 and g.books[2]>0,"Bulk use stops at the current ascension cap")
	var carry = g.experience[0]
	check(not g.use_book(0,0) and not g.ascend(0),"Capped characters need sufficient breakthrough materials")
	for item in g.costs(0):
		g.materials[item] = g.costs(0)[item]
	check(g.ascend(0) and g.cap(0)==40 and g.ascensions[0]==1 and g.materials[0]==0,"Breakthrough consumes exact character, element and monster materials")
	check(g.experience[0]==carry or g.levels[0]>20,"Overflow experience is retained or settled after breakthrough")
	check(not g.ascend(0),"Breakthrough cannot be repeated below the next cap")
	for id in range(23):
		check(g.costs(id).has(id) and g.costs(id).has(23+GameData.element_of(id)),"Correct specialty and element requirements for character %d" % id)
	g.books[2] = 100
	for i in range(5):
		g.use_book(0,2,10)
	for item in g.costs(0):
		g.materials[item] = g.costs(0)[item]
	check(g.levels[0]==40 and g.ascend(0) and g.cap(0)==60,"Second breakthrough unlocks level sixty")
	for i in range(10):
		g.use_book(0,2,10)
	var end_books = g.books.duplicate()
	check(g.levels[0]==60 and not g.use_book(0,0) and not g.ascend(0) and g.books==end_books,"Maximum level cannot consume more books or breakthroughs")
	check(g.damage_multiplier(0)>2 and g.damage_taken(0)<0.8,"Levels materially improve damage and protection")
	game.player.set_character(0,false)
	game.player.hp = 180
	game.player.invulnerability = 0
	game.player.shield = 0
	game.player.take_damage(100)
	check(is_equal_approx(game.player.hp,180-100*g.damage_taken(0)),"Damage reduction is applied by the real player damage path")
	game.wishes.owned.append(5)
	g.levels[5] = 10
	var effect = game.arts._effect("moon",5,1,Vector3.ZERO)
	check(is_equal_approx(effect["mult"],1.3*g.damage_multiplier(5)*game.wishes.damage_multiplier(5)),"Limited abilities snapshot their owner's level multiplier")
	game.arts.clear()
	game.save_game()
	var saved_books = g.books.duplicate()
	game.load_game()
	check(g.levels[0]==60 and g.levels[5]==10 and g.books==saved_books,"All character cultivation and inventories persist")
	var valid_path = game.save_path
	game.save_path = "user://missing_growth_folder/save.json"
	var old_state = g.to_dict()
	check(not g.use_book(1,1) and g.to_dict()["books"]==old_state["books"] and g.levels[1]==1,"Save failure refunds books and character experience")
	g.levels[1] = 20
	for item in g.costs(1):
		g.materials[item] = g.costs(1)[item]
	var old_materials = g.materials.duplicate()
	check(not g.ascend(1) and g.ascensions[1]==0 and g.materials==old_materials,"Save failure refunds breakthrough materials")
	game.player.position = g.nodes[2]["pos"]
	var material_before = g.materials.duplicate()
	check(not g.gather(2) and g.materials==material_before and g.nodes[2]["ready_at"]<=game.play_time,"Save failure leaves a gathering point available without awarding materials")
	if not g.drops.is_empty():
		var failed_drop: Dictionary = g.drops[0]
		game.player.position = failed_drop["pos"]
		var count_before = g.drops.size()
		var books_before = g.books.duplicate()
		check(not g.collect_drop(failed_drop["id"]) and g.drops.size()==count_before and g.books==books_before,"Save failure keeps a physical drop and refunds its inventory transfer")
	game.save_path = valid_path
	var file = FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":3,"quest":24,"coins":5310,"wishes":{"owned":[22],"pity":16,"guaranteed":true}}))
	file.close()
	game.load_game()
	check(game.coins==5310 and game.quest_stage==24 and game.wishes.has_character(22) and game.wishes.pity==16 and g.levels.count(1)==23,"Old saves retain story, limited ownership, currency and pity while receiving level-one growth")
	game.open_overlay("growth")
	check(game.mode=="overlay" and game.ui.journal_page=="growth","U opens the cultivation screen and pauses combat")
	g.track(22)
	game._update_waypoint()
	check(not g.target().is_empty() and game.waypoint.visible and game.waypoint.text.contains(g.material_name(22)),"Materials remain trackable after all five chapters end")
	for target_point in g.nodes:
		if target_point["item"]==22:
			target_point["ready_at"] = game.play_time+60
	game._update_waypoint()
	check(game.waypoint.text.contains("秒后再生") and not g.target().is_empty(),"Exhausted material routes show a regrowth countdown instead of losing the destination")
	game._reset_progress()
	check(g.books==[0,0,0] and g.levels.count(1)==23 and g.drops.is_empty(),"New adventure clears cultivation, pickups and inventories")
	print("GROWTH RESULT: ",checks-failures,"/",checks," checks passed")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures==0 else 1)
