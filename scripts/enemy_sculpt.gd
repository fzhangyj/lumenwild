class_name EnemySculpt
extends RefCounted

static func guardian(visual: Node3D) -> Node3D:
	var stone = Color("647c81")
	var armor = Color("b4b9a5")
	var bronze = Color("c4ad80")
	for side in [-1, 1]:
		CharacterSculpt.loft(visual, [Vector4(0.15, 0.48, 0.65, -0.1), Vector4(0.48, 0.45, 0.55, -0.1), Vector4(1.1, 0.31, 0.34, 0), Vector4(1.6, 0.36, 0.36, 0), Vector4(2.2, 0.39, 0.40, 0)], stone, 10).position.x = side * 0.72
		CharacterSculpt.leaf(visual, Vector3(side * 0.72, 1.8, -0.30), Vector3(side * 0.72, 0.75, -0.48), 0.40, armor, 0.20)
		Models.sphere(visual, Vector3(side * 0.72, 1.8, -0.30), Vector3.ONE * 0.55, bronze)
		CharacterSculpt.leaf(visual, Vector3(side * 1.15, 4.2, 0), Vector3(side * 2.1, 3.35, 0), 0.65, armor, 0.42)
		CharacterSculpt.loft(visual, [Vector4(1.9, 0.40, 0.40, 0), Vector4(2.2, 0.45, 0.45, 0), Vector4(3.2, 0.34, 0.35, 0), Vector4(3.65, 0.38, 0.38, 0)], stone, 10).position.x = side * 1.91
		Models.cylinder(visual, Vector3(side * 1.91, 2.35, 0), 0.47, 0.16, bronze, -1, 10)
		CharacterSculpt.leaf(visual, Vector3(side * 1.91, 3.18, -0.31), Vector3(side * 1.91, 2.05, -0.46), 0.36, armor, 0.12)
		Models.crystal(visual, Vector3(side * 1.91, 3.65, -0.29), 0.34, Color("ecc292"))
		CharacterSculpt.leaf(visual, Vector3(side * 0.36, 2.7, -0.49), Vector3(side * 1.0, 1.74, -0.58), 0.31, bronze, 0.08)
	CharacterSculpt.loft(visual, [Vector4(2.1, 0.62, 0.45, 0), Vector4(2.7, 0.73, 0.54, 0), Vector4(3.6, 1.14, 0.64, 0), Vector4(4.1, 1.11, 0.58, 0), Vector4(4.4, 0.65, 0.38, 0)], stone, 12)
	for side in [-1, 1]:
		CharacterSculpt.leaf(visual, Vector3(side * 0.9, 4.13, -0.38), Vector3(side * 0.28, 3.18, -0.65), 0.35, armor, 0.17)
		CharacterSculpt.leaf(visual, Vector3(side * 0.85, 4.1, -0.55), Vector3(side * 0.25, 3.25, -0.80), 0.04, bronze, 0.03)
	CharacterSculpt.loft(visual, [Vector4(4.33, 0.21, 0.22, -0.05), Vector4(4.58, 0.46, 0.39, 0), Vector4(5.05, 0.52, 0.44, 0), Vector4(5.30, 0.33, 0.35, 0), Vector4(5.41, 0.06, 0.06, 0)], armor, 12)
	for side in [-1, 1]:
		CharacterSculpt.leaf(visual, Vector3(side * 0.08, 4.99, -0.44), Vector3(side * 0.40, 5.01, -0.32), 0.035, Color("f8d39f"), 0.022)
		CharacterSculpt.leaf(visual, Vector3(side * 0.39, 5.14, 0), Vector3(side * 0.77, 5.84, 0.08), 0.19, bronze, 0.12)
	var core = Models.crystal(visual, Vector3(0, 3.68, -0.71), 0.72, Color("e5a283"))
	Models.ring(visual, Vector3(0, 3.68, -0.73), 0.48, bronze, 0.055).rotation.x = PI * 0.5
	Models.ring(visual, Vector3(0, 4.5, 0.82), 1.67, bronze, 0.075).rotation.x = PI * 0.5
	return core
