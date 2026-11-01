class_name Models
extends RefCounted

static var materials: Dictionary = {}
static var anime_materials: Dictionary = {}

static func stylize(root: Node3D, width: float = 0.004) -> void:
	if root is MeshInstance3D and root.material_override is StandardMaterial3D:
		var source: StandardMaterial3D = root.material_override
		var facial_detail = root.get_parent() != null and root.get_parent().name == "Head" and root.mesh.get_aabb().size.y < 0.20
		var key = str(source.get_instance_id()) + ":" + str(width) + str(facial_detail)
		if not anime_materials.has(key):
			var mat = source.duplicate() as StandardMaterial3D
			mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
			mat.roughness = 0.76 if mat.metallic < 0.1 else 0.33
			mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
			mat.metallic_specular = 0.24
			if facial_detail:
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var outline = ShaderMaterial.new()
			outline.shader = load("res://shaders/ink_outline.gdshader")
			outline.set_shader_parameter("width", width)
			if not mat.emission_enabled and not facial_detail and width > 0.002:
				mat.next_pass = outline
			anime_materials[key] = mat
		root.material_override = anime_materials[key]
	for child in root.get_children():
		if child is Node3D:
			stylize(child, width)

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key = str(color) + str(glow)
	if materials.has(key):
		return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if color.is_equal_approx(Color("d1b783")):
		mat.metallic = 0.4
		mat.roughness = 0.4
		mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	materials[key] = mat
	return mat

static func mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color, glow)
	node.position = pos
	parent.add_child(node)
	return node

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	return mesh_node(parent, mesh, pos, color)

static func sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radial_segments = 24
	mesh.rings = 12
	mesh.radius = 0.5
	mesh.height = 1.0
	var node = mesh_node(parent, mesh, pos, color, glow)
	node.scale = size
	return node

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0, sides: int = 10) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = sides
	return mesh_node(parent, mesh, pos, color)

static func ring(parent: Node3D, pos: Vector3, radius: float, color: Color, thickness: float = 0.06) -> MeshInstance3D:
	var mesh = TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 40
	mesh.ring_segments = 6
	return mesh_node(parent, mesh, pos, color, 0.45)

static func crystal(parent: Node3D, pos: Vector3, size: float, color: Color) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	root.position = pos
	var upper = cylinder(root, Vector3(0, size * 0.25, 0), size * 0.34, size, color, 0.0, 5)
	upper.material_override = material(color, 0.7)
	var lower = cylinder(root, Vector3(0, -size * 0.42, 0), 0.0, size * 0.34, color.darkened(0.16), size * 0.34, 5)
	lower.material_override = material(color.darkened(0.1), 0.4)
	return root

static func character(index: int) -> Node3D:
	return CharacterSculpt.build(index)
