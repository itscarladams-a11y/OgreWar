class_name MarchFortress
extends Node3D

const GATE_MAX := 570.0
const KEEP_MAX := 920.0

var side := 1
var age := 0
var gate_hp := GATE_MAX
var keep_hp := KEEP_MAX
var gate_mesh: MeshInstance3D
var keep_mesh: MeshInstance3D
var architecture: Node3D
var gate_tint := Color("6b5140")
var keep_tint := Color("a6a393")
var gate_height := 3.4
var gate_x: float:
	get: return position.x - side * 6.0
var keep_x: float:
	get: return position.x

static func block(parent: Node3D, at: Vector3, dimensions: Vector3, tint: Color) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	model.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.96
	model.material_override = material
	parent.add_child(model)
	model.position = at
	return model

func build(which_side: int) -> void:
	side = which_side
	name = "Human Castle" if side == -1 else "Ogre Stronghold"
	rebuild_architecture()

func set_age(new_age: int) -> void:
	if new_age != age + 1 or new_age > 2:
		return
	age = new_age
	rebuild_architecture()

func rebuild_architecture() -> void:
	# Swap the whole age model so later eras have their own silhouette and draw cost.
	if is_instance_valid(architecture):
		remove_child(architecture)
		architecture.queue_free()
	architecture = Node3D.new()
	architecture.name = ("Human " if side == -1 else "Ogre ") + str(["Stone Bailey", "Bronze Castle", "Iron Citadel"][age])
	add_child(architecture)
	if side == -1:
		build_human()
	else:
		build_ogre()
	refresh()

static func round_tower(parent: Node3D, at: Vector3, radius: float, height: float, tint: Color) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.top_radius = radius
	cylinder_mesh.height = height
	cylinder_mesh.radial_segments = 10
	model.mesh = cylinder_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.96
	model.material_override = material
	parent.add_child(model)
	model.position = at
	return model

func roof(x: float, y: float, z: float, width: float, depth: float, tint: Color) -> void:
	# A pair of sloped slate or timber planes, pitched across the castle frontage.
	for side_of_roof in [-1.0, 1.0]:
		var plane := block(architecture, Vector3(x, y, z + side_of_roof * depth * 0.26), Vector3(width, 0.28, depth * 0.58), tint)
		plane.rotation.x = side_of_roof * 0.42

func banner(x: float, y: float, z: float, pole: Color, cloth: Color) -> void:
	block(architecture, Vector3(x, y + 1.0, z), Vector3(0.12, 2.5, 0.12), pole)
	block(architecture, Vector3(x, y + 1.58, z + 0.38), Vector3(0.11, 0.72, 0.72), cloth)

func make_gate(height: float, width: float, timber: Color, fittings: Color, crude: bool) -> void:
	var front := float(-side)
	gate_height = height
	gate_tint = timber
	gate_mesh = block(architecture, Vector3(front * 6.0, height * 0.5, 0), Vector3(0.85, height, width), timber)
	var face := front * 0.5
	for z in [-2.35, -1.18, 0.0, 1.18, 2.35]:
		block(gate_mesh, Vector3(face, 0, z), Vector3(0.13, height * 0.88, 0.14), fittings)
	for y_fraction in [-0.28, 0.27]:
		block(gate_mesh, Vector3(face + front * 0.08, y_fraction * height, 0), Vector3(0.16, 0.2 if crude else 0.13, width * 0.91), fittings)
	if crude:
		for z in [-1.9, 1.9]:
			var spar := block(gate_mesh, Vector3(face + front * 0.14, 0, z), Vector3(0.2, height * 0.82, 0.21), fittings.lightened(0.12))
			spar.rotation.x = -0.28 if z < 0.0 else 0.28
	else:
		block(gate_mesh, Vector3(face + front * 0.18, 0.0, 0), Vector3(0.12, 0.44, 0.28), fittings.lightened(0.3))

func human_arch(height: float, stone: Color) -> void:
	var front := float(-side)
	for z in [-3.35, 3.35]:
		block(architecture, Vector3(front * 6.07, height * 0.5, z), Vector3(1.55, height, 0.82), stone)
	for z in [-2.6, -1.3, 0.0, 1.3, 2.6]:
		var rise := 0.52 - absf(z) * 0.12
		block(architecture, Vector3(front * 6.08, height + rise, z), Vector3(1.62, 0.72, 1.26), stone.lightened(0.08 if z == 0.0 else 0.0))

func human_arrow_slits(x: float, height: float, half_width: float) -> void:
	var front := float(-side)
	for z in [-half_width, 0.0, half_width]:
		block(architecture, Vector3(x + front * 0.08, height, z), Vector3(0.12, 0.82, 0.16), Color("22262a"))

func build_human() -> void:
	var front := float(-side)
	var pale := Color("aba99b") if age == 0 else (Color("b5b3a4") if age == 1 else Color("c2c0b2"))
	var shadow := pale.darkened(0.17)
	var wood := Color("765e48")
	var slate := Color("58646c") if age < 2 else Color("424d56")
	var metal := Color("9f8b66") if age == 1 else Color("87949a")
	var wall_height := 3.3 + float(age) * 0.7
	# Continuous ordered curtain walls and a deliberately readable central gate.
	for z in [-5.65, 5.65]:
		block(architecture, Vector3(front * 7.4, wall_height * 0.5, z), Vector3(1.1, wall_height, 5.1), shadow)
		block(architecture, Vector3(front * 7.52, 0.38, z), Vector3(1.5, 0.75, 5.4), pale)
		for seam in [-1.6, 0.0, 1.6]:
			block(architecture, Vector3(front * 8.01, 1.65, z + seam), Vector3(0.06, 0.08, 1.0), pale.lightened(0.11))
		if age == 2:
			for merlon in [-1.8, -0.6, 0.6, 1.8]:
				block(architecture, Vector3(front * 7.38, wall_height + 0.42, z + merlon), Vector3(1.25, 0.85, 0.52), pale)
	make_gate(3.4 + float(age) * 0.4, 6.3, wood.darkened(0.12), metal if age > 0 else wood.lightened(0.2), false)
	human_arch(gate_height, pale)
	# Twin towers become dressed square masonry and then cylindrical iron-age towers.
	for z in [-5.35, 5.35]:
		var tower_height := 4.8 + float(age) * 1.45
		if age == 2:
			round_tower(architecture, Vector3(front * 6.0, tower_height * 0.5, z), 1.95, tower_height, shadow)
			round_tower(architecture, Vector3(front * 6.0, tower_height + 0.16, z), 2.18, 0.44, pale)
			for tooth in [-1.45, -0.48, 0.48, 1.45]:
				block(architecture, Vector3(front * 6.0, tower_height + 0.6, z + tooth), Vector3(1.1, 0.72, 0.42), pale)
		else:
			block(architecture, Vector3(front * 6.0, tower_height * 0.5, z), Vector3(3.2, tower_height, 3.1), pale)
			block(architecture, Vector3(front * 6.0, tower_height + 0.12, z), Vector3(3.6, 0.35, 3.5), shadow)
			if age == 0:
				roof(front * 6.0, tower_height + 0.77, z, 3.7, 3.6, slate)
			else:
				for tooth in [-1.16, 0.0, 1.16]:
					block(architecture, Vector3(front * 6.0, tower_height + 0.6, z + tooth), Vector3(0.7, 0.8, 0.48), pale)
		human_arrow_slits(front * 7.72, tower_height * 0.65, 0.95)
	# Keep changes form with each era, while its HP continues uninterrupted.
	var keep_height := 5.4 + float(age) * 1.6
	var keep_face := front * ((5.7 + float(age) * 0.7) * 0.5)
	keep_tint = pale
	keep_mesh = block(architecture, Vector3(0, keep_height * 0.5, 0), Vector3(5.7 + float(age) * 0.7, keep_height, 8.2 + float(age) * 0.6), pale)
	block(architecture, Vector3(keep_face + front * 0.2, 0.53, 0), Vector3(0.4, 1.0, 9.0 + float(age) * 0.6), shadow)
	for z in [-3.3, 3.3]:
		block(architecture, Vector3(keep_face + front * 0.2, keep_height * 0.5, z), Vector3(0.38, keep_height - 0.6, 0.55), shadow)
	for z in [-2.0, 0.0, 2.0]:
		block(architecture, Vector3(keep_face + front * 0.13, keep_height * 0.66, z), Vector3(0.12, 0.93, 0.22), Color("292f34"))
	if age == 0:
		for z in [-3.0, 0.0, 3.0]:
			block(architecture, Vector3(keep_face + front * 0.22, 3.0, z), Vector3(0.14, 4.6, 0.22), wood)
		roof(0, keep_height + 0.9, 0, 6.45, 9.1, slate)
	elif age == 1:
		block(architecture, Vector3(0, keep_height + 0.2, 0), Vector3(6.8, 0.48, 9.25), shadow)
		roof(0, keep_height + 1.08, 0, 7.2, 9.6, slate)
		banner(front * 2.9, keep_height + 0.38, -3.4, metal, Color("657d91"))
	else:
		block(architecture, Vector3(0, keep_height + 0.16, 0), Vector3(7.5, 0.48, 10.2), shadow)
		for z in [-4.5, -2.25, 0.0, 2.25, 4.5]:
			block(architecture, Vector3(front * 3.4, keep_height + 0.65, z), Vector3(0.75, 0.82, 0.58), pale)
		roof(0, keep_height + 1.28, 0, 7.45, 10.0, slate)
		banner(front * 3.25, keep_height + 1.0, -3.55, metal, Color("476880"))
		banner(front * 3.25, keep_height + 1.0, 3.55, metal, Color("476880"))

func ogre_rubble(at: Vector3, size: Vector3, tint: Color, tilt: float) -> void:
	var stone := block(architecture, at, size, tint)
	stone.rotation.x = tilt

func ogre_spike(x: float, y: float, z: float, iron: Color, tilt: float) -> void:
	var spike := block(architecture, Vector3(x, y, z), Vector3(0.48, 2.0, 0.48), iron)
	spike.rotation.x = tilt

func build_ogre() -> void:
	var front := float(-side)
	var basalt := Color("49454a") if age == 0 else (Color("39383f") if age == 1 else Color("292b32"))
	var iron := Color("555159") if age == 0 else (Color("856c53") if age == 1 else Color("66666d"))
	var timber := Color("40312d")
	var ember := Color("c36d4c")
	var mass := 4.9 + float(age) * 1.1
	# Large uneven masonry and slanting buttresses form a separate faction silhouette.
	for z in [-6.2, 6.2]:
		ogre_rubble(Vector3(front * 6.95, mass * 0.5, z), Vector3(2.65, mass, 5.15), basalt, -0.045 if z < 0.0 else 0.04)
		for index in 3:
			var band_z: float = z + float(index - 1) * 1.45
			ogre_rubble(Vector3(front * 8.35, 1.0 + float(index % 2) * 1.25, band_z), Vector3(0.32, 1.6, 1.28), basalt.lightened(0.09), 0.08 if index == 1 else -0.06)
		ogre_spike(front * 6.8, mass + 0.62, z, iron, 0.32 if z < 0.0 else -0.32)
	make_gate(3.65 + float(age) * 0.48, 6.4, timber.darkened(0.22), iron, true)
	# Ogre gate lintel is a heavy broken monolith rather than a dressed arch.
	for z in [-3.6, 3.6]:
		ogre_rubble(Vector3(front * 6.1, 2.35, z), Vector3(1.8, 4.7, 1.38), basalt.lightened(0.04), 0.08 if z < 0.0 else -0.08)
	ogre_rubble(Vector3(front * 6.0, gate_height + 0.54, 0), Vector3(2.3, 1.0, 8.75), basalt, -0.025)
	for z in [-6.2, 6.2]:
		var tower_height := 6.1 + float(age) * 1.85
		ogre_rubble(Vector3(front * 6.1, tower_height * 0.5, z), Vector3(4.05, tower_height, 3.65), basalt.darkened(0.12), 0.045 if z < 0.0 else -0.035)
		ogre_rubble(Vector3(front * 6.2, tower_height + 0.02, z), Vector3(4.7, 0.68, 4.1), basalt.lightened(0.06), -0.08 if z < 0.0 else 0.09)
		for tooth in [-1.35, 0.25, 1.45]:
			ogre_spike(front * 7.0, tower_height + 1.05, z + tooth, iron, 0.34 if tooth < 0.0 else -0.2)
		block(architecture, Vector3(front * 8.24, tower_height * 0.64, z), Vector3(0.14, 1.1, 0.45), ember.darkened(0.24))
	var keep_height := 7.0 + float(age) * 1.7
	var keep_face := front * ((7.0 + float(age) * 0.7) * 0.5)
	keep_tint = basalt.darkened(0.08)
	keep_mesh = block(architecture, Vector3(0, keep_height * 0.5, 0), Vector3(7.0 + float(age) * 0.7, keep_height, 10.25 + float(age) * 0.75), keep_tint)
	for z in [-4.1, 4.1]:
		ogre_rubble(Vector3(keep_face + front * 0.42, keep_height * 0.43, z), Vector3(1.5, keep_height * 0.88, 1.75), basalt.lightened(0.05), 0.085 if z < 0.0 else -0.085)
	for z in [-2.7, 0.0, 2.7]:
		block(architecture, Vector3(keep_face + front * 0.18, keep_height * 0.57, z), Vector3(0.2, 1.15, 0.52), ember)
		block(architecture, Vector3(keep_face + front * 0.33, keep_height * 0.57, z), Vector3(0.09, 0.6, 0.28), Color("e29a64"))
	if age == 0:
		for z in [-3.7, 3.7]:
			ogre_spike(front * 2.6, keep_height + 0.65, z, timber, 0.28 if z < 0.0 else -0.26)
	elif age == 1:
		for z in [-4.0, -1.3, 1.3, 4.0]:
			ogre_rubble(Vector3(front * 2.6, keep_height + 0.68, z), Vector3(1.1, 1.6, 1.1), iron, 0.16 if z < 0.0 else -0.16)
		ogre_spike(front * 1.0, keep_height + 1.7, 0, iron, 0.0)
	else:
		ogre_rubble(Vector3(0, keep_height + 0.35, 0), Vector3(8.4, 0.85, 12.0), basalt.lightened(0.08), 0.0)
		for z in [-4.8, -2.45, 0.0, 2.45, 4.8]:
			ogre_spike(front * 3.4, keep_height + 1.35, z, iron, 0.22 if z < 0.0 else -0.22)
		for z in [-3.9, 3.9]:
			ogre_rubble(Vector3(front * 1.4, keep_height + 2.05, z), Vector3(1.85, 3.6, 1.7), basalt, 0.12 if z < 0.0 else -0.13)
			ogre_spike(front * 1.4, keep_height + 4.2, z, iron, 0.28 if z < 0.0 else -0.28)

func damage_gate(amount: float) -> void:
	if gate_hp <= 0.0:
		return
	gate_hp = maxf(0.0, gate_hp - amount)
	refresh()

func damage_keep(amount: float) -> void:
	if gate_hp > 0.0 or keep_hp <= 0.0:
		return
	keep_hp = maxf(0.0, keep_hp - amount)
	refresh()

func repair_gate(amount: float) -> bool:
	if gate_hp <= 0.0 or gate_hp >= GATE_MAX:
		return false
	gate_hp = minf(GATE_MAX, gate_hp + amount)
	refresh()
	return true

func refresh() -> void:
	if not is_instance_valid(gate_mesh):
		return
	var gate_fraction := gate_hp / GATE_MAX
	gate_mesh.scale.y = maxf(0.04, gate_fraction)
	gate_mesh.position.y = maxf(0.08, gate_height * 0.5 * gate_fraction)
	var gate_material: StandardMaterial3D = gate_mesh.material_override as StandardMaterial3D
	gate_material.albedo_color = gate_tint.lerp(Color("242425"), 1.0 - gate_fraction)
	var keep_fraction := keep_hp / KEEP_MAX
	var keep_material: StandardMaterial3D = keep_mesh.material_override as StandardMaterial3D
	keep_material.albedo_color = keep_tint.lerp(Color("25272a"), 1.0 - keep_fraction)
