class_name LumenAtlas
extends Control

var game: Node3D
var full_map: bool = false
var font: Font

func _ready() -> void:
	font = load("res://assets/ui_font.tres")
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func map_position(p: Vector3) -> Vector2:
	var scale_factor = minf(size.x, size.y) / 345.0
	return size * 0.5 + Vector2(p.x, p.z) * scale_factor

func _draw() -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):
		return
	if is_instance_valid(game.sea) and game.sea.active:
		_draw_sea()
		return
	var center = size * 0.5
	var radius = minf(size.x, size.y) * 0.49
	draw_circle(center, radius, Color("284f56"))
	for ring in range(3):
		draw_arc(center, radius * (0.78 + ring * 0.1), 0, TAU, 80, Color(0.56, 0.72, 0.69, 0.12), 1, true)
	var outline = PackedVector2Array()
	for i in range(81):
		var a = i * TAU / 80
		var irregular = 1.0 + sin(a * 7) * 0.025 + cos(a * 11) * 0.025
		outline.append(map_position(Vector3(sin(a) * 142 * irregular, 0, cos(a) * 133 * irregular)))
	draw_colored_polygon(outline, Color("778c69"))
	draw_polyline(outline, Color("c0c6a0"), 2 if full_map else 1, true)
	# Contours make the map readable even at a glance.
	for level in range(3):
		var contour = PackedVector2Array()
		for i in range(51):
			var a = i * TAU / 50
			contour.append(map_position(Vector3(sin(a) * (96 - level * 18) + sin(a * 4) * 8, 0, cos(a) * (110 - level * 16) - 8)))
		draw_polyline(contour, Color(0.86, 0.87, 0.66, 0.16), 1, true)
	var path = PackedVector2Array([map_position(Vector3(0, 0, 79)), map_position(Vector3(0, 0, 35)), map_position(Vector3(8, 0, -25)), map_position(Vector3(0, 0, -106))])
	draw_polyline(path, Color("c8c49d"), 2 if full_map else 1, true)
	for i in range(5):
		var shrine: Dictionary = game.world.shrines[i]
		var p = map_position(shrine["pos"])
		var start = map_position(Vector3(0, 0, 35) if i < 2 else Vector3(8, 0, -25))
		draw_line(start, p, Color(0.83, 0.82, 0.66, 0.6), 1, true)
		var color = GameData.element_color(i)
		draw_circle(p, 9 if full_map else 3.8, color)
		if shrine["active"]:
			draw_arc(p, 13 if full_map else 6.5, 0, TAU, 20, Color("fff1cb"), 1.5, true)
		if full_map:
			draw_string(font, p + Vector2(17, 6), GameData.SHRINES[i]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("fff2d4"))
	var village = map_position(game.world.npc_position)
	draw_rect(Rect2(village - Vector2(4, 4), Vector2(8, 8)), Color("f2deae"))
	var boss_point = map_position(game.world.boss_position)
	draw_circle(boss_point, 9 if full_map else 4, Color("dec5a0"))
	if full_map:
		draw_string(font, village + Vector2(14, 6), "风铃村", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff2d4"))
		draw_string(font, boss_point + Vector2(15, -2), "星陨观测庭", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff2d4"))
		for chest in game.world.chests:
			if not chest["opened"]:
				var p = map_position(chest["pos"])
				draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), Color("eaca88"), false, 1.4)
		for enemy in game.enemies.slice(0, WorldRenewal.ENEMY_SLOTS):
			if not enemy.dead:
				var p = map_position(enemy.position)
				draw_circle(p, 2.8, Color("ef987e"))
	var pp = map_position(game.player.global_position)
	if is_instance_valid(game.growth):
		for point in game.growth.nodes:
			if point["ready_at"] > game.play_time:
				if point["item"] == game.growth.tracked_material:
					draw_arc(map_position(point["pos"]),4.2 if full_map else 2.5,0,TAU,16,Color("718f96"),1.0,true)
				continue
			if game.growth.tracked_material >= 0 and point["item"] != game.growth.tracked_material:
				continue
			if full_map or game.growth.tracked_material >= 0:
				var p = map_position(point["pos"])
				draw_circle(p,4.2 if game.growth.tracked_material >= 0 else 1.8,Color("aee6e0"))
		for drop in game.growth.drops:
			if full_map or game.player.position.distance_to(drop["pos"]) < 30:
				var p = map_position(drop["pos"])
				draw_rect(Rect2(p-Vector2(2,3),Vector2(4,6)),Color("c6a6ed"))
	if is_instance_valid(game.campaign) and game.quest_stage >= 4 and game.quest_stage < GameData.LAST_QUEST:
		for point in game.campaign.points:
			if point["data"]["stage"] == game.quest_stage and point["id"] not in game.campaign.completed:
				var cp = map_position(point["pos"])
				draw_circle(cp, 6 if full_map else 3, Color("a5f7ee"))
		var goal: Dictionary = game.campaign.current_target()
		var gp = map_position(goal["pos"])
		draw_arc(gp, 13 if full_map else 6, 0, TAU, 24, Color("fff3b5"), 2, true)
	var direction = Vector2(-sin(game.player.yaw), -cos(game.player.yaw))
	var side = direction.orthogonal()
	draw_circle(pp, 12 if full_map else 8, Color(1, 1, 1, 0.13))
	draw_colored_polygon(PackedVector2Array([pp + direction * 10, pp - direction * 6 + side * 5, pp - direction * 3, pp - direction * 6 - side * 5]), Color("fff5d6"))
	draw_arc(center, radius, 0, TAU, 96, Color("d6c9a1"), 1.5, true)
	draw_string(font, Vector2(center.x - 5, 15), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f2e4bc"))

func _draw_sea() -> void:
	var scale_factor=minf(size.x,size.y)/126.0
	var center=size*0.5
	draw_circle(center,minf(size.x,size.y)*0.49,Color("124153"))
	for i in range(4): draw_arc(center,(i+1)*size.x*0.11,0,TAU,64,Color("366778"),1,true)
	for i in range(game.sea.sites.size()):
		var q: Vector3=game.sea.sites[i]-DeepSea.CENTER
		var pos=center+Vector2(q.x,q.z)*scale_factor
		draw_circle(pos,6 if full_map else 3,Color("d0dac1"))
		if full_map: draw_string(font,pos+Vector2(9,5),["邮局","档案馆 ↑","海钟","风钟 ↑","星钟","钟庭"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e1e6cd"))
	var entrance=DeepSea.ENTRY-DeepSea.CENTER
	var exit_pos=center+Vector2(entrance.x,entrance.z)*scale_factor
	draw_circle(exit_pos,6,Color("8debe5"))
	if full_map: draw_string(font,exit_pos+Vector2(10,5),"返回海面",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e1e6cd"))
	var p: Vector3=game.player.position-DeepSea.CENTER
	draw_circle(center+Vector2(p.x,p.z)*scale_factor,5,Color.WHITE)
