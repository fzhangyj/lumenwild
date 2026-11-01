extends SceneTree

var checks = 0
var failures = 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if value:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func triangle_count(mesh: Mesh) -> int:
	return mesh.get_faces().size() / 3

func run() -> void:
	# Regression: merging a custom unindexed mesh with indexed primitives
	# previously discarded all custom triangles when the output acquired indices.
	for reverse in [false, true]:
		var group = Node3D.new()
		var loft = CharacterSculpt.loft(group, [Vector4(4, 1, 1, 0), Vector4(6, 0.5, 0.5, 0)], Color("f4d1b5"))
		var sphere = Models.sphere(group, Vector3(3, 0, 0), Vector3.ONE, Color("f4d1b5"))
		if reverse:
			group.move_child(sphere, 0)
		var expected = triangle_count(loft.mesh) + triangle_count(sphere.mesh)
		var expected_bounds = (loft.transform * loft.mesh.get_aabb()).merge(sphere.transform * sphere.mesh.get_aabb())
		CharacterSculpt._bake(group)
		var mesh: Mesh = group.get_child(0).mesh
		check(triangle_count(mesh) == expected, "Mixed meshes retain every triangle, reverse %s" % reverse)
		var bounds = mesh.get_aabb()
		check(bounds.is_equal_approx(expected_bounds), "Baked meshes retain both shapes and local transforms, reverse %s" % reverse)
		group.free()
	var source = Models.character(17)
	var cached = Models.character(17)
	var source_faces = 0
	var cached_faces = 0
	for limb in source.get_children():
		for part in limb.get_children():
			source_faces += triangle_count(part.mesh)
	for limb in cached.get_children():
		for part in limb.get_children():
			cached_faces += triangle_count(part.mesh)
	check(source_faces > 0 and source_faces == cached_faces, "Cached character instances retain all sculpted triangles")
	var has_face = false
	for part in cached.get_node("Head").get_children():
		if part.material_override.albedo_color.is_equal_approx(Color("f4d1b5")):
			var bounds: AABB = part.mesh.get_aabb()
			has_face = bounds.position.y <= -0.26 and bounds.end.y >= 0.30
	check(has_face, "Cached head retains a complete face from chin to crown")
	source.free()
	cached.free()
	# Every playable character must retain the pivots consumed by animation,
	# including characters which are initially locked behind limited banners.
	for index in range(GameData.CHARACTER_COUNT):
		var avatar = Models.character(index)
		var valid = true
		for pivot in ["Body", "Head", "LegL", "LegR", "ArmL", "ArmR", "Cape"]:
			valid = valid and avatar.has_node(pivot)
			if avatar.has_node(pivot):
				var limb: Node3D = avatar.get_node(pivot)
				valid = valid and limb.get_child_count() > 0
				for part in limb.get_children():
					valid = valid and part is MeshInstance3D and part.mesh.get_faces().size() > 0
		check(valid,"Character %02d retains renderable animated limbs" % index)
		avatar.free()
	print("MODEL RESULT: ", checks - failures, "/", checks, " checks passed")
	quit(0 if failures == 0 else 1)
