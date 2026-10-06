class_name MarchUnitArt
extends Node3D

# Original, deliberately low-poly battlefield models. All dimensions are local
# to the troop, so age changes never mutate an already recruited character.
var torso_material: StandardMaterial3D
var weapon_joint: Node3D
var legs: Array[Node3D] = []
var facing := 1.0
var moving_time := 0.0
var strike_time := 0.0

func box(at: Vector3, size: Vector3, tint: Color, parent: Node3D = null) -> MeshInstance3D:
	var mount: Node3D = self if parent == null else parent
	return MarchFortress.block(mount, at, size, tint)

func oval(at: Vector3, size: Vector3, tint: Color, parent: Node3D = null) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 8
	shape.rings = 4
	model.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.92
	model.material_override = material
	var mount: Node3D = self if parent == null else parent
	mount.add_child(model)
	model.position = at
	model.scale = size
	return model

func horn(at: Vector3, radius: float, height: float, tint: Color, along_x: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = 0.0
	shape.height = height
	shape.radial_segments = 6
	model.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.86
	model.material_override = material
	var mount: Node3D = self if parent == null else parent
	mount.add_child(model)
	model.position = at
	if along_x:
		model.rotation.z = -facing * PI * 0.5
	return model

func wheel(at: Vector3, radius: float, tint: Color) -> void:
	var model := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius
	shape.height = 0.22
	shape.radial_segments = 8
	model.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.93
	model.material_override = material
	add_child(model)
	model.position = at
	model.rotation.x = PI * 0.5
	oval(at + Vector3(0, 0, 0.13), Vector3(0.22, 0.22, 0.12), tint.lightened(0.27))

func make(which_kind: String, which_side: int, stats: Dictionary, era: int) -> void:
	name = str(stats["title"]) + " Model"
	facing = float(-which_side)
	var human := which_side == -1
	var skin := Color("c0a581") if human else Color("78835e")
	var cloth := Color(str(stats["color"]))
	var leather := Color("664e3d") if human else Color("473c35")
	var metal := Color("b68850") if era == 1 else Color("909da4")
	var bone := Color("e2d4b3")
	var big := which_kind in ["hauler", "brute", "ram", "ram_beast", "ogre_captain"]
	var mounted := which_kind == "warg"
	var torso_y := 1.86 if mounted else (1.35 if big else 1.2)
	var face_y := torso_y + (1.16 if big else 0.92)
	if big:
		scale = Vector3(1.17, 1.12, 1.17)
	if which_kind == "ogre_captain":
		scale = Vector3(1.55, 1.52, 1.55)
	var torso := box(Vector3(0, torso_y, 0), Vector3(1.15 if big else 0.83, 1.16 if big else 1.08, 0.76), cloth)
	torso_material = torso.material_override as StandardMaterial3D
	oval(Vector3(0, face_y, 0), Vector3(0.94 if big else 0.71, 0.93 if big else 0.74, 0.76 if big else 0.67), skin)
	for z in [-0.18, 0.18]:
		oval(Vector3(facing * (0.45 if big else 0.34), face_y + 0.06, z), Vector3(0.11, 0.11, 0.1), Color("202322") if human else Color("d5a15b"))
	if not human:
		for z in [-0.22, 0.22]:
			horn(Vector3(facing * 0.31, face_y - 0.31, z), 0.105, 0.34, bone)
	for z in [-0.26, 0.26]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0, 0.76 if not mounted else 1.15, z)
		add_child(pivot)
		box(Vector3(0, -0.34, 0), Vector3(0.32 if not big else 0.4, 0.68, 0.3), leather, pivot)
		box(Vector3(facing * 0.09, -0.68, 0.04), Vector3(0.45, 0.2, 0.33), leather.darkened(0.23), pivot)
		legs.append(pivot)
	for z in [-0.43, 0.43]:
		box(Vector3(0, torso_y + 0.04, z), Vector3(0.34 if big else 0.24, 0.74, 0.26), skin.darkened(0.12))
	box(Vector3(0, torso_y - 0.43, 0.06), Vector3(1.0 if big else 0.78, 0.18, 0.81), leather)
	if era == 0:
		box(Vector3(0, torso_y + 0.08, 0.41), Vector3(0.68, 0.4, 0.14), leather.lightened(0.08))
		box(Vector3(0, torso_y + 0.43, -0.16), Vector3(0.93, 0.27, 0.48), Color("a4977b") if human else bone.darkened(0.28))
	elif era == 1:
		box(Vector3(0, torso_y + 0.08, 0.42), Vector3(0.77, 0.71, 0.15), metal.darkened(0.16))
		box(Vector3(0, torso_y + 0.3, 0.52), Vector3(0.7, 0.12, 0.11), metal.lightened(0.18))
		box(Vector3(0, face_y + 0.31, 0), Vector3(0.84, 0.19, 0.75), metal)
	else:
		box(Vector3(0, torso_y + 0.08, 0.43), Vector3(0.91, 0.84, 0.2), metal.darkened(0.24))
		for y in [torso_y - 0.1, torso_y + 0.15, torso_y + 0.39]:
			box(Vector3(0, y, 0.56), Vector3(0.79, 0.11, 0.08), metal.lightened(0.16))
		box(Vector3(0, face_y + 0.29, 0), Vector3(0.93, 0.31, 0.83), metal)
		box(Vector3(facing * 0.35, face_y + 0.08, 0), Vector3(0.17, 0.13, 0.66), metal.darkened(0.36))
	weapon_joint = Node3D.new()
	weapon_joint.name = "Equipment"
	weapon_joint.position = Vector3(facing * 0.48, torso_y + 0.02, 0.43)
	add_child(weapon_joint)
	match which_kind:
		"hunter": make_hunter(leather, bone, cloth)
		"slinger": make_slinger(leather, bone)
		"hauler": make_hauler(leather, bone)
		"raider": make_raider(leather, bone)
		"thrower": make_thrower(leather, bone)
		"brute": make_brute(leather, bone)
		"shield": make_shield(metal, leather)
		"bowman": make_bowman(metal, leather, bone)
		"ram": make_ram(metal, leather)
		"orc_guard": make_orc_guard(metal, bone)
		"horn_bow": make_horn_bow(metal, leather, bone)
		"ram_beast": make_ram_beast(metal, leather, bone)
		"swordsman": make_swordsman(metal, leather)
		"lancer": make_lancer(metal, leather)
		"torsion": make_torsion(metal, leather)
		"iron_breaker": make_iron_breaker(metal, bone)
		"warg": make_warg(metal, leather, bone)
		"ogre_captain": make_ogre_captain(metal, leather, bone)

func spear(length: float, shaft: Color, point: Color) -> void:
	box(Vector3(facing * length * 0.46, 0, 0), Vector3(length, 0.13, 0.13), shaft, weapon_joint)
	horn(Vector3(facing * (length + 0.04), 0, 0), 0.16, 0.45, point, true, weapon_joint)

func shield(tint: Color, boss: Color, long_shape: bool = false) -> void:
	oval(Vector3(facing * 0.31, 1.47, 0.65), Vector3(0.23, 1.54 if long_shape else 1.21, 1.14), tint)
	oval(Vector3(facing * 0.41, 1.47, 0.77), Vector3(0.16, 0.35, 0.35), boss)

func bow(wood: Color, cord: Color) -> void:
	var handle := box(Vector3(facing * 0.5, 0, 0), Vector3(0.15, 0.65, 0.15), wood, weapon_joint)
	for height in [-0.47, 0.47]:
		var limb := box(Vector3(facing * 0.62, height, 0), Vector3(0.14, 0.65, 0.15), wood, weapon_joint)
		limb.rotation.z = facing * (0.36 if height < 0.0 else -0.36)
	box(Vector3(facing * 0.85, 0, 0), Vector3(0.05, 1.44, 0.05), cord, weapon_joint)
	box(Vector3(facing * 0.91, -0.05, 0.1), Vector3(1.23, 0.055, 0.06), cord, weapon_joint)
	handle.name = "Bow Grip"

func club(wood: Color, head: Color, spiked: bool = false) -> void:
	box(Vector3(facing * 0.67, -0.08, 0), Vector3(1.55, 0.21, 0.23), wood, weapon_joint)
	oval(Vector3(facing * 1.53, -0.07, 0), Vector3(0.63, 0.53, 0.53), head, weapon_joint)
	if spiked:
		for z in [-0.31, 0.31]:
			horn(Vector3(facing * 1.53, 0.03, z), 0.12, 0.38, head.lightened(0.2), false, weapon_joint)

func pack(tint: Color) -> void:
	box(Vector3(-facing * 0.41, 1.35, -0.03), Vector3(0.67, 0.91, 0.76), tint)
	box(Vector3(-facing * 0.44, 1.74, 0.19), Vector3(0.55, 0.15, 0.68), tint.lightened(0.18))

func make_hunter(leather: Color, bone: Color, cloth: Color) -> void:
	spear(1.95, leather, bone)
	box(Vector3(0, 1.61, 0.65), Vector3(0.68, 0.77, 0.11), cloth.darkened(0.3))
	oval(Vector3(-facing * 0.13, 2.64, 0.0), Vector3(0.78, 0.2, 0.77), leather)

func make_slinger(leather: Color, bone: Color) -> void:
	box(Vector3(facing * 0.42, 0.1, 0), Vector3(0.19, 1.12, 0.17), leather, weapon_joint)
	oval(Vector3(facing * 0.4, -0.51, 0), Vector3(0.38, 0.18, 0.29), leather, weapon_joint)
	pack(leather.darkened(0.16))
	oval(Vector3(-facing * 0.58, 1.17, 0.25), Vector3(0.22, 0.2, 0.22), bone)

func make_hauler(leather: Color, bone: Color) -> void:
	club(leather, Color("77756a"))
	pack(Color("766f5f"))
	box(Vector3(0, 2.12, 0.45), Vector3(1.02, 0.22, 0.15), bone)
	box(Vector3(0, 0.88, 0.59), Vector3(1.0, 0.29, 0.12), leather)

func make_raider(leather: Color, bone: Color) -> void:
	spear(1.6, leather, bone)
	for z in [-0.28, 0.28]:
		horn(Vector3(0, 2.75, z), 0.15, 0.55, bone)
	box(Vector3(0, 1.34, 0.58), Vector3(0.62, 0.3, 0.12), bone)

func make_thrower(leather: Color, bone: Color) -> void:
	oval(Vector3(facing * 0.68, 0.08, 0), Vector3(0.46, 0.46, 0.46), Color("65615b"), weapon_joint)
	box(Vector3(facing * 0.28, -0.05, 0), Vector3(0.73, 0.15, 0.17), leather, weapon_joint)
	pack(leather)
	for z in [-0.33, 0.33]:
		box(Vector3(0, 2.57, z), Vector3(0.25, 0.15, 0.22), bone)

func make_brute(leather: Color, bone: Color) -> void:
	club(leather, Color("57534f"), true)
	for z in [-0.52, 0.52]:
		box(Vector3(0, 1.84, z), Vector3(0.47, 0.46, 0.3), bone.darkened(0.25))
	box(Vector3(0, 1.45, 0.55), Vector3(0.98, 0.42, 0.2), leather)

func make_shield(metal: Color, leather: Color) -> void:
	shield(metal, leather.darkened(0.3), true)
	spear(1.4, leather, metal.lightened(0.27))
	box(Vector3(0, 2.61, 0.07), Vector3(0.2, 0.4, 0.83), metal.darkened(0.26))

func make_bowman(metal: Color, leather: Color, bone: Color) -> void:
	bow(leather.lightened(0.1), bone)
	pack(leather)
	for z in [-0.19, 0.19]:
		box(Vector3(-facing * 0.46, 1.85, z), Vector3(0.07, 0.62, 0.06), bone)
	box(Vector3(0, 2.56, 0.02), Vector3(0.83, 0.13, 0.78), metal)

func make_ram(metal: Color, leather: Color) -> void:
	box(Vector3(0, 0.66, 0), Vector3(2.8, 0.28, 1.75), leather)
	for x in [-0.88, 0.88]:
		for z in [-0.92, 0.92]:
			wheel(Vector3(x, 0.47, z), 0.37, leather.darkened(0.25))
	box(Vector3(facing * 0.95, 1.17, 0), Vector3(2.8, 0.35, 0.48), leather.darkened(0.15))
	box(Vector3(facing * 2.4, 1.17, 0), Vector3(0.58, 0.63, 0.58), metal)
	for z in [-0.65, 0.65]:
		box(Vector3(0, 1.56, z), Vector3(0.16, 1.14, 0.16), metal.darkened(0.18))

func make_orc_guard(metal: Color, bone: Color) -> void:
	shield(metal.darkened(0.32), bone, true)
	club(Color("53453c"), metal, true)
	for z in [-0.35, 0.35]:
		horn(Vector3(0, 2.69, z), 0.16, 0.57, bone)

func make_horn_bow(metal: Color, leather: Color, bone: Color) -> void:
	bow(bone.darkened(0.18), leather.lightened(0.34))
	pack(leather)
	for z in [-0.33, 0.33]:
		horn(Vector3(0, 2.65, z), 0.14, 0.45, metal)

func make_ram_beast(metal: Color, leather: Color, bone: Color) -> void:
	oval(Vector3(0, 0.81, 0), Vector3(2.18, 0.93, 1.12), Color("55564a"))
	for x in [-0.68, 0.68]:
		for z in [-0.4, 0.4]:
			box(Vector3(x, 0.35, z), Vector3(0.29, 0.65, 0.27), Color("44483e"))
	oval(Vector3(facing * 1.21, 1.02, 0), Vector3(0.82, 0.62, 0.75), Color("68634f"))
	for z in [-0.42, 0.42]:
		horn(Vector3(facing * 1.48, 1.39, z), 0.2, 0.67, bone)
	box(Vector3(facing * 1.0, 0.78, 0), Vector3(2.65, 0.28, 0.47), leather)
	box(Vector3(facing * 2.4, 0.78, 0), Vector3(0.52, 0.62, 0.56), metal)

func make_swordsman(metal: Color, leather: Color) -> void:
	shield(Color("607b8a"), metal.lightened(0.21), true)
	box(Vector3(facing * 0.8, -0.03, 0), Vector3(1.84, 0.25, 0.13), metal.lightened(0.3), weapon_joint)
	box(Vector3(facing * 0.13, -0.03, 0), Vector3(0.15, 0.62, 0.16), leather, weapon_joint)
	box(Vector3(0, 0.91, 0.35), Vector3(0.94, 0.37, 0.4), metal.darkened(0.27))

func make_lancer(metal: Color, leather: Color) -> void:
	spear(2.6, metal.darkened(0.19), metal.lightened(0.33))
	shield(Color("6b7b86"), metal)
	box(Vector3(0, 2.74, 0), Vector3(0.19, 0.46, 0.89), Color("536c7d"))
	box(Vector3(0, 1.2, 0.51), Vector3(0.55, 0.67, 0.14), leather)

func make_torsion(metal: Color, leather: Color) -> void:
	box(Vector3(0, 0.62, 0), Vector3(2.93, 0.31, 1.75), leather)
	for z in [-0.97, 0.97]:
		wheel(Vector3(-facing * 0.25, 0.55, z), 0.46, metal.darkened(0.35))
	box(Vector3(facing * 1.06, 1.11, 0), Vector3(3.12, 0.24, 0.21), metal)
	horn(Vector3(facing * 2.73, 1.11, 0), 0.24, 0.52, metal.lightened(0.32), true)
	for z in [-0.7, 0.7]:
		var arm := box(Vector3(-facing * 0.17, 1.17, z), Vector3(0.27, 1.29, 0.2), leather)
		arm.rotation.x = 0.17 if z < 0.0 else -0.17

func make_iron_breaker(metal: Color, bone: Color) -> void:
	shield(metal.darkened(0.36), metal, true)
	club(Color("4c4140"), metal.darkened(0.13), true)
	for z in [-0.51, 0.51]:
		horn(Vector3(0, 1.96, z), 0.22, 0.63, metal)
	box(Vector3(0, 1.09, 0.44), Vector3(0.85, 0.4, 0.12), bone.darkened(0.45))

func make_warg(metal: Color, leather: Color, bone: Color) -> void:
	oval(Vector3(0, 0.81, 0), Vector3(2.23, 0.93, 1.1), Color("363933"))
	for x in [-0.79, 0.79]:
		for z in [-0.4, 0.4]:
			box(Vector3(x, 0.3, z), Vector3(0.28, 0.58, 0.25), Color("30312f"))
	oval(Vector3(facing * 1.27, 0.94, 0), Vector3(0.78, 0.61, 0.64), Color("494a40"))
	for z in [-0.21, 0.21]:
		horn(Vector3(facing * 1.62, 0.63, z), 0.11, 0.28, bone)
	box(Vector3(0, 1.09, 0), Vector3(1.03, 0.19, 0.99), leather)
	spear(1.58, leather, metal)

func make_ogre_captain(metal: Color, leather: Color, bone: Color) -> void:
	club(leather, metal, true)
	shield(metal.darkened(0.36), bone)
	for z in [-0.34, 0.34]:
		horn(Vector3(0, 3.05, z), 0.23, 0.79, bone)
	box(Vector3(0, 1.66, 0.6), Vector3(1.12, 0.48, 0.18), metal.lightened(0.09))
	box(Vector3(-facing * 0.4, 2.4, -0.39), Vector3(0.26, 1.23, 0.26), leather)
	box(Vector3(-facing * 0.4, 3.04, 0.02), Vector3(0.13, 0.48, 0.68), Color("a44b39"))

func march(delta: float, phase: float) -> void:
	moving_time = maxf(0.0, moving_time - delta)
	strike_time = maxf(0.0, strike_time - delta)
	var stride := minf(1.0, moving_time * 6.0)
	position.y = sin(phase) * 0.035 * stride
	for index in legs.size():
		var leg: Node3D = legs[index]
		leg.rotation.z = sin(phase + float(index) * PI) * 0.26 * stride
	weapon_joint.rotation.z = facing * sin(phase * 0.5) * 0.045 - facing * strike_time * 2.3

func moved() -> void:
	moving_time = 0.18

func impact() -> void:
	strike_time = 0.2
