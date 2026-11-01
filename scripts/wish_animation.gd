class_name WishAnimation
extends Control

signal finished
var elapsed = 0.0
var duration = 3.8
var tier = 0
var pull_count = 1
var done = false
var stars: Array[Vector3] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng = RandomNumberGenerator.new()
	rng.seed = 8341
	for i in range(140):
		stars.append(Vector3(rng.randf_range(0, 1440), rng.randf_range(0, 900), rng.randf_range(0.6, 2)))

func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		skip()

func skip() -> void:
	if done:
		return
	done = true
	finished.emit()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), Color("061322"))
	var center = Vector2(720, 425)
	var reveal = smoothstep(0.9, 1.8, elapsed)
	var rarity = Color("ffd998") if tier == 2 else (Color("c3a0ff") if tier == 1 else Color("92dfff"))
	var color = Color("90caff").lerp(rarity, reveal)
	for i in range(12, 0, -1):
		draw_circle(center, i * 38.0, Color(color, 0.006 + reveal * 0.002))
	for i in range(stars.size()):
		var star = stars[i]
		var pos = Vector2(star.x, star.y)
		var alpha = 0.18 + (sin(elapsed * 1.7 + i) + 1) * 0.18
		draw_circle(pos, star.z, Color("dcefff") * Color(1, 1, 1, alpha))
	var travel = smoothstep(0, 2.25, elapsed)
	var head = Vector2(1070, 70).lerp(center, travel)
	var direction = Vector2(0.7, -0.71)
	for n in range(pull_count):
		var offset = Vector2((n % 3 - 1) * 44, (n / 3) * 26) * (1 - travel)
		var point = head + offset
		for segment in range(22):
			var ratio = segment / 22.0
			var a = point + direction * segment * 13
			var b = a + direction * 15
			draw_line(a, b, Color(color, (1 - ratio) * 0.56 * (1 - smoothstep(2.3, 2.9, elapsed))), (1 - ratio) * 6 + 1, true)
		_star(point, 9 if n == 0 else 4, Color(color, 1 - smoothstep(2.5, 3.1, elapsed)), elapsed)
	if elapsed > 1.45:
		var portal = smoothstep(1.45, 2.8, elapsed)
		for ring in range(3):
			var radius = (118 + ring * 39) * portal
			draw_arc(center, radius, elapsed * (0.25 if ring % 2 == 0 else -0.2), TAU + elapsed * (0.25 if ring % 2 == 0 else -0.2), 96, Color(color, portal * (0.6 - ring * 0.16)), 1.5, true)
		for i in range(8):
			var angle = i * TAU / 8 + elapsed * 0.16
			var point = center + Vector2(cos(angle), sin(angle)) * 158 * portal
			_star(point, 6 * portal, Color(color, portal * 0.85), angle)
			var next = center + Vector2(cos(angle + TAU * 3 / 8), sin(angle + TAU * 3 / 8)) * 158 * portal
			draw_line(point, next, Color(color, portal * 0.14), 1, true)
		_star(center, 36 * portal, Color("fff7de"), 0)
	if elapsed > 2.5:
		var bloom = smoothstep(2.5, 3.65, elapsed)
		for i in range(32):
			var angle = i * TAU / 32 + i * 0.37
			var outward = Vector2(cos(angle), sin(angle))
			var radius = 120 + bloom * (310 + (i % 5) * 50)
			draw_line(center + outward * radius, center + outward * (radius + 24), Color(color, (1 - bloom) * 0.7), 2, true)
		_star(center, 36 + bloom * 86, Color(color, 1 - bloom * 0.7), 0)
		draw_circle(center, bloom * 620, Color(color, sin(bloom * PI) * 0.045))

func _star(center: Vector2, radius: float, color: Color, angle: float) -> void:
	var points = PackedVector2Array()
	for i in range(8):
		var a = angle + i * TAU / 8
		points.append(center + Vector2(cos(a), sin(a)) * radius * (1.0 if i % 2 == 0 else 0.2))
	draw_colored_polygon(points, color)
