class_name OgreWarSiegeVisual
extends Node3D

# Castlehold-first siege visuals. The machines are new Ogre War assemblies,
# but their surface treatment, crew models, contact shadow and animation logic
# are reused from Castlehold so the remaining siege units no longer fall back
# to the old cube-built character renderer.
const OAK_ALBEDO := "res://assets/castlehold/materials/oak_albedo.png"
const OAK_NORMAL := "res://assets/castlehold/materials/oak_normal.png"
const SHADOW := "res://assets/castlehold/materials/contact_shadow.png"

var kind := "ram"
var side := -1
var machine: Node3D
var crew: Array[Node3D] = []
var crew_animators: Array[AnimationPlayer] = []
var wheels: Array[MeshInstance3D] = []
var ram_beam: Node3D
var torsion_arm: Node3D
var moving_time := 0.0
var attack_time := 0.0
var wheel_phase := 0.0
var oak: StandardMaterial3D
var dark_oak: StandardMaterial3D
var metal: StandardMaterial3D
var rope: StandardMaterial3D
var canvas: StandardMaterial3D

func make(which_kind: String, which_side: int) -> void:
	kind = which_kind
	side = which_side
	name = "Castlehold-Derived " + ("Bronze Ram" if kind == "ram" else "Torsion Engine")
	_build_materials()
	machine = Node3D.new()
	machine.name = "Siege Machine"
	add_child(machine)
	if kind == "ram":
		_build_ram()
	else:
		_build_torsion()
	_make_contact_shadow()

func _build_materials() -> void:
	oak = StandardMaterial3D.new()
	oak.albedo_color = Color("8b6847")
	oak.albedo_texture = load(OAK_ALBEDO)
	oak.normal_enabled = true
	oak.normal_texture = load(OAK_NORMAL)
	oak.normal_scale = 0.34
	oak.roughness = 0.84
	oak.uv1_triplanar = true
	oak.uv1_world_triplanar = true
	oak.uv1_scale = Vector3.ONE * 1.7
	oak.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	dark_oak = oak.duplicate() as StandardMaterial3D
	dark_oak.albedo_color = Color("54402f")
	metal = StandardMaterial3D.new()
	metal.albedo_color = Color("a77d48") if kind == "ram" else Color("858f94")
	metal.metallic = 0.68
	metal.roughness = 0.38
	rope = StandardMaterial3D.new()
	rope.albedo_color = Color("a68d62")
	rope.roughness = 0.94
	canvas = StandardMaterial3D.new()
	canvas.albedo_color = Color("696957") if side == 1 else Color("706f61")
	canvas.roughness = 0.98

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = at
	return node

func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, along_z: bool = false, along_x: bool = false, sides: int = 12) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = at
	if along_z:
		node.rotation.x = PI * 0.5
	elif along_x:
		node.rotation.z = PI * 0.5
	return node

func _cone(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, along_x: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = 0.0
	mesh.height = height
	mesh.radial_segments = 10
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = at
	if along_x:
		node.rotation.z = -float(side) * PI * 0.5
	return node

func _wheel(at: Vector3, radius: float) -> void:
	var wheel := _cylinder(machine, at, radius, 0.24, dark_oak, true, false, 14)
	wheels.append(wheel)
	_cylinder(machine, at + Vector3(0, 0, 0.14), radius * 0.18, 0.31, metal, true, false, 10)
	for spoke in 8:
		var angle := float(spoke) * TAU / 8.0
		var spoke_node := _box(wheel, Vector3(cos(angle) * radius * 0.43, sin(angle) * radius * 0.43, 0), Vector3(radius * 0.74, 0.07, 0.06), oak)
		spoke_node.rotation.z = angle

func _crew_model(model_name: String, at: Vector3, scale_factor: float, yaw_offset: float = 0.0) -> void:
	var packed := load("res://assets/castlehold/characters/%s.gltf" % model_name) as PackedScene
	if packed == null:
		return
	var model := packed.instantiate() as Node3D
	machine.add_child(model)
	model.position = at
	model.scale = Vector3.ONE * scale_factor
	model.rotation.y = (PI * 0.5 if side == 1 else -PI * 0.5) + yaw_offset
	var refinement_kind := _crew_refinement_kind(model_name)
	var refinement_era := 1 if kind == "ram" else 2
	OgreWarUnitRefinement.apply(model, refinement_kind, side, refinement_era)
	crew.append(model)
	var animator := _find_animator(model)
	if animator != null:
		for clip in ["idle", "walk", "run"]:
			if animator.has_animation(clip):
				animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		animator.play("idle")
		crew_animators.append(animator)


func _crew_refinement_kind(model_name: String) -> String:
	if model_name == "archer":
		return "bowman"
	if model_name == "enemy_archer":
		return "horn_bow"
	if model_name == "spearman":
		return "hunter"
	if model_name == "raider":
		return "raider"
	if model_name == "orc_guard":
		return "orc_guard"
	return "shield" if side == -1 else "orc_guard"

func _find_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_animator(child)
		if result != null:
			return result
	return null

func _build_ram() -> void:
	# Four-wheeled roofed frame, suspended Castlehold-oak ram and bronze beak.
	_box(machine, Vector3(0, 0.86, 0), Vector3(3.8, 0.30, 2.25), oak)
	for x in [-1.38, 1.38]:
		for z in [-1.05, 1.05]:
			_wheel(Vector3(x, 0.44, z), 0.48)
	for x in [-1.45, 1.45]:
		for z in [-0.82, 0.82]:
			_box(machine, Vector3(x, 1.72, z), Vector3(0.22, 1.75, 0.22), dark_oak)
	_box(machine, Vector3(0, 2.58, -0.92), Vector3(3.45, 0.18, 0.28), oak)
	_box(machine, Vector3(0, 2.58, 0.92), Vector3(3.45, 0.18, 0.28), oak)
	for z in [-0.83, 0.0, 0.83]:
		var roof_board := _box(machine, Vector3(0, 2.87, z), Vector3(3.95, 0.14, 0.78), canvas)
		roof_board.rotation.z = 0.055 * float(side)
	for x in [-0.86, 0.86]:
		_cylinder(machine, Vector3(x, 2.04, 0), 0.045, 1.56, rope, false, false, 7)
	ram_beam = Node3D.new()
	ram_beam.name = "Suspended Ram"
	machine.add_child(ram_beam)
	_cylinder(ram_beam, Vector3(float(-side) * 0.25, 1.63, 0), 0.18, 4.15, dark_oak, false, true, 12)
	_cone(ram_beam, Vector3(float(-side) * 2.46, 1.63, 0), 0.34, 0.82, metal, true)
	for x in [-0.92, 0.92]:
		_box(ram_beam, Vector3(x, 1.63, 0), Vector3(0.10, 0.62, 0.10), metal)
	# Bronze side plates, rope lashings and a small faction pennant keep the ram from reading as a bare frame.
	for z in [-1.10, 1.10]:
		_box(machine, Vector3(0.0, 1.76, z), Vector3(2.35, 0.62, 0.10), metal)
		for x in [-0.82, 0.0, 0.82]:
			_cylinder(machine, Vector3(x, 1.76, z * 1.02), 0.035, 0.74, rope, false, false, 7)
	var ram_flag := _box(machine, Vector3(float(side) * 1.15, 2.52, 0), Vector3(0.08, 0.78, 0.66), canvas)
	ram_flag.rotation.z = float(side) * 0.06
	_crew_model("swordsman" if side == -1 else "orc_guard", Vector3(float(side) * 0.55, 0.02, -0.50), 0.82)
	_crew_model("spearman" if side == -1 else "raider", Vector3(float(side) * 0.58, 0.02, 0.54), 0.80)

func _build_torsion() -> void:
	# Wheeled Castlehold-oak ballista with iron torsion frame and reused archer crew.
	_box(machine, Vector3(0, 0.72, 0), Vector3(3.25, 0.32, 2.05), oak)
	for x in [-1.05, 1.05]:
		for z in [-0.94, 0.94]:
			_wheel(Vector3(x, 0.39, z), 0.43)
	_box(machine, Vector3(float(-side) * 0.30, 1.42, 0), Vector3(3.75, 0.24, 0.34), dark_oak)
	_box(machine, Vector3(float(side) * 1.20, 1.46, 0), Vector3(0.42, 1.65, 1.85), oak)
	for z in [-0.72, 0.72]:
		_cylinder(machine, Vector3(float(side) * 1.16, 1.48, z), 0.20, 0.44, rope, true, false, 10)
	torsion_arm = Node3D.new()
	torsion_arm.name = "Torsion Arms"
	machine.add_child(torsion_arm)
	for z in [-0.72, 0.72]:
		var arm := _box(torsion_arm, Vector3(float(-side) * 0.18, 1.93, z), Vector3(2.30, 0.18, 0.18), oak)
		arm.rotation.y = float(side) * (0.32 if z < 0.0 else -0.32)
		_cylinder(torsion_arm, Vector3(float(-side) * 1.30, 1.93, z * 0.66), 0.05, 1.45, rope, true, false, 7)
	_cylinder(machine, Vector3(float(-side) * 1.45, 1.47, 0), 0.065, 2.85, metal, false, true, 8)
	_cone(machine, Vector3(float(-side) * 3.04, 1.47, 0), 0.13, 0.46, metal, true)
	_cylinder(machine, Vector3(float(side) * 1.32, 1.35, 0), 0.34, 0.42, metal, true, false, 12)
	# Iron reinforcing straps, spare bolts and side screens make the torsion engine read as late-age siege equipment.
	for z in [-0.92, 0.92]:
		_box(machine, Vector3(0.0, 1.12, z), Vector3(2.55, 0.10, 0.12), metal)
	for bolt_index in 3:
		var bolt_z := -0.54 + float(bolt_index) * 0.54
		_cylinder(machine, Vector3(float(side) * 0.92, 1.03, bolt_z), 0.028, 1.75, metal, false, true, 7)
		_cone(machine, Vector3(float(-side) * 0.05, 1.03, bolt_z), 0.075, 0.25, metal, true)
	for z in [-0.86, 0.86]:
		_box(machine, Vector3(float(side) * 0.36, 1.72, z), Vector3(0.85, 0.82, 0.10), canvas)
	_crew_model("archer" if side == -1 else "enemy_archer", Vector3(float(side) * 0.56, 0.04, -0.58), 0.78)
	_crew_model("swordsman" if side == -1 else "orc_guard", Vector3(float(side) * 0.82, 0.04, 0.63), 0.75)

func _make_contact_shadow() -> void:
	var shadow := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.5, 2.8)
	shadow.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(SHADOW)
	material.albedo_color = Color(1, 1, 1, 0.56)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shadow.material_override = material
	shadow.position.y = 0.025
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)

func march(delta: float, _phase: float) -> void:
	moving_time = maxf(0.0, moving_time - delta)
	attack_time = maxf(0.0, attack_time - delta)
	if moving_time > 0.0:
		wheel_phase += delta * 4.7
		for wheel in wheels:
			wheel.rotation.z = wheel_phase * float(-side)
	for animator in crew_animators:
		if attack_time > 0.0:
			continue
		var wanted := "run" if moving_time > 0.0 else "idle"
		if animator.current_animation != wanted and animator.has_animation(wanted):
			animator.speed_scale = 0.92 if kind == "ram" else 0.88
			animator.play(wanted, 0.08)
	# Phase 7 gives each siege machine a readable mechanical cycle. The ram pulls
	# back before the strike; the torsion engine visibly winds, snaps and recoils.
	if is_instance_valid(ram_beam):
		var p := clampf(1.0 - attack_time / 0.58, 0.0, 1.0) if attack_time > 0.0 else 1.0
		var ram_offset := 0.0
		if attack_time > 0.0 and p < 0.40:
			ram_offset = -smoothstep(0.0, 0.40, p) * 0.25
		elif attack_time > 0.0:
			var release_p := clampf((p - 0.40) / 0.60, 0.0, 1.0)
			ram_offset = -0.25 * (1.0 - release_p) + sin(release_p * PI) * 0.62
		ram_beam.position.x = float(-side) * ram_offset
	if is_instance_valid(torsion_arm):
		var p := clampf(1.0 - attack_time / 0.66, 0.0, 1.0) if attack_time > 0.0 else 1.0
		var twist := 0.0
		if attack_time > 0.0 and p < 0.58:
			twist = smoothstep(0.0, 0.58, p) * 0.26
		elif attack_time > 0.0:
			var snap_p := clampf((p - 0.58) / 0.42, 0.0, 1.0)
			twist = 0.26 * (1.0 - snap_p) - sin(snap_p * PI) * 0.12
		torsion_arm.rotation.y = float(side) * twist
		machine.position.x = float(side) * (0.07 * sin(maxf(0.0, p - 0.58) / 0.42 * PI) if attack_time > 0.0 and p >= 0.58 else 0.0)

func moved() -> void:
	moving_time = 0.20

func impact() -> void:
	attack_time = 0.58 if kind == "ram" else 0.66
	for animator in crew_animators:
		var clip := "attack_a" if kind == "ram" else "shoot"
		if animator.has_animation(clip):
			animator.speed_scale = 0.82 if kind == "ram" else 0.92
			animator.play(clip, 0.06)

func hurt() -> void:
	for animator in crew_animators:
		if animator.has_animation("hit"):
			animator.play("hit", 0.04)

func defeat() -> void:
	for animator in crew_animators:
		if animator.has_animation("defeat"):
			animator.play("defeat", 0.04)
