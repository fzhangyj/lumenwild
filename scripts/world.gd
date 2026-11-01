class_name WildWorld
extends Node3D

var shrines: Array = []
var chests: Array = []
var windmills: Array[Node3D] = []
var birds: Array[Node3D] = []
var rng = RandomNumberGenerator.new()
var npc_position: Vector3
var boss_position: Vector3
var spawn_position: Vector3
var time: float = 0.0
var environment: WorldEnvironment
var beacon: MeshInstance3D
var solids: WorldSolids

static func height_at(x: float, z: float) -> float:
	var h = _base_height(x, z)
	var summit_distance = Vector2(x, z + 106.0).length()
	h = lerpf(h, 14.0, 1.0 - smoothstep(18.0, 35.0, summit_distance))
	for data in GameData.SHRINES:
		var center: Vector2 = data["xz"]
		var distance = center.distance_to(Vector2(x, z))
		if distance < 9.0:
			h = lerpf(h, _base_height(center.x, center.y), 1.0 - smoothstep(4.8, 9.0, distance))
	var lake_distance = Vector2(x + 91.0, z + 27.0).length()
	h = lerpf(h, -2.4, 1.0 - smoothstep(9.0, 17.0, lake_distance))
	return h

static func _base_height(x: float, z: float) -> float:
	var radius = Vector2(x * 0.92, z).length()
	var hills = 2.4 + sin(x * 0.034) * cos(z * 0.027) * 2.8 + sin(z * 0.042 + x * 0.014) * 1.6
	var summit = 12.0 * exp(-Vector2(x, z + 106.0).length_squared() / 1700.0)
	return maxf(1.5, hills + summit) - smoothstep(122.0, 177.0, radius) * 22.0

static func ground(x: float, z: float, offset: float = 0.0) -> Vector3:
	return Vector3(x, height_at(x, z) + offset, z)

func _ready() -> void:
	rng.seed = 81924
	solids = WorldSolids.new()
	add_child(solids)
	_build_light()
	_build_terrain()
	_build_ocean()
	_build_paths()
	_build_village()
	_build_shrines()
	_build_observatory()
	_build_nature()
	_build_chests()
	_build_scenery()
	spawn_position = ground(0, 77, 0.2)
	npc_position = ground(-3, 63)
	boss_position = ground(0, -106, 0.2)
	var npc = Models.character(2)
	add_child(npc)
	npc.position = npc_position
	npc.rotation.y = PI
	npc.scale = Vector3.ONE * 1.12
	_label(npc, "阿芙", Vector3(0, 2.75, 0), Color("fff1cf"), 32)
	_label(npc, "守灯人", Vector3(0, 2.42, 0), Color("c6e5dc"), 21)
	for i in range(9):
		var bird = Node3D.new()
		add_child(bird)
		Models.box(bird, Vector3(-0.4, 0.08, 0), Vector3(0.8, 0.05, 0.2), Color("edf4df")).rotation.z = -0.25
		Models.box(bird, Vector3(0.4, 0.08, 0), Vector3(0.8, 0.05, 0.2), Color("edf4df")).rotation.z = 0.25
		birds.append(bird)

func _process(delta: float) -> void:
	time += delta
	for mill in windmills:
		mill.rotation.z += delta * 0.25
	for i in range(shrines.size()):
		var shrine: Dictionary = shrines[i]
		shrine["crystal"].rotation.y += delta * 0.55
		shrine["crystal"].position.y = 2.7 + sin(time * 1.5 + i) * 0.18
		shrine["halo"].rotation.z += delta * 0.15
	for i in range(birds.size()):
		var a = time * 0.065 + i * 0.8
		birds[i].position = Vector3(cos(a) * (60.0 + i * 3), 26.0 + sin(a * 3.0) * 2.0 + i, sin(a) * 50.0)
		birds[i].rotation.y = -a

func _build_light() -> void:
	environment = WorldEnvironment.new()
	var env = Environment.new()
	var sky = Sky.new()
	var sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/painted_sky.gdshader")
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b6c9ec")
	env.ambient_light_energy = 0.48
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("a3bed4")
	env.fog_density = 0.0019
	env.fog_sky_affect = 0.08
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff3dc")
	sun.light_energy = 0.88
	sun.shadow_enabled = true
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.0
	sun.directional_shadow_max_distance = 140
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _build_terrain() -> void:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step = 3.5
	for xi in range(-51, 51):
		for zi in range(-51, 51):
			var x = xi * step
			var z = zi * step
			var points = [ground(x, z), ground(x + step, z), ground(x, z + step), ground(x + step, z + step)]
			var color = Color("5d814e")
			var h = height_at(x, z)
			if h < 0.8:
				color = Color("c5b786")
			elif z < -55:
				color = Color("677b73")
			elif x > 33 and z > -8:
				color = Color("89894f")
			color = color.lightened(rng.randf_range(-0.035, 0.04))
			for idx in [0, 1, 2, 1, 3, 2]:
				surface.set_color(color)
				var p: Vector3 = points[idx]
				surface.set_normal(Vector3(height_at(p.x - 0.2, p.z) - height_at(p.x + 0.2, p.z), 0.4, height_at(p.x, p.z - 0.2) - height_at(p.x, p.z + 0.2)).normalized())
				surface.add_vertex(points[idx])
	var terrain = MeshInstance3D.new()
	terrain.mesh = surface.commit()
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/landscape.gdshader")
	terrain.material_override = mat
	add_child(terrain)
	terrain.create_trimesh_collision()

func _build_ocean() -> void:
	var plane = PlaneMesh.new()
	plane.size = Vector2(2200, 2200)
	plane.subdivide_depth = 80
	plane.subdivide_width = 80
	var ocean = MeshInstance3D.new()
	ocean.mesh = plane
	ocean.position.y = -1.4
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader")
	ocean.material_override = mat
	add_child(ocean)

func _path(from: Vector2, to: Vector2, width: float) -> void:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count = int(from.distance_to(to) / 2) + 1
	var perpendicular = (to - from).normalized().orthogonal() * width * 0.5
	for i in range(count):
		var a = from.lerp(to, float(i) / count)
		var b = from.lerp(to, float(i + 1) / count)
		var corners = [a + perpendicular, a - perpendicular, b + perpendicular, b - perpendicular]
		for idx in [0, 2, 1, 2, 3, 1]:
			var p: Vector2 = corners[idx]
			surface.set_color(Color("a39b79").darkened(rng.randf_range(0.0, 0.025)))
			surface.set_uv(Vector2(idx % 2, (i + (1 if idx >= 2 else 0)) * 2.0))
			surface.add_vertex(ground(p.x, p.y, 0.075))
	surface.generate_normals()
	var mesh = MeshInstance3D.new()
	mesh.mesh = surface.commit()
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/path.gdshader")
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func _build_paths() -> void:
	_path(Vector2(0, 88), Vector2(0, 35), 4.5)
	_path(Vector2(0, 35), Vector2(8, -25), 4.2)
	_path(Vector2(8, -25), Vector2(0, -105), 4.0)
	for data in GameData.SHRINES:
		var end: Vector2 = data["xz"]
		var start = Vector2(0, 35) if end.y > 0 else Vector2(8, -25)
		_path(start, end, 3.0)

func _build_village() -> void:
	var stone = Color("c2bc9c")
	var roofs = [Color("406c69"), Color("537e73"), Color("ae6b4e")]
	var points = [Vector2(-15, 73), Vector2(14, 73), Vector2(-16, 56), Vector2(18, 53), Vector2(28, 66), Vector2(-27, 65)]
	for i in range(points.size()):
		var p: Vector2 = points[i]
		var root = Node3D.new()
		add_child(root)
		root.position = ground(p.x, p.y)
		root.rotation.y = -0.18 if i % 2 == 0 else 0.18
		var w = 5.8 if i < 4 else 4.4
		Models.box(root, Vector3(0, 0.25, 0), Vector3(w + 0.5, 0.7, 5.6), stone)
		Models.box(root, Vector3(0, 2.3, 0), Vector3(w, 4.0, 5), Color("e5d9b2"))
		for side in [-1, 1]:
			Models.box(root, Vector3(side * w * 0.49, 2.3, 2.52), Vector3(0.18, 4.2, 0.18), Color("70624e"))
			var roof = Models.box(root, Vector3(side * w * 0.27, 5.0, 0), Vector3(w * 0.67, 0.28, 6.1), roofs[i % 3])
			roof.rotation.z = side * -0.53
			Models.box(root, Vector3(side * 1.65, 2.6, 2.54), Vector3(1.05, 1.25, 0.08), Color("4c7272"))
			Models.box(root, Vector3(side * 1.65, 2.6, 2.61), Vector3(0.09, 1.4, 0.07), Color("dfc799"))
			Models.box(root, Vector3(side * 1.65, 2.6, 2.61), Vector3(1.2, 0.09, 0.07), Color("dfc799"))
		Models.box(root, Vector3(0, 1.42, 2.54), Vector3(1.28, 2.4, 0.15), Color("71614c"))
		Models.box(root, Vector3(0, 4.25, 2.55), Vector3(w, 0.16, 0.18), Color("70624e"))
		Models.box(root, Vector3(-1.5, 5.2, -1.2), Vector3(0.8, 2.5, 0.8), stone)
		_collider(root, Vector3(0, 2.5, 0), Vector3(w, 5, 5))
		var detail = Node3D.new()
		root.add_child(detail)
		for side in [-1, 1]:
			for row in range(7):
				var tile = Models.box(detail, Vector3(side * (0.16 + row * w * 0.075), 5.81 - row * w * 0.044, 0), Vector3(0.055, 0.075, 6.15), roofs[i % 3].lightened(0.14))
				tile.rotation.z = side * -0.53
			for z in range(8):
				var seam = Models.box(detail, Vector3(side * w * 0.27, 5.08, -2.72 + z * 0.78), Vector3(w * 0.67, 0.04, 0.045), roofs[i % 3].darkened(0.15))
				seam.rotation.z = side * -0.53
			Models.box(detail, Vector3(side * 1.65, 1.79, 2.74), Vector3(1.36, 0.27, 0.49), Color("877052"))
			for flower in range(5):
				var stem = Vector3(side * 1.65 - 0.43 + flower * 0.21, 2.04, 2.74)
				Models.sphere(detail, stem, Vector3(0.29, 0.29, 0.29), Color("748c5c"))
				Models.sphere(detail, stem + Vector3.UP * 0.15, Vector3.ONE * 0.12, Color("ebc9a9") if i % 2 == 0 else Color("c5c8e2"))
			for shutter in [-1, 1]:
				Models.box(detail, Vector3(side * 1.65 + shutter * 0.7, 2.6, 2.59), Vector3(0.25, 1.36, 0.11), roofs[i % 3])
		Models.cylinder(detail, Vector3(0.43, 1.35, 2.68), 0.045, 0.13, Color("d1b783")).rotation.x = PI * 0.5
		for step in range(2):
			Models.box(detail, Vector3(0, 0.15 + step * 0.12, 3.2 - step * 0.28), Vector3(1.75, 0.22, 0.48), stone.lightened(0.05))
		for brick in range(6):
			Models.box(detail, Vector3(-w * 0.44 + brick * w * 0.175, 0.4, 2.81), Vector3(w * 0.16, 0.29, 0.13), stone.darkened(0.10 if brick % 2 == 0 else 0.03))
		CharacterSculpt._bake(detail)
	# Village gateway, cloth banners and hanging lanterns.
	var gate = Node3D.new()
	add_child(gate)
	gate.position = ground(0, 48)
	for side in [-1, 1]:
		Models.box(gate, Vector3(side * 4.4, 3.6, 0), Vector3(0.6, 7.2, 0.7), Color("a0a38b"))
		Models.box(gate, Vector3(side * 4.4, 0.5, 0), Vector3(1.1, 1, 1.2), stone)
		Models.box(gate, Vector3(side * 3.2, 5.0, 0), Vector3(1.1, 2.3, 0.06), Color("467e74"))
		Models.crystal(gate, Vector3(side * 3.2, 4.0, 0), 0.18, Color("e9d695"))
	Models.box(gate, Vector3(0, 7, 0), Vector3(10.7, 0.38, 1.1), Color("667666"))
	_label(gate, "风 铃 村", Vector3(0, 6.4, 0.6), Color("f5e7c0"), 42)
	# Market canopy and supplies.
	var market = Node3D.new()
	add_child(market)
	market.position = ground(7.5, 61)
	for x in [-2, 2]:
		for z in [-1, 1]:
			Models.cylinder(market, Vector3(x, 1.7, z), 0.08, 3.4, Color("786247"))
	Models.box(market, Vector3(0, 3.4, 0), Vector3(4.6, 0.13, 2.8), Color("ddb974"))
	Models.box(market, Vector3(0, 1, 0), Vector3(3.6, 0.3, 1.5), Color("826c4d"))
	for i in range(6):
		Models.sphere(market, Vector3(-1.3 + i * 0.48, 1.3, 0), Vector3.ONE * 0.38, Color("d39459"))
	for p in [Vector2(-34, 50), Vector2(39, 65)]:
		_windmill(p)
	for i in range(12):
		var z = 48 + i * 3.0
		for side in [-1, 1]:
			if i > 4 and i < 8:
				continue
			var p = ground(side * 6, z)
			Models.cylinder(self, p + Vector3.UP * 0.6, 0.06, 1.2, Color("958165"), -1, 6)
			Models.box(self, p + Vector3(0, 0.8, 1.5), Vector3(0.07, 0.1, 3), Color("aa9875"))

func _windmill(p: Vector2) -> void:
	var root = Node3D.new()
	add_child(root)
	root.position = ground(p.x, p.y)
	Models.cylinder(root, Vector3(0, 4.2, 0), 2, 8.4, Color("d1c8a8"), 1.2, 10)
	Models.cylinder(root, Vector3(0, 9.1, 0), 2.3, 2.5, Color("497a74"), 0, 8)
	var blades = Node3D.new()
	root.add_child(blades)
	blades.position = Vector3(0, 7.5, 1.5)
	for i in range(4):
		var arm = Node3D.new()
		blades.add_child(arm)
		arm.rotation.z = i * PI * 0.5
		Models.box(arm, Vector3(0, 2.6, 0), Vector3(0.14, 5.2, 0.18), Color("70694f"))
		Models.box(arm, Vector3(0.5, 3, 0.03), Vector3(0.95, 3.3, 0.07), Color("ebe1ba"))
		for y in range(4):
			Models.box(arm, Vector3(0.5, 1.5 + y, 0.09), Vector3(1.1, 0.06, 0.08), Color("aa9670"))
	Models.sphere(blades, Vector3.ZERO, Vector3.ONE * 0.65, Color("9b8560"))
	windmills.append(blades)
	_collider(root, Vector3(0, 4, 0), Vector3(3, 8, 3))

func _build_shrines() -> void:
	for i in range(GameData.SHRINES.size()):
		var data: Dictionary = GameData.SHRINES[i]
		var p: Vector2 = data["xz"]
		var root = Node3D.new()
		add_child(root)
		root.position = ground(p.x, p.y)
		var color = GameData.element_color(i)
		root.position.y -= 0.45
		for step in range(3):
			Models.cylinder(root, Vector3(0, step * 0.2, 0), 4.4 - step * 0.8, 0.24, Color("b9b9a1"), -1, 12)
		Models.cylinder(root, Vector3(0, 0.9, 0), 0.9, 1.1, Color("7c9290"), 0.65, 6)
		_collider(root, Vector3(0, 0.9, 0), Vector3(1.3, 1.6, 1.3))
		var crystal = Models.crystal(root, Vector3(0, 2.7, 0), 1.5, color)
		var halo = Models.ring(root, Vector3(0, 2.7, 0), 2.1, color, 0.065)
		halo.rotation.x = PI / 2
		for j in range(5):
			var a = j * TAU / 5.0
			var point = Vector3(sin(a) * 3.6, 1.25, cos(a) * 3.6)
			Models.cylinder(root, point, 0.3, 2.4, Color("a2afa3"), 0.25, 5)
			Models.crystal(root, point + Vector3.UP * 1.4, 0.32, color)
		var beam = Models.cylinder(root, Vector3(0, 11, 0), 0.085, 17, color, -1, 6)
		beam.material_override = Models.material(color, 1.5)
		_label(root, data["name"], Vector3(0, 5.9, 0), Color("f6edce"), 34)
		shrines.append({"root": root, "pos": root.position, "element": i, "crystal": crystal, "halo": halo, "beam": beam, "active": false})
		# Regional landmark: clustered crystals and broken columns.
		for j in range(7):
			var a = rng.randf() * TAU
			var distance = rng.randf_range(9, 19)
			var x = p.x + cos(a) * distance
			var z = p.y + sin(a) * distance
			if i == 4 or i == 3:
				var column = Models.cylinder(self, ground(x, z, 1.7), 0.6, rng.randf_range(2, 6), Color("8c9b91"), 0.46, 6)
				column.rotation.z = rng.randf_range(-0.18, 0.18)
			else:
				Models.crystal(self, ground(x, z, 0.7), rng.randf_range(0.6, 1.8), color.darkened(0.2))
		if i == 1:
			for j in range(6):
				var a = j * TAU / 6
				var tree_pos = ground(p.x + cos(a) * 16, p.y + sin(a) * 16)
				Models.cylinder(self, tree_pos + Vector3.UP * 2.0, 0.25, 4, Color("74664c"), 0.15, 6)
				solids.tree(tree_pos, 0.25, 4)
				Models.sphere(self, tree_pos + Vector3.UP * 4.0, Vector3(4.4, 3.3, 4.1), Color("b17943"))
		elif i == 2:
			for j in range(6):
				var stone_pos = ground(-77 + j * 1.2, -39 + j * 3)
				var stone = Models.sphere(self, stone_pos, Vector3(2.8, 1.1, 2.3), Color("9aa99c"))
				solids.rock(stone.mesh, stone.transform)

func _build_observatory() -> void:
	var root = Node3D.new()
	add_child(root)
	root.position = ground(0, -106, -0.25)
	for i in range(3):
		Models.cylinder(root, Vector3(0, i * 0.18 - 0.18, 0), 16.0 - i * 0.7, 0.2, Color("9ca8a0"), -1, 48)
	Models.ring(root, Vector3(0, 0.3, 0), 13.8, Color("d5caa1"), 0.1)
	for i in range(12):
		if i in [0, 1, 11]:
			continue
		var a = TAU * i / 12
		var p = Vector3(sin(a) * 14, 0, cos(a) * 14)
		var height = 8.0 if i % 3 != 0 else 5.2
		Models.cylinder(root, p + Vector3.UP * height * 0.5, 0.85, height, Color("b7bda8"), 0.68, 8)
		Models.box(root, p + Vector3.UP * height, Vector3(2.5, 0.7, 2.1), Color("ccc9ae")).rotation.y = a
		Models.crystal(root, p + Vector3.UP * (height + 0.85), 0.8, Color("b9d8d2"))
	var celestial = Models.ring(root, Vector3(0, 20, -3), 9.0, Color("d3c7a5"), 0.32)
	celestial.rotation.x = 0.9
	celestial.rotation.z = 0.3
	var inner = Models.ring(root, Vector3(0, 20, -3), 6.4, Color("99c2b6"), 0.16)
	inner.rotation.x = 1.2
	inner.rotation.z = -0.4
	beacon = Models.cylinder(root, Vector3(0, 20, -3), 0.15, 38, Color("f3d698"), -1, 8)
	beacon.material_override = Models.material(Color("f3d698"), 1.0)
	beacon.visible = false
	_label(root, "星  陨  观  测  庭", Vector3(0, 11, 0), Color("ebe5cf"), 40)

func _build_nature() -> void:
	var trunks: Array[Transform3D] = []
	var crowns: Array[Transform3D] = []
	var branches: Array[Transform3D] = []
	var pine_trunks: Array[Transform3D] = []
	var pine_crowns: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	var grass: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	for i in range(440):
		var x = rng.randf_range(-144, 144)
		var z = rng.randf_range(-139, 129)
		if height_at(x, z) < 0.8 or _is_clear(x, z, 11):
			continue
		var size = rng.randf_range(0.7, 1.7)
		var point = ground(x, z)
		if z < -25 or absf(x) > 100:
			solids.tree(point, size * 0.17, size * 5)
			pine_trunks.append(Transform3D(Basis().scaled(Vector3(size * 0.34, size * 5, size * 0.34)), point + Vector3.UP * size * 2.5))
			for level in range(3):
				pine_crowns.append(Transform3D(Basis().scaled(Vector3(size * (4.6 - level), size * 4.2, size * (4.6 - level))), point + Vector3.UP * size * (3.6 + level * 1.4)))
		else:
			trunks.append(Transform3D(Basis().scaled(Vector3(size * 0.5, size * 4.4, size * 0.5)), point + Vector3.UP * size * 2.2))
			solids.tree(point, size * 0.25, size * 4.4)
			for side in [-1, 1]:
				branches.append(Transform3D(Basis(Vector3.FORWARD, side * 0.68).scaled(Vector3(size * 0.17, size * 2.5, size * 0.17)), point + Vector3(side * 0.72 * size, size * 2.9, 0)))
			for j in range(3):
				crowns.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size * 4.1, size * 3.4, size * 3.9)), point + Vector3((j - 1) * 1.3 * size, (4.0 + j * 0.45) * size, 0)))
	for i in range(320):
		var x = rng.randf_range(-150, 150)
		var z = rng.randf_range(-150, 140)
		if height_at(x, z) < -1 or _is_clear(x, z, 7):
			continue
		var size = rng.randf_range(0.5, 2.4)
		rocks.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size * 2, size, size * 1.4)), ground(x, z, size * 0.25)))
	for i in range(10500):
		var x = rng.randf_range(-144, 144)
		var z = rng.randf_range(-136, 137)
		if height_at(x, z) < 0.8 or _is_clear(x, z, 4):
			continue
		var size = rng.randf_range(0.4, 0.95)
		grass.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size), ground(x, z, 0.02)))
		if i % 5 == 0:
			flowers.append(Transform3D(Basis().scaled(Vector3(0.15, 0.23, 0.15)), ground(x + 0.2, z, size * 0.8)))
	var cylinder = CylinderMesh.new()
	cylinder.radial_segments = 6
	cylinder.top_radius = 0.42
	cylinder.bottom_radius = 0.5
	cylinder.height = 1
	_batch(cylinder, trunks + pine_trunks + branches, Models.material(Color("766952")))
	var sphere = SphereMesh.new()
	sphere.radial_segments = 20
	sphere.rings = 10
	sphere.radius = 0.5
	sphere.height = 1
	var canopy_light: Array[Transform3D] = []
	var canopy_shade: Array[Transform3D] = []
	for i in range(crowns.size()):
		if i % 3 == 1:
			canopy_light.append(crowns[i])
		else:
			canopy_shade.append(crowns[i])
	var canopy = NatureSculpt.canopy()
	_batch(canopy, canopy_light, NatureSculpt.foliage(Color("739753")))
	_batch(canopy, canopy_shade, NatureSculpt.foliage(Color("527e46")))
	var outer_leaves: Array[Transform3D] = []
	for i in range(crowns.size()):
		var crown: Transform3D = crowns[i]
		for j in range(7):
			var a = j * TAU / 7 + i * 1.7
			var offset = Vector3(cos(a) * 0.37, sin(a * 2 + i) * 0.16, sin(a) * 0.37)
			outer_leaves.append(crown * Transform3D(Basis().scaled(Vector3(0.48, 0.42, 0.47)), offset))
	_batch(canopy, outer_leaves, NatureSculpt.foliage(Color("668b4b")))
	var pine_holder = Node3D.new()
	var pine = CharacterSculpt.loft(pine_holder, [Vector4(-0.5, 0.45, 0.45, 0), Vector4(-0.31, 0.31, 0.31, 0), Vector4(-0.24, 0.39, 0.39, 0), Vector4(-0.04, 0.24, 0.24, 0), Vector4(0.02, 0.29, 0.29, 0), Vector4(0.25, 0.12, 0.12, 0), Vector4(0.5, 0, 0, 0)], Color("417369"), 12)
	_batch(pine.mesh, pine_crowns, NatureSculpt.foliage(Color("477468")))
	pine_holder.free()
	var rock_mat = ShaderMaterial.new()
	rock_mat.shader = load("res://shaders/landscape.gdshader")
	rock_mat.set_shader_parameter("stone", true)
	_batch(sphere, rocks, rock_mat)
	for transform in rocks:
		solids.rock(sphere, transform)
	var blade = SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector3(-0.15, 0, 0), Vector3(0.06, 0.9, 0.03), Vector3(0.15, 0, 0), Vector3(0, 0, -0.13), Vector3(0.04, 0.72, 0.02), Vector3(0, 0, 0.13)]:
		blade.add_vertex(v * Vector3(0.65, 0.64, 0.65))
	blade.generate_normals()
	var grass_mat = ShaderMaterial.new()
	grass_mat.shader = load("res://shaders/grass.gdshader")
	_batch(blade.commit(), grass, grass_mat)
	_batch(sphere, flowers, Models.material(Color("eee2a0")))

func _is_clear(x: float, z: float, margin: float) -> bool:
	for point in Afterlight.POINTS + LumenCampaign.POINTS:
		if point["xz"].distance_to(Vector2(x, z)) < maxf(8.5, margin):
			return true
	for arena in [Vector2(-40, -35), Vector2(55, 87), Vector2(-106, -72)]:
		if arena.distance_to(Vector2(x, z)) < 17:
			return true
	for pos in [Vector2(23, 89), Vector2(-37, 11), Vector2(84, 9), Vector2(-91, -3), Vector2(27, -43), Vector2(84, -65), Vector2(-47, -96), Vector2(35, 103), Vector2(-20, 94), Vector2(-52, 67), Vector2(51, 78), Vector2(96, 39), Vector2(-108, 9), Vector2(-70, -59), Vector2(-102, -82), Vector2(94, -32), Vector2(47, -90), Vector2(14, -119)]:
		if pos.distance_to(Vector2(x, z)) < 3.5:
			return true
	var escort_route = [Vector2(-28, 26), Vector2(-17, 20), Vector2(-27, 4), Vector2(-29, -15), Vector2(-40, -35)]
	for i in range(escort_route.size() - 1):
		if Geometry2D.get_closest_point_to_segment(Vector2(x, z), escort_route[i], escort_route[i + 1]).distance_to(Vector2(x, z)) < 4:
			return true
	if absf(x) < 6.0 and z > -110:
		return true
	if Vector2(x, z + 106).length() < 20:
		return true
	if absf(x) < 36 and z > 47 and z < 90:
		return true
	for data in GameData.SHRINES:
		var end: Vector2 = data["xz"]
		if end.distance_to(Vector2(x, z)) < margin:
			return true
		var start = Vector2(0, 35) if end.y > 0 else Vector2(8, -25)
		if Geometry2D.get_closest_point_to_segment(Vector2(x, z), start, end).distance_to(Vector2(x, z)) < 2.6:
			return true
	return false

func _batch(mesh: Mesh, transforms: Array, mat: Material) -> void:
	if transforms.is_empty():
		return
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var node = MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = mat
	add_child(node)

func _build_chests() -> void:
	var positions = [Vector2(23, 89), Vector2(-37, 11), Vector2(84, 9), Vector2(-91, -3), Vector2(27, -43), Vector2(84, -65), Vector2(-47, -96), Vector2(35, 103)]
	positions.append_array([Vector2(-20, 94), Vector2(-52, 67), Vector2(51, 78), Vector2(96, 39), Vector2(-108, 9), Vector2(-70, -59), Vector2(-102, -82), Vector2(94, -32), Vector2(47, -90), Vector2(14, -119)])
	for i in range(positions.size()):
		var p: Vector2 = positions[i]
		var root = Node3D.new()
		add_child(root)
		root.position = ground(p.x, p.y)
		Models.box(root, Vector3(0, 0.45, 0), Vector3(1.4, 0.9, 0.85), Color("7a674e"))
		var lid = Node3D.new()
		root.add_child(lid)
		lid.position = Vector3(0, 0.98, 0)
		Models.cylinder(lid, Vector3.ZERO, 0.44, 1.42, Color("816347"), -1, 20).rotation.z = PI * 0.5
		for band in [-0.49, 0.49]:
			Models.ring(lid, Vector3(band, 0, 0), 0.449, Color("d1b783"), 0.047).rotation.z = PI * 0.5
		for plank in range(4):
			Models.box(root, Vector3(0, 0.15 + plank * 0.19, 0.438), Vector3(1.38, 0.025, 0.02), Color("584e3b"))
		Models.box(root, Vector3(0, 0.66, 0.49), Vector3(0.24, 0.32, 0.09), Color("d1b783"))
		Models.crystal(root, Vector3(0, 0.68, 0.55), 0.12, Color("afcfd0"))
		for foot in [-0.54, 0.54]:
			Models.box(root, Vector3(foot, 0.06, 0), Vector3(0.23, 0.14, 1.01), Color("625442"))
		for x in [-0.48, 0.48]:
			Models.box(root, Vector3(x, 0.5, 0.45), Vector3(0.09, 1.05, 0.05), Color("dfc584"))
		Models.crystal(root, Vector3(0, 1.7, 0), 0.24, Color("ffe6a5"))
		chests.append({"root": root, "pos": root.position, "lid": lid, "opened": false})

func _build_scenery() -> void:
	# Distant silhouettes give the island a horizon beyond its playable shore.
	for i in range(29):
		var a = i * TAU / 29.0
		var radius = rng.randf_range(270, 460)
		var h = rng.randf_range(28, 85)
		var width = rng.randf_range(32, 74)
		var mountain = Models.mesh_node(self, NatureSculpt.mountain(i), Vector3(cos(a) * radius, -5 + h * 0.36, sin(a) * radius), Color("718d9b"))
		mountain.scale = Vector3(width, h, width)
		mountain.rotation.y = a
	# Travel lanterns lead north.
	for i in range(9):
		var p = ground(5.5, 28 - i * 14)
		Models.cylinder(self, p + Vector3.UP * 1.8, 0.08, 3.6, Color("8e8466"))
		Models.crystal(self, p + Vector3.UP * 3.6, 0.46, Color("f5df9f"))

func activate_shrine(index: int) -> void:
	shrines[index]["active"] = true
	shrines[index]["beam"].visible = false
	shrines[index]["halo"].material_override = Models.material(Color("fff0b5"), 1.2)

func open_chest(index: int) -> void:
	chests[index]["opened"] = true
	chests[index]["lid"].rotation.x = -1.1
	chests[index]["lid"].position.z = -0.3

func _label(parent: Node3D, content: String, pos: Vector3, color: Color, font_size: int) -> Label3D:
	var label = Label3D.new()
	label.text = content
	label.font = load("res://assets/ui_font.tres")
	label.font_size = font_size
	label.pixel_size = 0.013
	label.position = pos
	label.modulate = color
	label.outline_modulate = Color("314b4d")
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	parent.add_child(label)
	return label

func _collider(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body = StaticBody3D.new()
	parent.add_child(body)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	body.add_child(shape)
