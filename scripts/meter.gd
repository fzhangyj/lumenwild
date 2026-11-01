class_name LumenMeter
extends Control

var value: float = 100.0:
	set(next):
		value = clampf(next, 0, 100)
		queue_redraw()
var tint: Color = Color.WHITE

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.10, 0.12, 0.8))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * value / 100, size.y)), tint)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.94, 0.88, 0.72, 0.4), false, 1.0)
