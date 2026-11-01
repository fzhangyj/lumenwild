class_name AnimeCast
extends RefCounted

# Bespoke silhouette, hair construction, costume and headpiece for every character.
# height, shoulder width, face width, hairstyle, hair length, outfit, ornament
const DESIGNS = [
	[1.00,0.26,0.96,"crop",0.32,"courier","feather"],
	[1.04,0.30,1.04,"spike",0.27,"smith","goggles"],
	[0.98,0.245,0.94,"wave",1.23,"singer","pearls"],
	[1.06,0.28,0.92,"side",0.38,"officer","earcuff"],
	[1.12,0.36,1.07,"swept",0.31,"guardian","crest"],
	[1.02,0.245,0.91,"pony",1.06,"navigator","moon"],
	[1.04,0.26,0.94,"flare",0.85,"duelist","phoenix"],
	[1.08,0.275,0.90,"side",0.72,"officer","veil"],
	[1.01,0.25,0.96,"braids",1.05,"captain","captain"],
	[1.10,0.31,1.01,"bun",0.32,"scholar","brush"],
	[0.97,0.26,0.96,"crop",0.26,"courier","scarf"],
	[0.99,0.24,0.92,"straight",1.31,"singer","lotus"],
	[1.08,0.30,1.02,"shag",0.45,"ranger","fur"],
	[1.13,0.33,0.97,"swept",0.26,"guardian","horn"],
	[1.01,0.25,0.95,"twin",0.93,"navigator","stars"],
	[1.03,0.28,0.98,"bun",0.53,"scholar","fan"],
	[1.05,0.30,1.05,"spike",0.36,"duelist","sunband"],
	[0.96,0.24,0.95,"braids",0.92,"druid","flowers"],
	[1.12,0.35,1.06,"shag",0.33,"smith","goggles"],
	[1.07,0.265,0.94,"side",0.81,"scholar","harp"],
	[1.00,0.245,0.91,"wave",1.16,"singer","sun"],
	[1.09,0.28,0.93,"straight",0.65,"officer","tuning"],
	[0.98,0.25,0.99,"twin",0.48,"ranger","beret"]
]

static func make(index: int) -> Node3D:
	var d: Array = DESIGNS[index]
	var data = GameData.character(index)
	var color: Color = data["color"]
	var dark: Color = data["dark"]
	var gold = Color("d8bb7c")
	var ivory = Color("f1eee4")
	var skin = Color("f4d1b5")
	var hair = Color(CharacterSculpt.HAIR[index])
	var root=Node3D.new()
	root.name="Avatar"
	root.set_meta("design",str(d))
	var body=CharacterSculpt._group(root,"Body",Vector3.ZERO)
	var cape=CharacterSculpt._group(root,"Cape",Vector3(0,1.84,0.10))
	var width: float=d[1]
	var outfit: String=d[5]
	var skirt = outfit in ["singer","druid","navigator"]
	var bodice: Color=ivory if outfit in ["singer","scholar"] else dark
	CharacterSculpt.loft(body,[Vector4(1.08,0.24,0.145,0),Vector4(1.24,0.19,0.12,0),Vector4(1.46,0.22,0.15,0),Vector4(1.68,width,0.14,0),Vector4(1.82,width*0.85,0.11,0),Vector4(1.87,0.11,0.087,0)],bodice,32)
	CharacterSculpt.loft(body,[Vector4(1.84,0.072,0.066,0),Vector4(2.025,0.065,0.064,0)],skin,24)
	CharacterSculpt.loft(body,[Vector4(1.17,0.205,0.142,0),Vector4(1.23,0.203,0.143,0)],dark.darkened(0.20),32)
	Models.sphere(body,Vector3(0.08,1.20,-0.15),Vector3(0.087,0.073,0.017),gold)
	if skirt:
		var hem=0.53 if outfit=="singer" else 0.88
		CharacterSculpt.loft(body,[Vector4(hem,0.44,0.24,0.01),Vector4(0.96,0.33,0.195,0.015),Vector4(1.18,0.22,0.15,0)],dark,40)
		for side in [-1,1]:
			CharacterSculpt._drape(body,Vector3(side*0.15,1.18,-0.14),Vector3(side*0.32,hem+0.03,-0.245),0.07,0.17,ivory,gold)
		if outfit=="singer":
			for side in [-1,1]:
				CharacterSculpt._drape(body,Vector3(side*0.21,1.19,0.04),Vector3(side*0.47,0.29,0.17),0.08,0.18,color.darkened(0.12),gold)
	elif outfit in ["scholar","officer","captain"]:
		for side in [-1,1]:
			CharacterSculpt._drape(body,Vector3(side*0.17,1.22,-0.10),Vector3(side*0.28,0.45,-0.16),0.065,0.12,dark,gold)
			CharacterSculpt._drape(body,Vector3(side*0.17,1.24,0.11),Vector3(side*0.30,0.32,0.23),0.08,0.19,dark,gold)
	elif outfit=="smith":
		CharacterSculpt._drape(body,Vector3(0,1.62,-0.16),Vector3(0,0.85,-0.19),0.15,0.23,Color("795547"),gold)
		Models.box(body,Vector3(0.26,1.02,0),Vector3(0.13,0.20,0.13),Color("54434a"))
	elif outfit=="guardian":
		CharacterSculpt.loft(body,[Vector4(1.33,0.22,0.166,0),Vector4(1.55,width*0.96,0.18,0),Vector4(1.75,width,0.155,0)],dark.lightened(0.13),16)
		for side in [-1,1]:
			CharacterSculpt._drape(body,Vector3(side*0.15,1.20,-0.13),Vector3(side*0.28,0.79,-0.20),0.07,0.14,ivory,gold)
	else:
		CharacterSculpt._drape(body,Vector3(-0.20,1.84,-0.10),Vector3(0.13,1.23,-0.155),0.045,0.05,Color("c3a67a"),gold)
	# Tailored necklines and asymmetric scarf, rather than identical armor on every body.
	for side in [-1,1]:
		CharacterSculpt.leaf(body,Vector3(side*0.09,1.85,-0.07),Vector3(side*0.17,1.65,-0.146),0.046,dark if outfit=="singer" else ivory,0.012)
	Models.crystal(body,Vector3(-0.105,1.72,-0.164),0.053,color)
	# Fitted waist insets, embroidered seams and layered asymmetric lapels.
	for side in [-1,1]:
		CharacterSculpt._drape(body,Vector3(side*0.165,1.68,-0.145),Vector3(side*0.105,1.23,-0.146),0.050,0.055,dark if bodice==ivory else color.darkened(0.35),gold)
		for j in range(6):
			var y=1.28+j*0.048
			var x=side*(0.145+(y-1.28)*0.08)
			CharacterSculpt.leaf(body,Vector3(x,y,-0.164),Vector3(x+side*0.033,y+0.025,-0.167),0.006,gold,0.004)
		Models.ring(body,Vector3(side*0.205,1.17,-0.10),0.031,gold,0.006).rotation.x=PI/2
		CharacterSculpt.leaf(body,Vector3(side*0.205,1.14,-0.10),Vector3(side*0.245,0.97,-0.145),0.009,gold,0.005)
	if outfit in ["officer","captain","scholar"]:
		for j in range(4):
			Models.sphere(body,Vector3(0,1.35+j*0.087,-0.153),Vector3.ONE*0.020,gold)
	if outfit in ["singer","druid"]:
		CharacterSculpt._drape(body,Vector3(0,1.26,-0.15),Vector3(0,0.77,-0.23),0.065,0.08,color.darkened(0.2),gold)
	if outfit in ["courier","ranger","navigator","duelist"]:
		CharacterSculpt.cloth(cape,color.darkened(0.32),0.66,0.41 if outfit=="courier" else 0.96,true)
	elif outfit in ["guardian","officer"]:
		CharacterSculpt.cloth(cape,dark.darkened(0.12),0.79,1.25,true)
	else:
		for side in [-1,1]:
			CharacterSculpt._drape(cape,Vector3(side*0.12,0,0),Vector3(side*0.34,-0.90,0.22),0.035,0.07,color.darkened(0.1),gold)
	for side in [-1,1]:
		var leg=CharacterSculpt._group(root,"LegL" if side<0 else "LegR",Vector3(side*0.128,1.10,0))
		var leg_color=skin if skirt else dark.darkened(0.38)
		CharacterSculpt.loft(leg,[Vector4(-0.94,0.062,0.074,0),Vector4(-0.72,0.076,0.082,0),Vector4(-0.52,0.080,0.08,-0.013),Vector4(-0.30,0.099,0.10,0),Vector4(0,0.108,0.11,0)],leg_color,24)
		var boot_top=-0.76 if outfit in ["singer","scholar"] else -0.46
		CharacterSculpt.loft(leg,[Vector4(-1.08,0.078,0.155,-0.054),Vector4(-1.02,0.080,0.142,-0.06),Vector4(-0.94,0.065,0.086,0),Vector4(boot_top,0.083,0.084,0)],dark.darkened(0.25),24)
		CharacterSculpt.loft(leg,[Vector4(boot_top-0.027,0.086,0.089,0),Vector4(boot_top,0.086,0.089,0)],gold,24)
		var arm=CharacterSculpt._group(root,"ArmL" if side<0 else "ArmR",Vector3(side*(width+0.047),1.79,0))
		var bare = outfit in ["singer","smith","duelist","druid"]
		CharacterSculpt.loft(arm,[Vector4(-0.67,0.045,0.055,-0.025),Vector4(-0.45,0.060,0.067,0),Vector4(-0.31,0.065,0.067,0),Vector4(-0.16,0.079,0.078,0),Vector4(0,0.093,0.084,0),Vector4(0.055,0.047,0.057,0)],skin if bare else dark,24)
		Models.sphere(arm,Vector3(0,0.005,0),Vector3(0.185,0.17,0.164),skin if bare else dark)
		if outfit in ["scholar","singer"]:
			CharacterSculpt.loft(arm,[Vector4(-0.60,0.13,0.11,0),Vector4(-0.45,0.115,0.10,0),Vector4(-0.24,0.070,0.08,0)],ivory if outfit=="scholar" else dark,24)
		else:
			CharacterSculpt.loft(arm,[Vector4(-0.65,0.052,0.063,-0.02),Vector4(-0.45,0.066,0.075,0)],dark.darkened(0.13),24)
		if outfit in ["guardian","officer"]:
			CharacterSculpt.loft(arm,[Vector4(-0.12,0.125,0.117,0),Vector4(0.05,0.114,0.11,0),Vector4(0.09,0.055,0.07,0)],gold.darkened(0.12),20)
		Models.sphere(arm,Vector3(0,-0.725,-0.027),Vector3(0.095,0.15,0.07),skin)
		for f in range(4): Models.sphere(arm,Vector3(-0.031+f*0.021,-0.806+absf(f-1.5)*0.009,-0.03),Vector3(0.022,0.08,0.031),skin)
		if side==1: CharacterSculpt._weapon(arm,GameData.element_of(index),index,color,dark,gold)
	var head=CharacterSculpt._group(root,"Head",Vector3(0,2.12,0))
	_face(head,index,color,skin,hair)
	_hair(head,index,hair)
	_ornament(head,body,index,color,gold)
	CastRefinement.costume(root, body, head, cape, index, color, dark, gold, ivory)
	for group in root.get_children(): CharacterSculpt._bake(group)
	# Facial construction stays consistent with the neck; variations affect the whole skeleton.
	root.scale=Vector3(1,d[0],1)
	# Six-head illustration proportions; retain the neck and animation pivots.
	head.scale=Vector3(0.74*d[2],0.73,0.76)
	for side in [-1, 1]:
		var arm: Node3D = root.get_node("ArmL" if side < 0 else "ArmR")
		arm.rotation.z = side * 0.10
	Models.stylize(root,0.0012)
	return root

static func _face(head: Node3D,index: int,color: Color,skin: Color,hair: Color) -> void:
	var angular=index in [1,3,4,9,12,13,16,18,19,21]
	var chin=0.064 if angular else 0.043
	var face=CharacterSculpt.loft(head,[Vector4(-0.27,0.012,0.035,-0.012),Vector4(-0.25,chin,0.071,-0.017),Vector4(-0.20,0.121,0.118,-0.022),Vector4(-0.12,0.180,0.15,-0.01),Vector4(-0.03,0.212,0.177,0),Vector4(0.07,0.222,0.189,0.009),Vector4(0.18,0.210,0.185,0.016),Vector4(0.26,0.166,0.145,0.02),Vector4(0.32,0.062,0.065,0.02),Vector4(0.335,0.001,0.001,0.02)],skin,48)
	CharacterSculpt._smooth(face)
	for side in [-1,1]:
		Models.sphere(head,Vector3(side*0.22,-0.03,0),Vector3(0.045,0.09,0.055),skin)
		_eye(head,side,color,0.98 if angular else 1.12)
		CharacterSculpt.leaf(head,Vector3(side*0.038,0.097,-0.191),Vector3(side*0.161,0.109 if angular else 0.099,-0.149),0.006,hair.darkened(0.45),0.004)
	# Small angular nose and lip, with no protruding spherical button nose.
	Models.sphere(head,Vector3(0,-0.070,-0.182),Vector3(0.020,0.033,0.026),skin)
	CharacterSculpt.leaf(head,Vector3(-0.023,-0.151,-0.153),Vector3(0.026,-0.148,-0.153),0.0035,Color("b87977"),0.002)

static func _eye(head: Node3D, side: int, iris: Color, tall: float) -> void:
	var sclera=SurfaceTool.new()
	var lashes=SurfaceTool.new()
	sclera.begin(Mesh.PRIMITIVE_TRIANGLES)
	lashes.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(24):
		var vertices: Array[Vector3]=[]
		var lid: Array[Vector3]=[]
		for j in [i,i+1]:
			var u=-1.0+j/12.0
			var x=side*(0.099+u*0.066)
			var z=-sqrt(maxf(0.01,1.0-pow(x/0.239,2)))*0.189-0.005
			var shape=pow(maxf(0,1-u*u),0.72)
			var y=0.024+u*0.011
			vertices.append(Vector3(x,y+shape*0.029*tall,z))
			vertices.append(Vector3(x,y-shape*0.024*tall,z))
			lid.append(Vector3(x,y+shape*0.029*tall,z-0.001))
			lid.append(Vector3(x,y+shape*0.029*tall+shape*0.0045,z-0.001))
		for k in [0,1,2,2,1,3]:
			sclera.add_vertex(vertices[k]); lashes.add_vertex(lid[k])
	for pair in [[sclera,Color("fff6ec")],[lashes,Color("43333e")]]:
		pair[0].generate_normals()
		var node=Models.mesh_node(head,pair[0].commit(),Vector3.ZERO,pair[1])
		var mat=node.material_override.duplicate() as StandardMaterial3D
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		node.material_override=mat
	var p=Vector3(side*0.098,0.024,-0.184)
	Models.sphere(head,p,Vector3(0.054,0.055*tall,0.005),iris.darkened(0.58))
	Models.sphere(head,p+Vector3(0,-0.006,-0.003),Vector3(0.044,0.039*tall,0.004),iris.darkened(0.08))
	Models.sphere(head,p+Vector3(0,-0.014,-0.005),Vector3(0.033,0.014*tall,0.003),iris.lightened(0.28))
	Models.sphere(head,p+Vector3(0,0.006,-0.006),Vector3(0.015,0.031*tall,0.003),Color("29313e"))
	Models.sphere(head,p+Vector3(-0.011,0.014,-0.009),Vector3(0.013,0.012,0.003),Color("fffaf2"))
	Models.sphere(head,p+Vector3(0.012,-0.012,-0.009),Vector3(0.006,0.005,0.002),Color("fffaf2"))
	CharacterSculpt.leaf(head,Vector3(side*0.151,0.043,-0.152),Vector3(side*0.182,0.061,-0.126),0.005,Color("43333e"),0.004)

static func _hair(head: Node3D,index: int,color: Color) -> void:
	var style: String=DESIGNS[index][3]
	var length: float=DESIGNS[index][4]
	CharacterSculpt.loft(head,[Vector4(0.13,0.235,0.207,0.036),Vector4(0.23,0.221,0.200,0.035),Vector4(0.31,0.16,0.145,0.035),Vector4(0.365,0.01,0.01,0.04)],color,40)
	var back_length = length if style in ["wave","straight","flare","shag","side"] else 0.27
	for i in range(17):
		var a=PI*i/16
		var end=Vector3(cos(a)*(0.25+(0.045 if style=="wave" else 0.0)), -back_length+sin(i*1.6)*0.04,sin(a)*0.20+0.12)
		CharacterSculpt._lock(head,Vector3(cos(a)*0.12,0.29,sin(a)*0.12+0.04),Vector3(cos(a)*0.255,0.13,sin(a)*0.24+0.05),Vector3(cos(a)*(0.29 if style=="wave" else 0.25),-back_length*0.74,sin(a)*0.24+0.12),end,0.052,0.022,color.darkened((i%3)*0.035))
	# Broad swept locks with pointed ends, leaving the iris and eyebrows visible.
	var sweep=0.065 if style in ["side","swept","pony","flare"] else -0.025
	for i in range(7):
		var x=-0.19+i*0.063
		var tip=0.115+absf(x)*0.20 if style=="straight" else 0.085+absf(sin(i*0.83+index*0.31))*0.075
		CharacterSculpt._lock(head,Vector3(x*0.38-sweep,0.34,-0.015),Vector3(x*0.65-sweep,0.30,-0.16),Vector3(x+sweep*0.35,0.19,-0.226),Vector3(x+sweep,tip,-0.218),0.055,0.017,color.lightened((i%3)*0.025))
	if style in ["crop","swept","spike","flare"]:
		for i in range(3):
			CharacterSculpt._lock(head,Vector3(-0.03,0.31,0.04),Vector3(0.06,0.47,0.04),Vector3(0.17,0.46,0.03),Vector3(0.14+i*0.024,0.39+i*0.024,0.02),0.026,0.012,color)
	for side in [-1,1]:
		CharacterSculpt._lock(head,Vector3(side*0.19,0.26,-0.075),Vector3(side*0.26,0.10,-0.11),Vector3(side*0.25,-0.17,-0.10),Vector3(side*0.20,-0.32,-0.09),0.043,0.020,color)
	if style in ["pony","twin","braids"]:
		var sides = [1] if style=="pony" else [-1,1]
		for side in sides:
			var x=0.05 if style=="pony" else side*0.27
			for i in range(6):
				var offset=(i-2.5)*0.021
				CharacterSculpt._lock(head,Vector3(x,0.17,0.22),Vector3(x+side*0.16,0.20,0.39),Vector3(x+side*0.14,-length*0.72,0.32),Vector3(x+offset+side*0.17,-length,0.17),0.052,0.023,color.darkened((i%3)*0.04))
			if style=="braids":
				for j in range(9):
					for braid_side in [-1, 1]:
						var y = -j * 0.085
						CharacterSculpt._lock(head,Vector3(x+side*0.13-braid_side*0.035,y+0.06,0.29),Vector3(x+side*0.13+braid_side*0.07,y+0.02,0.25),Vector3(x+side*0.13+braid_side*0.05,y-0.03,0.26),Vector3(x+side*0.13,y-0.07,0.30),0.035,0.022,color.lightened(0.025 if braid_side==1 else 0.0))
			Models.ring(head,Vector3(x,0.15,0.25),0.076,Color("d1b783"),0.013).rotation.x=PI/2
	if style=="bun":
		Models.sphere(head,Vector3(0,0.19,0.29),Vector3(0.30,0.30,0.25),color)
	if style=="spike":
		for i in range(7):
			CharacterSculpt.leaf(head,Vector3((i-3)*0.046,0.24,0.03),Vector3((i-3)*0.075,0.43+sin(i)*0.05,0.10),0.060,color,0.028)

static func _ornament(head: Node3D,body: Node3D,index: int,color: Color,gold: Color) -> void:
	var ornament: String=DESIGNS[index][6]
	match ornament:
		"captain","beret":
			var cap=Models.sphere(head,Vector3(0,0.31,0.025),Vector3(0.63,0.20,0.48),Color("263e52") if ornament=="captain" else color.darkened(0.45))
			cap.rotation.z=-0.13
			CharacterSculpt.leaf(head,Vector3(-0.22,0.24,-0.08),Vector3(0.23,0.24,-0.14),0.045,gold,0.02)
		"moon":
			Models.ring(head,Vector3(-0.24,0.20,-0.02),0.095,gold,0.012).rotation.x=PI/2
			CharacterSculpt.leaf(head,Vector3(-0.24,0.14,0),Vector3(-0.31,-0.30,0.12),0.027,color)
		"goggles":
			for side in [-1,1]:
				Models.ring(head,Vector3(side*0.11,0.20,-0.16),0.071,gold,0.015).rotation.x=PI/2
				Models.sphere(head,Vector3(side*0.11,0.20,-0.16),Vector3(0.095,0.09,0.017),Color("597a7c"))
		"sun","crest","stars":
			for i in range(5):
				var x=(i-2)*0.080
				CharacterSculpt.leaf(head,Vector3(x,0.21,-0.16),Vector3(x*1.15,0.33+(0.10 if i==2 else 0),-0.10),0.028,gold,0.011)
		"flowers","lotus","pearls":
			for i in range(5):
				var a=i*TAU/5
				Models.sphere(head,Vector3(-0.235+cos(a)*0.051,0.17+sin(a)*0.049,-0.06),Vector3(0.063,0.063,0.021),Color("f2e4d0"))
			Models.sphere(head,Vector3(-0.235,0.17,-0.08),Vector3.ONE*0.045,gold)
		"veil":
			CharacterSculpt._drape(head,Vector3(-0.21,0.15,0.10),Vector3(-0.37,-0.66,0.16),0.035,0.08,color.darkened(0.35),gold)
		"horn":
			for side in [-1,1]: CharacterSculpt.leaf(head,Vector3(side*0.21,0.16,0),Vector3(side*0.30,0.45,0.08),0.039,gold)
		_:
			CharacterSculpt.leaf(head,Vector3(-0.23,0.12,-0.05),Vector3(-0.33,0.34,0.04),0.04,color)
	# Individual signature props are part of the silhouette, not a palette swap.
	if ornament=="fur":
		for i in range(9): Models.sphere(body,Vector3((i-4)*0.069,1.82,0),Vector3(0.12,0.11,0.22),Color("dddbcb"))
	if ornament in ["brush","fan","harp","tuning"]:
		for i in range(3): CharacterSculpt.leaf(body,Vector3(-0.27,1.16,0.02),Vector3(-0.40+i*0.055,0.75,0.03),0.017,gold)
	if ornament=="scarf":
		CharacterSculpt._drape(body,Vector3(0.14,1.87,-0.1),Vector3(0.33,1.28,-0.15),0.065,0.07,color,gold)
	for side in [-1,1]:
		Models.sphere(head,Vector3(side*0.23,-0.11,-0.01),Vector3.ONE*0.026,gold)
		if index in [2,5,8,11,17,20]: CharacterSculpt.leaf(head,Vector3(side*0.23,-0.13,-0.01),Vector3(side*0.24,-0.25,0),0.012,gold,0.007)
