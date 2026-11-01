class_name WishSystem
extends RefCounted

const COST = 60
const CHARACTER_RATE = 0.01
const SOFT_PITY = 20
const HARD_PITY = 40
const MAX_RANK = 5
var owned: Array[int] = [0, 1, 2, 3, 4]
var ranks: Dictionary = {}
var pity: int = 0
var guaranteed: bool = false
var total_pulls: int = 0
var since_limited: int = 0
var potions: int = 0
var banner: int = 5
var history: Array = []

func has_character(index: int) -> bool:
	return index in owned

func rank_of(index: int) -> int:
	return int(ranks.get(str(index), 0))

func damage_multiplier(index: int) -> float:
	return 1.0 + rank_of(index) * 0.03

func draw_many(count: int, selected: int, coins: int, rng: RandomNumberGenerator, rotation: int = 0) -> Dictionary:
	if count not in [1, 10] or selected not in GameData.LIMITED_IDS:
		return {"ok": false, "error": "无效的祈愿请求"}
	if rotation < 0 or rotation >= GameData.BANNER_BATCHES.size() or selected not in GameData.BANNER_BATCHES[rotation]:
		return {"ok": false, "error": "该限定不在本期卡池 · 通关主线章节将轮换卡池"}
	if coins < count * COST:
		return {"ok": false, "error": "金币不足 · 单抽需要 60，十连需要 600 金币"}
	var results: Array = []
	banner = selected
	for i in range(count):
		results.append(_draw(selected, rng.randf(), rng.randf(), rng.randi_range(0, 4)))
	return {"ok": true, "spent": count * COST, "results": results}

# Rolls are injected here to make pity boundary tests deterministic.
func _draw(selected: int, chance_roll: float, featured_roll: float, standard_id: int) -> Dictionary:
	pity += 1
	total_pulls += 1
	since_limited += 1
	var forced = pity >= SOFT_PITY
	var result = {"type": "supply", "character": -1, "name": "旅行药剂", "detail": "药剂 ×1 · 按 R 恢复 45 生命", "limited": false, "new": false, "pity": forced, "pull": total_pulls}
	if forced or chance_roll < CHARACTER_RATE:
		var featured = guaranteed or featured_roll < 0.5
		var index = selected if featured else clampi(standard_id, 0, 4)
		result["type"] = "character"
		result["character"] = index
		result["name"] = GameData.character(index)["name"]
		result["limited"] = featured
		result["new"] = not has_character(index)
		result["big_pity"] = guaranteed
		if not has_character(index):
			owned.append(index)
			result["detail"] = "新角色 · 已解锁，可在角色图鉴编入队伍"
		elif rank_of(index) < MAX_RANK:
			ranks[str(index)] = rank_of(index) + 1
			result["detail"] = "共鸣 %d 阶 · 伤害提升 %d%%" % [rank_of(index), rank_of(index) * 3]
		else:
			potions += 2
			result["detail"] = "共鸣已满 · 转为旅行药剂 ×2"
		pity = 0
		guaranteed = not featured
		if featured:
			since_limited = 0
	else:
		potions += 1
	history.push_front(result.duplicate(true))
	if history.size() > 60:
		history.resize(60)
	return result

func to_dict() -> Dictionary:
	return {"owned": owned.duplicate(), "ranks": ranks.duplicate(true), "pity": pity, "guaranteed": guaranteed, "total_pulls": total_pulls, "since_limited": since_limited, "potions": potions, "banner": banner, "history": history.duplicate(true)}

func restore(data: Dictionary) -> void:
	owned = [0, 1, 2, 3, 4]
	for id in data.get("owned", []):
		if int(id) in GameData.LIMITED_IDS and int(id) not in owned:
			owned.append(int(id))
	ranks.clear()
	var stored_ranks = data.get("ranks", {})
	if stored_ranks is Dictionary:
		for id in owned:
			var rank = clampi(int(stored_ranks.get(str(id), 0)), 0, MAX_RANK)
			if rank > 0:
				ranks[str(id)] = rank
	pity = clampi(int(data.get("pity", 0)), 0, SOFT_PITY - 1)
	guaranteed = bool(data.get("guaranteed", false))
	total_pulls = maxi(0, int(data.get("total_pulls", 0)))
	since_limited = clampi(int(data.get("since_limited", 0)), 0, HARD_PITY - 1)
	potions = maxi(0, int(data.get("potions", 0)))
	banner = int(data.get("banner", 5))
	if banner not in GameData.LIMITED_IDS:
		banner = 5
	history = []
	var stored_history = data.get("history", [])
	if stored_history is Array:
		for row in stored_history.slice(0, 60):
			if row is Dictionary and row.has_all(["type", "name", "detail", "limited", "new", "pity", "pull", "character"]):
				var record: Dictionary = row.duplicate(true)
				record["character"] = int(record["character"])
				record["pull"] = int(record["pull"])
				history.append(record)
