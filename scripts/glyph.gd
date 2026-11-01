class_name ElementGlyph
extends Control

var element: int = 0
var tint = Color.WHITE

func _draw() -> void:
	var s = minf(size.x, size.y)
	var c = size * 0.5
	var r = s * 0.31
	var width = maxf(1.6, s * 0.035)
	match element:
		0:
			for i in range(3):
				var y = c.y + (i - 1) * r * 0.65
				draw_line(Vector2(c.x - r, y), Vector2(c.x + r * (0.6 if i == 1 else 0.15), y), tint, width, true)
				draw_arc(Vector2(c.x + r * (0.6 if i == 1 else 0.15), y - r * 0.27), r * 0.28, -PI, PI * 0.5, 16, tint, width, true)
		1:
			var points = PackedVector2Array([c + Vector2(0, -r * 1.35), c + Vector2(r * 0.25, -r * 0.15), c + Vector2(r * 0.68, -r * 0.65), c + Vector2(r * 0.92, r * 0.3), c + Vector2(r * 0.4, r), c + Vector2(-r * 0.4, r), c + Vector2(-r * 0.92, r * 0.3), c + Vector2(-r * 0.55, -r * 0.7), c + Vector2(-r * 0.35, 0), c + Vector2(0, -r * 1.35)])
			draw_polyline(points, tint, width, true)
			draw_line(c + Vector2(0, r * 0.8), c, tint, width, true)
		2:
			var points = PackedVector2Array()
			points.append(c + Vector2(0, -r * 1.4))
			for i in range(25):
				var a = -0.4 + float(i) / 24 * (PI + 0.8)
				points.append(c + Vector2(cos(a), sin(a)) * r * 0.8 + Vector2(0, r * 0.2))
			points.append(c + Vector2(0, -r * 1.4))
			draw_polyline(points, tint, width, true)
		3:
			var points = PackedVector2Array([c + Vector2(r * 0.5, -r * 1.35), c + Vector2(-r * 0.85, r * 0.12), c + Vector2(0, r * 0.12), c + Vector2(-r * 0.4, r * 1.35), c + Vector2(r * 0.85, -r * 0.22), c + Vector2(0, -r * 0.22), c + Vector2(r * 0.5, -r * 1.35)])
			draw_colored_polygon(points, tint)
		4:
			var points = PackedVector2Array()
			for i in range(7):
				points.append(c + Vector2(sin(i * TAU / 6), cos(i * TAU / 6)) * r * 1.1)
			draw_polyline(points, tint, width, true)
			draw_line(c + Vector2(-r * 0.8, r * 0.5), c + Vector2(0, -r * 0.6), tint, width, true)
			draw_line(c + Vector2(0, -r * 0.6), c + Vector2(r * 0.8, r * 0.5), tint, width, true)

