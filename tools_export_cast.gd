extends SceneTree

# Export the same meshes used by combat, portraits and the character gallery.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/blender/cast")
	var manifest: Array = []
	for index in range(GameData.CHARACTER_COUNT):
		var avatar = Models.character(index)
		var document = GLTFDocument.new()
		var state = GLTFState.new()
		var result = document.append_from_scene(avatar, state)
		if result == OK:
			result = document.write_to_filesystem(state, "res://assets/blender/cast/character_%02d.glb" % index)
		print("EXPORT ", index, " ", GameData.character(index)["name"], " ", result)
		manifest.append({"id":index,"name":GameData.character(index)["name"],"outfit":AnimeCast.DESIGNS[index][5],"hair":AnimeCast.DESIGNS[index][3],"file":"character_%02d" % index})
		avatar.free()
		if result != OK:
			quit(1)
			return
	var file = FileAccess.open("res://assets/blender/cast/manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"))
	quit()
