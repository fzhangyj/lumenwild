extends SceneTree

var checks = 0
var failures = 0

func check(value: bool, name: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL " + name)
	else:
		print("PASS ", name)

func _initialize() -> void:
	var w = WishSystem.new()
	check(w.owned == [0, 1, 2, 3, 4], "Limited characters are initially locked")
	for i in range(19):
		w._draw(5, 0.99, 0.99, 2)
	check(w.pity == 19 and w.owned.size() == 5 and w.potions == 19, "First nineteen non-rare pulls give supplies")
	var tenth = w._draw(5, 0.99, 0.99, 2)
	check(tenth["character"] == 2 and tenth["pity"] and w.pity == 0 and w.guaranteed, "Twentieth pull gives character and losing enables guarantee")
	check(w.rank_of(2) == 1 and is_equal_approx(w.damage_multiplier(2), 1.03), "Starter duplicate improves resonance")
	for i in range(19):
		w._draw(7, 0.99, 0.99, 0)
	check(not w.has_character(7) and w.pity == 19, "Guarantee carries across banners without early grant")
	var twentieth = w._draw(7, 0.99, 0.99, 0)
	check(twentieth["character"] == 7 and twentieth["big_pity"] and w.has_character(7), "Fortieth pull guarantees current featured character")
	check(w.pity == 0 and not w.guaranteed and w.since_limited == 0, "Featured resets both pity states")
	w = WishSystem.new()
	check(w._draw(6, 0.01, 0.1, 0)["type"] == "supply", "One percent boundary is exclusive")
	var early = w._draw(6, 0.00999, 0.1, 0)
	check(early["new"] and early["character"] == 6 and w.pity == 0, "Natural rare below one percent unlocks featured early")
	w._draw(6, 0.0, 0.99, 1)
	check(w.guaranteed, "Early standard character triggers big pity")
	var restored = WishSystem.new()
	restored.restore(JSON.parse_string(JSON.stringify(w.to_dict())))
	check(restored.to_dict() == w.to_dict(), "Wish state survives JSON save round trip")
	check(restored._draw(5, 0.0, 0.99, 0)["character"] == 5, "Early character while guaranteed must be featured")
	var rng = RandomNumberGenerator.new()
	rng.seed = 937
	var before = restored.to_dict()
	check(not restored.draw_many(10, 5, 599, rng)["ok"] and restored.to_dict() == before, "Insufficient currency leaves all wish state unchanged")
	check(not restored.draw_many(2, 5, 600, rng)["ok"] and restored.to_dict() == before, "Invalid pull count is rejected")
	check(not restored.draw_many(1, 0, 600, rng)["ok"] and restored.to_dict() == before, "Invalid banner is rejected")
	restored.pity = 19
	restored.guaranteed = true
	var ten = restored.draw_many(10, 6, 600, rng)
	check(ten["ok"] and ten["spent"] == 600 and ten["results"].size() == 10, "Ten-pull charges exactly six hundred coins")
	check(ten["results"][0]["character"] == 6, "Ten-pull respects carried pity on its first result")
	var single = restored.draw_many(1, 5, 60, rng)
	check(single["ok"] and single["spent"] == 60, "Single pull costs exactly sixty coins")
	for i in range(8):
		restored._draw(5, 0.0, 0.0, 0)
	check(restored.rank_of(5) == 5, "Duplicate rank caps at five")
	var potions = restored.potions
	restored._draw(5, 0.0, 0.0, 0)
	check(restored.potions == potions + 2, "Full rank duplicate becomes two potions")
	for i in range(70):
		restored._draw(5, 0.99, 0.99, 0)
	check(restored.history.size() == 60, "Recent history is bounded to sixty records")
	var sample = WishSystem.new()
	var max_gap = 0
	for i in range(10000):
		sample.draw_many(1, 5 + (i % 3), 60, rng)
		max_gap = maxi(max_gap, sample.since_limited)
	check(max_gap <= 39, "Ten thousand draws never exceed forty-pull featured limit")
	for rotation in range(GameData.BANNER_BATCHES.size()):
		for id in GameData.BANNER_BATCHES[rotation]:
			var batch = WishSystem.new()
			batch.pity = 19
			batch.guaranteed = true
			var result = batch.draw_many(1, id, 60, rng, rotation)
			check(result["ok"] and result["results"][0]["character"] == id and batch.has_character(id), "Active chapter banner grants its selected limited %d" % id)
	print("WISH RESULT: ", checks - failures, "/", checks, " checks passed")
	quit(0 if failures == 0 else 1)
