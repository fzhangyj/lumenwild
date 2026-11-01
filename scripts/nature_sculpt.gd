class_name NatureSculpt
extends RefCounted

static func canopy() -> ArrayMesh:
	var source = SphereMesh.new()
	source.radial_segments = 32
	source.rings = 18
	source.radius = 0.5
	source.height = 1
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in source.get_faces():
		var n = point.normalized()
		var ripple = sin(n.x * 17 + n.y * 11) * sin(n.z * 19 - n.y * 9) * 0.05
		var lobes = sin(n.x * 7 + n.z * 5) * sin(n.y * 8 - n.z * 4) * 0.07
		surface.add_vertex(point * (1.0 + ripple + lobes))
	surface.index()
	surface.generate_normals()
	return surface.commit()

static func foliage(color: Color) -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/foliage.gdshader")
	mat.set_shader_parameter("base_color", color)
	return mat

static func mountain(seed_value: int) -> ArrayMesh:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for row in range(33):
		var z = row / 16.0 - 1.0
		for i in range(33):
			var x = i / 16.0 - 1.0
			var shift = sin(seed_value * 1.7) * 0.14
			var peak_a = exp(-((x + 0.28) * (x + 0.28) * 8 + (z - shift) * (z - shift) * 11)) * 0.79
			var peak_b = exp(-((x - 0.30) * (x - 0.30) * 13 + (z + 0.12) * (z + 0.12) * 8)) * 0.68
			var peak_c = exp(-((x - 0.07) * (x - 0.07) * 15 + (z - 0.42) * (z - 0.42) * 18)) * 0.45
			var ridge = sin(x * 19 + z * 9 + seed_value) * sin(z * 17 - x * 5) * 0.035
			var h = (peak_a + peak_b + peak_c + ridge) * (1.0 - smoothstep(0.72, 1.08, Vector2(x, z).length()))
			points.append(Vector3(x, h - 0.5, z))
	for row in range(32):
		for i in range(32):
			var p = row * 33 + i
			var q = p + 1
			for id in [p, q, p + 33, q, q + 33, p + 33]:
				surface.add_vertex(points[id])
	surface.index()
	surface.generate_normals()
	return surface.commit()
