class_name BeastSculpt
extends RefCounted

const NAMES = ["蚀光体", "火绒团", "苔角兽", "潮灯灵", "晶甲蟹"]
const COLORS = [Color("ae7ed8"), Color("edac73"), Color("9dce93"), Color("98dbe8"), Color("c8a4df")]

static func build(root: Node3D, kind: int) -> Node3D:
	var color: Color = COLORS[kind]
	var core: Node3D
	match kind:
		1:
			var body = Models.sphere(root, Vector3(0, 0.72, 0), Vector3(1.65, 1.38, 1.5), Color("e6976b"))
			CharacterSculpt._smooth(body)
			Models.sphere(root, Vector3(0, 0.63, -0.51), Vector3(1.08, 0.75, 0.38), Color("ffdc9c"))
			for side in [-1, 1]:
				Models.sphere(root, Vector3(side * 0.52, 0.12, -0.12), Vector3(0.58, 0.22, 0.72), Color("d08063"))
				CharacterSculpt.leaf(root, Vector3(side * 0.35, 1.17, 0), Vector3(side * 0.61, 1.84, 0.07), 0.19, color, 0.12)
			core = Models.crystal(root, Vector3(0, 1.60, 0), 0.53, Color("ffe2a0"))
			_eyes(root, 0.25, 0.86, -0.705, Color("80524d"))
			Models.sphere(root, Vector3(0, 0.60, -0.72), Vector3(0.15, 0.07, 0.035), Color("985d59"))
		2:
			Models.sphere(root, Vector3(0, 0.94, 0.13), Vector3(1.18, 1.12, 1.8), Color("698f77"))
			Models.sphere(root, Vector3(0, 1.34, -0.74), Vector3(0.93, 0.96, 0.89), Color("adc8a0"))
			Models.sphere(root, Vector3(0, 1.09, -1.14), Vector3(0.63, 0.39, 0.53), Color("e3ddbc"))
			Models.sphere(root, Vector3(0, 1.15, -1.41), Vector3(0.18, 0.11, 0.07), Color("384f55"))
			for side in [-1, 1]:
				for fore in [-1, 1]:
					var leg = Node3D.new()
					root.add_child(leg)
					leg.name = "Paw%d%d" % [side, fore]
					leg.position = Vector3(side * 0.4, 0.73, fore * 0.62)
					Models.sphere(leg, Vector3(0, 0.01, 0), Vector3(0.37, 0.38, 0.39), Color("698f77"))
					CharacterSculpt.loft(leg, [Vector4(-0.63, 0.20, 0.25, -0.05), Vector4(-0.45, 0.13, 0.16, 0), Vector4(0, 0.17, 0.19, 0)], Color("526f65"), 12)
				CharacterSculpt.leaf(root, Vector3(side * 0.31, 1.64, -0.64), Vector3(side * 0.58, 2.05, -0.57), 0.17, color, 0.05)
				CharacterSculpt.leaf(root, Vector3(side * 0.27, 1.73, -0.57), Vector3(side * 0.49, 2.36, -0.39), 0.10, Color("c4b989"), 0.07)
				CharacterSculpt.leaf(root, Vector3(side * 0.40, 2.06, -0.47), Vector3(side * 0.71, 2.18, -0.58), 0.065, Color("c4b989"), 0.05)
				for i in range(3):
					CharacterSculpt.leaf(root, Vector3(side * 0.28, 1.38, i * 0.3), Vector3(side * 0.72, 0.82, i * 0.3 + 0.2), 0.25, color.darkened(i * 0.06), 0.055)
			CharacterSculpt.leaf(root, Vector3(0, 0.94, 0.87), Vector3(0, 1.31, 1.65), 0.27, color, 0.1)
			core = Models.crystal(root, Vector3(0, 1.57, -1.12), 0.18, Color("d6e7ab"))
			_eyes(root, 0.245, 1.43, -1.10, Color("304f56"))
		3:
			Models.sphere(root, Vector3(0, 1.63, 0), Vector3(1.34, 1.03, 1.24), Color("8bbbcf"))
			Models.sphere(root, Vector3(0, 1.73, 0), Vector3(1.12, 0.88, 1.07), Color("b8e5e4"))
			Models.ring(root, Vector3(0, 1.44, 0), 0.65, Color("eadcb5"), 0.035)
			for i in range(6):
				var a = i * TAU / 6
				CharacterSculpt.leaf(root, Vector3(cos(a) * 0.39, 1.44, sin(a) * 0.39), Vector3(cos(a + 0.3) * 0.65, 0.3 + (i % 2) * 0.2, sin(a + 0.3) * 0.65), 0.105, color, 0.035)
			core = Models.sphere(root, Vector3(0, 1.15, 0), Vector3.ONE * 0.48, Color("e5faf0"), 0.7)
			_eyes(root, 0.25, 1.60, -0.58, Color("345b71"))
			Models.ring(root, Vector3(0, 2.38, 0), 0.38, color, 0.025)
		4:
			Models.sphere(root, Vector3(0, 0.75, 0), Vector3(1.70, 1.06, 1.24), Color("786f97"))
			for side in [-1, 1]:
				for i in range(3):
					var z = -0.43 + i * 0.42
					CharacterSculpt.leaf(root, Vector3(side * 0.50, 0.68, z), Vector3(side * 1.10, 0.44, z + 0.12), 0.13, Color("a8a4c4"), 0.085)
					CharacterSculpt.leaf(root, Vector3(side * 1.10, 0.44, z + 0.12), Vector3(side * 1.31, 0.10, z + 0.26), 0.09, Color("655b85"), 0.065)
				var claw = Node3D.new()
				root.add_child(claw)
				claw.name = "ClawL" if side < 0 else "ClawR"
				claw.position = Vector3(side * 0.77, 0.78, -0.52)
				Models.sphere(claw, Vector3(side * 0.33, 0, -0.26), Vector3(0.63, 0.53, 0.73), Color("c6aacb"))
				for finger in [-1, 1]:
					CharacterSculpt.leaf(claw, Vector3(side * 0.33 + finger * 0.16, 0, -0.48), Vector3(side * 0.33 + finger * 0.11, 0.02, -0.99), 0.12, color, 0.09)
			for i in range(3):
				var plate = Models.crystal(root, Vector3((i - 1) * 0.44, 1.17, 0.1), 0.47 if i != 1 else 0.73, color)
				plate.rotation.z = (i - 1) * -0.28
			core = Models.crystal(root, Vector3(0, 0.74, -0.64), 0.30, Color("e3cded"))
			_eyes(root, 0.31, 1.01, -0.62, Color("393e63"))
	Models.stylize(root, 0.009)
	return core

static func _eyes(root: Node3D, width: float, y: float, z: float, color: Color) -> void:
	for side in [-1, 1]:
		Models.sphere(root, Vector3(side * width, y, z), Vector3(0.15, 0.22, 0.055), color)
		Models.sphere(root, Vector3(side * width - 0.026, y + 0.047, z - 0.028), Vector3(0.045, 0.064, 0.016), Color("fff9e4"))
