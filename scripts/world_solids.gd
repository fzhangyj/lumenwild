class_name WorldSolids
extends Node3D

var obstacles: Array[Dictionary] = []

func tree(base: Vector3, radius: float, height: float) -> void:
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_add(shape, Transform3D(Basis(), base + Vector3.UP * height * 0.5), "tree", Vector2(radius, radius), base.y + height)

func rock(mesh: Mesh, transform: Transform3D) -> void:
	var shape = ConvexPolygonShape3D.new()
	var points = PackedVector3Array()
	for surface in range(mesh.get_surface_count()):
		for vertex in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			points.append(transform.basis * vertex)
	shape.points = points
	var scale = transform.basis.get_scale()
	_add(shape, Transform3D(Basis(), transform.origin), "rock", Vector2(scale.x, scale.z) * 0.5, transform.origin.y + scale.y * 0.5, transform.basis.get_euler().y)

func _add(shape: Shape3D, transform: Transform3D, kind: String, radius: Vector2, top: float, yaw: float = 0) -> void:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.transform = transform
	add_child(body)
	var collider = CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	obstacles.append({"kind": kind, "body": body, "pos": transform.origin, "radius": radius, "top": top, "yaw": yaw})

func clear_at(pos: Vector3, margin: float = 0.5) -> bool:
	for obstacle in obstacles:
		if pos.y > obstacle["top"] + 0.3:
			continue
		var offset = Vector2(pos.x - obstacle["pos"].x, pos.z - obstacle["pos"].z).rotated(obstacle["yaw"])
		var radius: Vector2 = obstacle["radius"] + Vector2.ONE * margin
		if (offset / radius).length_squared() < 1.0:
			return false
	return true

# An old save can place its player or renewed objects inside a newly solid prop.
func resolve(pos: Vector3, margin: float = 0.6) -> Vector3:
	if clear_at(pos, margin):
		return pos
	for step in range(1, 25):
		for direction in range(24):
			var angle = direction * TAU / 24
			var candidate = WildWorld.ground(pos.x + cos(angle) * step * 0.6, pos.z + sin(angle) * step * 0.6, 0.2)
			if candidate.y >= 1.5 and clear_at(candidate, margin):
				return candidate
	return pos
