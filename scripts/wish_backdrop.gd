class_name WishBackdrop
extends Control

var tint = Color("b6f5de")
var time: float = 0
var stars: Array[Vector3] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var rng = RandomNumberGenerator.new()
	rng.seed = 932
	for i in range(90):
		stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.6, 2.2)))

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var center = Vector2(size.x * 0.76, size.y * 0.51)
	for i in range(6):
		draw_circle(center, 58 + i * 31, Color(tint, 0.014))
	for i in range(3):
		draw_arc(center, 108 + i * 61, time * 0.025 + i, time * 0.025 + i + 4.6, 100, Color(tint, 0.16), 1.0, true)
	for star in stars:
		var p = Vector2(star.x * size.x, star.y * size.y)
		draw_circle(p, star.z, Color(tint, 0.28 + sin(time + star.x * 50) * 0.17))
