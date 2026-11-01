class_name CharacterSculpt
extends RefCounted

static var templates: Dictionary = {}
const HAIR = ["dbe8df", "703836", "a8d9e1", "333c56", "b8a17d", "e7e8f5", "d6a46e", "34344e", "c3e8ee", "46504e", "ba715e", "d9e9f6", "9bafb5", "303952", "ddd39c", "794337", "b68c55", "e2d6b6", "564b53", "416c83", "ece0c5", "52496c", "b0d7cf"]

# Elliptical cross sections sculpt the silhouette; all coordinates are local.
static func loft(parent: Node3D, sections: Array, color: Color, sides: int = 24) -> MeshInstance3D:
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(sections.size() - 1):
		for i in range(sides):
			var a = TAU * i / sides
			var b = TAU * (i + 1) / sides
			var low: Vector4 = sections[row]
			var high: Vector4 = sections[row + 1]
			var p = Vector3(cos(a) * low.y, low.x, sin(a) * low.z + low.w)
			var q = Vector3(cos(b) * low.y, low.x, sin(b) * low.z + low.w)
			var r = Vector3(cos(a) * high.y, high.x, sin(a) * high.z + high.w)
			var s = Vector3(cos(b) * high.y, high.x, sin(b) * high.z + high.w)
			for v in [p, q, r, q, s, r]:
				tool.add_vertex(v)
	# Closed ends prevent visible holes at cuffs, shoulders, boots and necklines.
	for end in [0, sections.size() - 1]:
		var section: Vector4 = sections[end]
		var center = Vector3(0, section.x, section.w)
		for i in range(sides):
			var a = TAU * i / sides
			var b = TAU * (i + 1) / sides
			var p = Vector3(cos(a) * section.y, section.x, sin(a) * section.z + section.w)
			var q = Vector3(cos(b) * section.y, section.x, sin(b) * section.z + section.w)
			for v in ([center, q, p] if end == 0 else [center, p, q]):
				tool.add_vertex(v)
	tool.index()
	tool.generate_normals()
	return Models.mesh_node(parent, tool.commit(), Vector3.ZERO, color)

static func leaf(parent: Node3D, from: Vector3, to: Vector3, width: float, color: Color, depth: float = 0.04) -> Node3D:
	var node = Node3D.new()
	parent.add_child(node)
	node.position = from
	var delta = to - from
	node.quaternion = Quaternion(Vector3.UP, delta.normalized())
	var length = delta.length()
	loft(node, [Vector4(0, width * 0.45, depth, 0), Vector4(length * 0.16, width * 0.84, depth, -width * 0.10), Vector4(length * 0.35, width, depth, -width * 0.18), Vector4(length * 0.62, width * 0.72, depth * 0.8, -width * 0.25), Vector4(length * 0.84, width * 0.32, depth * 0.4, -width * 0.15), Vector4(length, 0.001, 0.001, 0)], color, 12)
	return node

static func cloth(parent: Node3D, color: Color, width: float, length: float, split: bool = false) -> void:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in range(8):
		for x in range(6):
			var points: Array[Vector3] = []
			for v in [Vector2(x, y), Vector2(x + 1, y), Vector2(x, y + 1), Vector2(x + 1, y + 1)]:
				var u = v.x / 6 - 0.5
				var t = v.y / 8
				var hem = absf(u) * 0.24 if split else (0.13 * cos(u * TAU))
				points.append(Vector3(u * width * (0.6 + t * 0.4), -t * (length + hem), 0.04 + t * t * 0.19 + sin(u * PI * 6) * 0.025 * t))
			for i in [0, 1, 2, 1, 3, 2, 2, 1, 0, 2, 3, 1]:
				surface.add_vertex(points[i])
	surface.generate_normals()
	Models.mesh_node(parent, surface.commit(), Vector3.ZERO, color)

static func build(index: int) -> Node3D:
	if templates.has(index):
		return templates[index].instantiate()
	var root = AnimeCast.make(index)
	_owners(root,root)
	var packed = PackedScene.new()
	packed.pack(root)
	templates[index]=packed
	return root
static func _smooth(node: MeshInstance3D) -> void:
	var mesh = SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.set_smooth_group(0)
	for point in node.mesh.get_faces():
		mesh.add_vertex(point)
	mesh.index()
	mesh.generate_normals()
	node.mesh = mesh.commit()

static func _eye_mask(head: Node3D, side: int, scale: float, color: Color, depth: float) -> void:
	var mesh = SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center = Vector3(side * 0.095, 0.017, -0.208 - depth)
	for i in range(32):
		var points: Array[Vector3] = []
		for j in [i, i + 1]:
			var a = TAU * j / 32
			var x = side * 0.095 + cos(a) * 0.072 * scale
			var y = 0.017 + sin(a) * (0.038 if sin(a) > 0 else 0.030) * scale + side * (x - side * 0.095) * 0.15
			points.append(Vector3(x, y, -sqrt(maxf(0.001, 1 - pow(x / 0.245, 2))) * 0.205 - 0.010 - depth))
		for point in [center, points[0], points[1]]:
			mesh.add_vertex(point)
	mesh.generate_normals()
	Models.mesh_node(head, mesh.commit(), Vector3.ZERO, color)

static func _signature(index: int, body: Node3D, head: Node3D, cape: Node3D, color: Color, gold: Color) -> void:
	match index:
		17:
			# A woven leaf mantle and overlapping petal skirt for the forest tailor.
			for side in [-1, 1]:
				for i in range(3):
					leaf(body, Vector3(side * (0.10 + i * 0.055), 1.76, -0.12), Vector3(side * (0.22 + i * 0.07), 1.40 + i * 0.10, -0.22), 0.09, color.darkened(i * 0.12), 0.025)
				for i in range(3):
					leaf(body, Vector3(side * (0.03 + i * 0.065), 1.21, -0.18), Vector3(side * (0.04 + i * 0.10), 0.65 + i * 0.07, -0.27), 0.095, color.darkened(0.20 + i * 0.08), 0.022)
				for i in range(3):
					leaf(head, Vector3(side * (0.07 + i * 0.06), 0.18, -0.20 + i * 0.025), Vector3(side * (0.12 + i * 0.065), 0.27, -0.19 + i * 0.025), 0.029, color, 0.008)
		18:
			# Heavy engraved armor, a split leather apron and a tool pouch.
			for side in [-1, 1]:
				leaf(body, Vector3(side * 0.17, 1.24, -0.18), Vector3(side * 0.27, 0.55, -0.29), 0.155, Color("a98161"), 0.04)
				for i in range(3):
					leaf(body, Vector3(side * 0.27, 1.73 - i * 0.10, -0.16), Vector3(side * 0.07, 1.57 - i * 0.10, -0.24), 0.021, gold, 0.011)
			Models.box(body, Vector3(0.30, 1.02, 0.02), Vector3(0.20, 0.25, 0.18), Color("694d42"))
			Models.box(body, Vector3(0.30, 1.09, -0.08), Vector3(0.13, 0.07, 0.024), gold)
			Models.ring(head, Vector3(-0.24, -0.13, 0), 0.065, gold, 0.012).rotation.x = PI * 0.5
		19:
			# Layered tide-blue robes, strings and pearl clasps echo a travelling harp.
			for side in [-1, 1]:
				leaf(body, Vector3(side * 0.13, 1.24, -0.19), Vector3(side * 0.30, 0.38, -0.27), 0.155, Color("87b7c6"), 0.025)
				leaf(body, Vector3(side * 0.16, 1.22, -0.22), Vector3(side * 0.25, 0.44, -0.30), 0.012, gold, 0.008)
				for i in range(4):
					Models.sphere(body, Vector3(side * (0.07 + i * 0.047), 1.69 - i * 0.035, -0.165), Vector3.ONE * 0.029, Color("ede5d0"))
			leaf(cape, Vector3(-0.14, 0.01, 0.04), Vector3(-0.44, -1.17, 0.32), 0.14, Color("507f9a"), 0.018)
		20:
			# A sunrise crown and red-gold ceremonial sash.
			Models.ring(head, Vector3(0, 0.20, 0.12), 0.31, gold, 0.019).rotation.x = PI * 0.5
			for i in range(7):
				var a = PI * i / 6
				leaf(head, Vector3(cos(a) * 0.29, 0.20 + sin(a) * 0.29, 0.12), Vector3(cos(a) * 0.38, 0.20 + sin(a) * 0.38, 0.12), 0.023, gold, 0.009)
			for side in [-1, 1]:
				leaf(body, Vector3(side * 0.16, 1.24, -0.17), Vector3(side * 0.31, 0.47, -0.27), 0.15, Color("b96d54"), 0.025)
				leaf(body, Vector3(side * 0.15, 1.23, -0.20), Vector3(side * 0.32, 0.49, -0.30), 0.018, gold, 0.008)
		21:
			# Asymmetric ivory stole with tuning pins and a suspended star earring.
			leaf(body, Vector3(-0.22, 1.76, -0.13), Vector3(-0.25, 0.72, -0.29), 0.11, Color("d6cedc"), 0.022)
			for i in range(4):
				Models.cylinder(body, Vector3(-0.24, 1.13 + i * 0.10, -0.31), 0.012, 0.11, gold).rotation.z = PI * 0.5
			Models.crystal(head, Vector3(-0.245, -0.20, 0), 0.115, color)
			leaf(head, Vector3(-0.245, -0.02, 0), Vector3(-0.245, -0.15, 0), 0.008, gold, 0.005)
		22:
			# A cartographer's cross-body satchel, rolled map and long scarf tails.
			leaf(body, Vector3(-0.22, 1.76, -0.15), Vector3(0.27, 1.09, -0.24), 0.035, Color("b28d65"), 0.014)
			Models.box(body, Vector3(0.31, 1.04, -0.035), Vector3(0.25, 0.29, 0.20), Color("9b7959"))
			Models.box(body, Vector3(0.31, 1.14, -0.146), Vector3(0.22, 0.09, 0.025), Color("d4ba87"))
			Models.sphere(body, Vector3(0.31, 1.10, -0.165), Vector3.ONE * 0.036, gold)
			Models.cylinder(body, Vector3(-0.29, 1.0, 0.05), 0.058, 0.40, Color("ede5d0"), -1, 12)
			Models.cylinder(body, Vector3(-0.29, 1.0, 0.05), 0.062, 0.035, gold, -1, 12)
			for side in [-1, 1]:
				leaf(cape, Vector3(side * 0.12, 0.04, 0.06), Vector3(side * 0.53, -0.89, 0.37), 0.08, color, 0.016)

static func _hair(head: Node3D, index: int, color: Color) -> void:
	# Rounded, curved locks follow the scalp before tapering into separate tips.
	loft(head, [Vector4(0.13, 0.243, 0.212, 0.04), Vector4(0.22, 0.23, 0.205, 0.04), Vector4(0.30, 0.18, 0.16, 0.04), Vector4(0.35, 0.10, 0.10, 0.04), Vector4(0.37, 0.001, 0.001, 0.04)], color, 32)
	for i in range(13):
		var a = PI * i / 12
		var extent = 0.27 + (0.20 if index % 3 == 2 else 0.0) + sin(i * 2.7) * 0.035
		_lock(head, Vector3(cos(a) * 0.13, 0.29, sin(a) * 0.12 + 0.04), Vector3(cos(a) * 0.29, 0.13, sin(a) * 0.25 + 0.05), Vector3(cos(a) * 0.26, -extent * 0.7, sin(a) * 0.24 + 0.06), Vector3(cos(a) * 0.28, -extent, sin(a) * 0.19 + 0.08), 0.055, 0.036, color.darkened((i % 3) * 0.035))
	for i in range(9):
		var x = -0.205 + i * 0.050
		var sweep = 0.04 if index % 2 == 0 else -0.025
		var tip = 0.105 + sin(i * 0.63 + index * 0.4) * 0.065
		_lock(head, Vector3(x * 0.48 - sweep, 0.32, -0.06), Vector3(x * 0.80 - sweep, 0.27, -0.21), Vector3(x + sweep, 0.17, -0.237), Vector3(x + sweep * 1.4, tip, -0.220), 0.034 + (i % 3) * 0.006, 0.010, color.lightened((i % 3) * 0.023))
	for side in [-1, 1]:
		_lock(head, Vector3(side * 0.20, 0.25, -0.08), Vector3(side * 0.28, 0.09, -0.13), Vector3(side * 0.24, -0.17, -0.14), Vector3(side * 0.20, -0.29, -0.11), 0.044, 0.025, color)
	if index % 3 == 1:
		for i in range(4):
			_lock(head, Vector3(0.02, 0.20, 0.22), Vector3(0.17, 0.01, 0.40), Vector3(-0.08, -0.39, 0.34), Vector3(0.12 + i * 0.024, -0.75 + i * 0.04, 0.24), 0.06, 0.036, color.darkened(i * 0.035))
		Models.ring(head, Vector3(0.04, 0.12, 0.25), 0.088, Color("d1b783"), 0.016)
	elif index % 3 == 2:
		for side in [-1, 1]:
			for strand in range(4):
				_lock(head, Vector3(side * 0.22, 0.10, 0.05 + strand * 0.03), Vector3(side * 0.27, -0.20, 0.08), Vector3(side * 0.22, -0.49, 0.13), Vector3(side * (0.29 + strand * 0.02), -0.68 + strand * 0.025, 0.05), 0.041, 0.026, color.lightened(strand * 0.023))

static func _lock(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, width: float, depth: float, color: Color) -> void:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	for row in range(13):
		var t = row / 12.0
		var center = a.bezier_interpolate(b, c, d, t)
		var tangent = a.bezier_derivative(b, c, d, t).normalized()
		var across = tangent.cross(Vector3.FORWARD).normalized()
		if across.length_squared() < 0.01:
			across = Vector3.RIGHT
		var normal = across.cross(tangent).normalized()
		var taper = maxf(0.015, pow(1.0 - t, 0.50)) * (0.62 + sin(t * PI) * 0.58)
		for i in range(12):
			var angle = i * TAU / 12
			points.append(center + across * cos(angle) * width * taper + normal * sin(angle) * depth * taper)
	for row in range(12):
		for i in range(12):
			var p = row * 12 + i
			var q = row * 12 + (i + 1) % 12
			for id in [p, q, p + 12, q, q + 12, p + 12]:
				surface.add_vertex(points[id])
	surface.index()
	surface.generate_normals()
	Models.mesh_node(parent, surface.commit(), Vector3.ZERO, color)

static func _tailoring(body: Node3D, cape: Node3D, index: int, color: Color, gold: Color) -> void:
	# Small stitched borders, inset cloth folds and hanging metal fasteners.
	for side in [-1, 1]:
		for i in range(9):
			var y = 1.31 + i * 0.037
			var x = side * (0.085 + i * 0.013)
			leaf(body, Vector3(x - 0.007, y, -0.178), Vector3(x + 0.007, y + 0.009, -0.178), 0.004, gold, 0.003)
		for i in range(3):
			var x = side * (0.12 + i * 0.041)
			leaf(body, Vector3(x, 1.17, -0.191), Vector3(x * 1.32, 0.92 - i * 0.028, -0.237), 0.010, color.darkened(0.3), 0.006)
		Models.ring(body, Vector3(side * 0.25, 1.19, -0.12), 0.040, gold, 0.008).rotation.x = PI * 0.5
		leaf(body, Vector3(side * 0.25, 1.15, -0.12), Vector3(side * 0.28, 1.02, -0.16), 0.009, gold, 0.006)
		Models.sphere(body, Vector3(side * 0.28, 1.01, -0.16), Vector3(0.030, 0.043, 0.030), color)
		for i in range(5):
			var y = -0.21 - i * 0.085
			leaf(cape, Vector3(side * 0.13, y, 0.07 + y * y * 0.2), Vector3(side * 0.22, y - 0.055, 0.09 + y * y * 0.2), 0.007, gold.darkened(0.12), 0.004)
	if index % 2 == 0:
		leaf(body, Vector3(-0.20, 1.68, -0.15), Vector3(0.15, 1.26, -0.20), 0.025, Color("c4ae83"), 0.012)

static func _couture(body: Node3D, root: Node3D, element: int, index: int, color: Color, dark: Color, ivory: Color, gold: Color) -> void:
	# Thin, folded cloth panels establish silhouettes independently of the armor.
	for side in [-1,1]:
		var length = [0.76,0.61,0.85,0.79,0.51][element]
		var width = [0.15,0.14,0.21,0.14,0.18][element]
		if index>=17:
			length += 0.05
		var begin = Vector3(side*0.20,1.22,0.10)
		var end = Vector3(side*0.38,1.22-length,0.21)
		_drape(body,begin,end,0.075,width,color.darkened(0.16),gold)
		if element==2:
			_drape(body,Vector3(side*0.12,1.20,-0.21),Vector3(side*0.18,0.37,-0.29),0.11,0.15,ivory.darkened(0.035),gold)
			var sleeve = root.get_node("ArmL" if side<0 else "ArmR")
			_drape(sleeve,Vector3(side*0.06,-0.19,0.02),Vector3(side*0.13,-0.52,0.04),0.07,0.14,color.darkened(0.12),gold)
		elif element==0:
			_drape(body,Vector3(side*0.12,1.20,-0.21),Vector3(side*0.25,0.76,-0.28),0.06,0.09,ivory,gold)
		elif element==3:
			_drape(body,Vector3(side*0.12,1.21,-0.20),Vector3(side*0.22,0.58,-0.27),0.065,0.10,dark.lightened(0.24),gold)
		for i in range(4):
			var y = 1.05-i*0.085
			leaf(body,Vector3(side*0.27,y,0.06),Vector3(side*0.34,y-0.045,0.12),0.011,gold,0.007)
	if element==1:
		_drape(body,Vector3(-0.22,1.73,-0.14),Vector3(0.18,1.28,-0.22),0.075,0.10,ivory,gold)
	elif element==4:
		for i in range(3):
			leaf(body,Vector3(-0.16,1.60-i*0.075,-0.203),Vector3(0.16,1.60-i*0.075,-0.203),0.011,gold,0.007)

static func _drape(parent: Node3D, top: Vector3, bottom: Vector3, top_width: float, bottom_width: float, color: Color, trim: Color) -> void:
	var mesh = SurfaceTool.new()
	var border = SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	border.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(16):
		for column in range(12):
			var points: Array[Vector3] = []
			for uv in [Vector2(column,row),Vector2(column+1,row),Vector2(column,row+1),Vector2(column+1,row+1)]:
				var u = uv.x/12.0*2-1
				var t = uv.y/16.0
				var width = lerpf(top_width,bottom_width,t)
				var center = top.lerp(bottom,t)
				points.append(center + Vector3(u*width,-t*t*0.028*cos(u*PI),sin(u*PI*2)*0.005*t - 0.032*sin(t*PI)))
			for id in [0,2,1,1,2,3]:
				mesh.add_vertex(points[id])
			# A thin hem follows the actual edge, independent of tessellation size.
			if column==0 or column==11:
				var outer0 = points[0] if column==0 else points[1]
				var outer1 = points[2] if column==0 else points[3]
				var inward = Vector3(0.007 if column==0 else -0.007,0,0)
				for point in [outer0,outer1,outer0+inward,outer0+inward,outer1,outer1+inward]:
					border.add_vertex(point+Vector3(0,0,-0.003))
			if row==15:
				for point in [points[2],points[3],points[2]+Vector3(0,0.008,0),points[3],points[3]+Vector3(0,0.008,0),points[2]+Vector3(0,0.008,0)]:
					border.add_vertex(point+Vector3(0,0,-0.003))
	mesh.index()
	mesh.generate_normals()
	border.index()
	border.generate_normals()
	for pair in [[mesh,color],[border,trim]]:
		var part = Models.mesh_node(parent,pair[0].commit(),Vector3.ZERO,pair[1])
		var mat = part.material_override.duplicate() as StandardMaterial3D
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		part.material_override = mat

static func _proportions(root: Node3D) -> void:
	# Keep the named limb pivots used by gameplay animation and packed instances.
	for limb in root.get_children():
		if limb.name == "Head":
			limb.position.y = 2.315
			limb.scale = Vector3(0.80, 0.74, 0.82)
		else:
			limb.position *= Vector3(0.84, 1.13, 0.88)
			limb.scale = Vector3(0.84, 1.13, 0.88)

static func _weapon(arm: Node3D, element: int, index: int, color: Color, dark: Color, gold: Color) -> void:
	var weapon = _group(arm, "Weapon", Vector3(0, -0.64, -0.045))
	if element in [0, 1]:
		leaf(weapon, Vector3(0, 0.04, -0.10), Vector3(0, 0.0, -1.01 if element == 0 else -1.2), 0.095, Color("dce6e6"), 0.022)
		leaf(weapon, Vector3(0, 0.02, -0.19), Vector3(0, 0.025, -0.91), 0.022, color, 0.01)
		leaf(weapon, Vector3(-0.18, 0, -0.13), Vector3(0.18, 0, -0.13), 0.047, gold)
		Models.cylinder(weapon, Vector3(0, 0, 0.03), 0.032, 0.27, dark).rotation.x = PI * 0.5
		Models.crystal(weapon, Vector3(0, 0, 0.19), 0.095, color)
	elif element == 2:
		Models.cylinder(weapon, Vector3(0, 0.19, 0), 0.028, 1.45, dark, -1, 12)
		Models.ring(weapon, Vector3(0, 1.02, 0), 0.21, gold, 0.022).rotation.x = PI * 0.5
		Models.sphere(weapon, Vector3(0, 1.02, 0), Vector3.ONE * 0.24, color, 0.5)
		for side in [-1, 1]:
			leaf(weapon, Vector3(side * 0.10, 0.76, 0), Vector3(side * 0.24, 1.22, 0), 0.037, ivory_color())
		if index == 19:
			for x in [-0.12, 0, 0.12]:
				Models.cylinder(weapon, Vector3(x, 1.02, -0.03), 0.007, 0.35, gold, -1, 6)
	elif element == 3:
		Models.cylinder(weapon, Vector3(0, 0.36, 0), 0.025, 1.8, dark, -1, 12)
		leaf(weapon, Vector3(0, 1.14, 0), Vector3(0, 1.67, 0), 0.08, Color("e0dcec"), 0.025)
		for side in [-1, 1]:
			leaf(weapon, Vector3(0, 1.12, 0), Vector3(side * 0.18, 1.34, 0), 0.04, gold)
		Models.crystal(weapon, Vector3(0, 1.14, -0.04), 0.13, color)
		if index == 21:
			for side in [-1, 1]:
				leaf(weapon, Vector3(side * 0.10, 1.16, 0), Vector3(side * 0.15, 1.64, 0), 0.03, gold, 0.015)
	else:
		Models.cylinder(weapon, Vector3(0, 0, -0.33), 0.039, 0.86, dark).rotation.x = PI * 0.5
		loft(weapon, [Vector4(-0.15, 0.23, 0.15, -0.74), Vector4(-0.10, 0.29, 0.19, -0.74), Vector4(0.13, 0.29, 0.19, -0.74), Vector4(0.19, 0.23, 0.15, -0.74)], color.darkened(0.13), 8)
		Models.crystal(weapon, Vector3(0, 0.03, -0.94), 0.17, color)
		for x in [-0.21, 0.21]:
			Models.box(weapon, Vector3(x, 0.02, -0.74), Vector3(0.038, 0.31, 0.34), gold)
	if index >= 5:
		leaf(weapon, Vector3(0.04, 0.02, 0.06), Vector3(0.12, -0.32, 0.14), 0.018, color, 0.008)

static func ivory_color() -> Color:
	return Color("ece6d1")

static func _group(parent: Node3D, label: String, position: Vector3) -> Node3D:
	var group = Node3D.new()
	group.name = label
	group.position = position
	parent.add_child(group)
	return group

# Bake static ornament meshes by material within each animated limb.
static func _bake(group: Node3D) -> void:
	var surfaces: Dictionary = {}
	_gather(group, Transform3D.IDENTITY, surfaces)
	for child in group.get_children():
		child.free()
	for material in surfaces:
		var mesh = MeshInstance3D.new()
		surfaces[material].index()
		mesh.mesh = surfaces[material].commit()
		mesh.material_override = material
		group.add_child(mesh)

static func _gather(node: Node3D, transform: Transform3D, surfaces: Dictionary) -> void:
	if node is MeshInstance3D:
		var material: Material = node.material_override
		if not surfaces.has(material):
			var surface = SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfaces[material] = surface
		for i in range(node.mesh.get_surface_count()):
			# Primitive meshes use indices; lofts do not. Normalize before merging
			# so an indexed ornament cannot leave the sculpted body unreferenced.
			var source = SurfaceTool.new()
			source.create_from(node.mesh, i)
			source.deindex()
			surfaces[material].append_from(source.commit(), 0, transform)
	for child in node.get_children():
		if child is Node3D:
			_gather(child, transform * child.transform, surfaces)

static func _owners(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_owners(child, root)
