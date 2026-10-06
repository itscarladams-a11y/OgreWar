class_name OgreWarUnitRefinement
extends RefCounted

# Runtime refinement layer for Castlehold's rigged Ogre War characters.
# The base Castlehold mesh/rig/animations stay intact; age/faction equipment is
# attached to named bones so added detail follows the existing animation clips.

const OAK_ALBEDO := "res://assets/castlehold/materials/oak_albedo.png"
const OAK_NORMAL := "res://assets/castlehold/materials/oak_normal.png"
const SANDSTONE_ALBEDO := "res://assets/castlehold/materials/sandstone_albedo.png"
const SANDSTONE_NORMAL := "res://assets/castlehold/materials/sandstone_normal.png"
const SLATE_ALBEDO := "res://assets/castlehold/materials/slate_albedo.png"
const SLATE_NORMAL := "res://assets/castlehold/materials/slate_normal.png"
const GEAR_ROOT := "res://assets/ogre_modern/phase6/gear/"
const PHASE9_GEAR_ROOT := "res://assets/ogre_modern/phase9/gear/"

static var gear_mesh_cache: Dictionary = {}

static var material_cache: Dictionary = {}

static func apply(model_root: Node3D, kind: String, side: int, era: int) -> void:
	if not is_instance_valid(model_root):
		return
	var skeleton := _find_skeleton(model_root)
	if skeleton == null:
		return
	for child in skeleton.get_children():
		if str(child.name).begins_with("OgreWarRefine"):
			child.queue_free()
	var layer := Node3D.new()
	layer.name = "OgreWarRefine Fallback Layer"
	skeleton.add_child(layer)
	if side == -1:
		_refine_human(skeleton, layer, kind, era)
	else:
		_refine_ogre(skeleton, layer, kind, era)

static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

static func _mat(key: String, tint: Color, metallic: float = 0.0, roughness: float = 0.82, family: String = "plain") -> StandardMaterial3D:
	var cache_key := key + tint.to_html(false) + str(metallic) + str(roughness) + family
	if material_cache.has(cache_key):
		return material_cache[cache_key]
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = metallic
	material.roughness = roughness
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if family == "oak":
		material.albedo_texture = load(OAK_ALBEDO)
		material.normal_enabled = true
		material.normal_texture = load(OAK_NORMAL)
		material.normal_scale = 0.26
	elif family == "stone":
		material.albedo_texture = load(SANDSTONE_ALBEDO)
		material.normal_enabled = true
		material.normal_texture = load(SANDSTONE_NORMAL)
		material.normal_scale = 0.32
	elif family == "slate":
		material.albedo_texture = load(SLATE_ALBEDO)
		material.normal_enabled = true
		material.normal_texture = load(SLATE_NORMAL)
		material.normal_scale = 0.26
	if family in ["oak", "stone", "slate"]:
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE * 2.2
	material_cache[cache_key] = material
	return material

static func _attach(skeleton: Skeleton3D, layer: Node3D, bone_name: String, child: Node3D) -> Node3D:
	if skeleton.find_bone(bone_name) < 0:
		layer.add_child(child)
		return child
	var attachment := BoneAttachment3D.new()
	attachment.name = "OgreWarRefine " + bone_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	attachment.add_child(child)
	return child

static func _box(size: Vector3, material: Material, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = at
	return node

static func _sphere(scale_size: Vector3, material: Material, at: Vector3 = Vector3.ZERO, segments: int = 10) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = segments
	mesh.rings = maxi(4, int(segments / 2))
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.scale = scale_size
	return node

static func _cylinder(radius: float, height: float, material: Material, at: Vector3 = Vector3.ZERO, sides: int = 10) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	node.mesh = mesh
	node.material_override = material
	node.position = at
	return node

static func _cone(radius: float, height: float, material: Material, at: Vector3 = Vector3.ZERO, sides: int = 9) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = 0.0
	mesh.height = height
	mesh.radial_segments = sides
	node.mesh = mesh
	node.material_override = material
	node.position = at
	return node

static func _bespoke(file_name: String, material: Material, at: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var path := GEAR_ROOT + file_name + ".obj"
	var mesh: Mesh = gear_mesh_cache.get(path)
	if mesh == null:
		mesh = load(path) as Mesh
		gear_mesh_cache[path] = mesh
	var node := MeshInstance3D.new()
	node.name = "Bespoke " + file_name
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.scale = scale_value
	node.rotation = rot
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node

static func _attach_bespoke(skeleton: Skeleton3D, layer: Node3D, bone_name: String, file_name: String, material: Material, at: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var piece := _bespoke(file_name, material, at, scale_value, rot)
	_attach(skeleton, layer, bone_name, piece)
	return piece

static func _bespoke9(file_name: String, material: Material, at: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var path := PHASE9_GEAR_ROOT + file_name + ".obj"
	var mesh: Mesh = gear_mesh_cache.get(path)
	if mesh == null:
		mesh = load(path) as Mesh
		gear_mesh_cache[path] = mesh
	var node := MeshInstance3D.new()
	node.name = "Phase9 Hero " + file_name
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.scale = scale_value
	node.rotation = rot
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node

static func _attach_bespoke9(skeleton: Skeleton3D, layer: Node3D, bone_name: String, file_name: String, material: Material, at: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var piece := _bespoke9(file_name, material, at, scale_value, rot)
	_attach(skeleton, layer, bone_name, piece)
	return piece

static func _hero_shoulders9(skeleton: Skeleton3D, layer: Node3D, file_name: String, material: Material, scale_value: float = 1.0) -> void:
	for bone_name in ["upper_arm_L", "upper_arm_R"]:
		_attach_bespoke9(skeleton, layer, bone_name, file_name, material, Vector3(0, 0.02, -0.02), Vector3.ONE * scale_value, Vector3(0, 0, 0.11 if bone_name.ends_with("L") else -0.11))

static func _bespoke_shoulders(skeleton: Skeleton3D, layer: Node3D, file_name: String, material: Material, scale_value: float = 1.0) -> void:
	for bone_name in ["upper_arm_L", "upper_arm_R"]:
		_attach_bespoke(skeleton, layer, bone_name, file_name, material, Vector3(0, 0.015, -0.015), Vector3.ONE * scale_value, Vector3(0, 0, 0.08 if bone_name.ends_with("L") else -0.08))

static func _pauldrons(skeleton: Skeleton3D, layer: Node3D, material: Material, scale: float = 1.0, spikes: bool = false) -> void:
	for spec in [["upper_arm_L", -1.0], ["upper_arm_R", 1.0]]:
		var plate := _sphere(Vector3(0.62, 0.36, 0.54) * scale, material, Vector3(0, 0.03, 0))
		_attach(skeleton, layer, str(spec[0]), plate)
		if spikes:
			var spike := _cone(0.075 * scale, 0.34 * scale, material, Vector3(0, 0.12, -0.24))
			spike.rotation.x = PI * 0.5
			_attach(skeleton, layer, str(spec[0]), spike)

static func _helmet_band(skeleton: Skeleton3D, layer: Node3D, material: Material, heavy: bool = false) -> void:
	var band := _cylinder(0.245 if heavy else 0.225, 0.16 if heavy else 0.12, material, Vector3(0, 0.11, 0), 12)
	_attach(skeleton, layer, "head", band)
	var brow := _box(Vector3(0.46 if heavy else 0.40, 0.09, 0.12), material, Vector3(0, 0.01, -0.16))
	_attach(skeleton, layer, "head", brow)

static func _horned_helmet(skeleton: Skeleton3D, layer: Node3D, metal: Material, horn_mat: Material, scale: float = 1.0) -> void:
	_helmet_band(skeleton, layer, metal, true)
	for x in [-0.21, 0.21]:
		var horn := _cone(0.075 * scale, 0.42 * scale, horn_mat, Vector3(x, 0.28, 0), 8)
		horn.rotation.z = (-0.58 if x < 0.0 else 0.58)
		_attach(skeleton, layer, "head", horn)

static func _back_quiver(skeleton: Skeleton3D, layer: Node3D, material: Material, shaft: Material, scale: float = 1.0) -> void:
	var case := _cylinder(0.105 * scale, 0.76 * scale, material, Vector3(-0.17, 0.06, 0.22), 9)
	case.rotation.z = -0.22
	_attach(skeleton, layer, "chest", case)
	for i in 4:
		var arrow := _cylinder(0.014, 0.70 * scale, shaft, Vector3(-0.20 + float(i) * 0.045, 0.32, 0.21), 6)
		arrow.rotation.z = -0.20
		_attach(skeleton, layer, "chest", arrow)

static func _back_banner(skeleton: Skeleton3D, layer: Node3D, pole: Material, cloth: Material, scale: float = 1.0) -> void:
	var staff := _cylinder(0.025 * scale, 1.55 * scale, pole, Vector3(0.18, 0.40, 0.20), 7)
	_attach(skeleton, layer, "chest", staff)
	var flag := _box(Vector3(0.06, 0.46, 0.58) * scale, cloth, Vector3(0.18, 0.80, 0.46))
	flag.rotation.x = 0.10
	_attach(skeleton, layer, "chest", flag)

static func _belt_pouches(skeleton: Skeleton3D, layer: Node3D, material: Material, heavy: bool = false) -> void:
	for x in [-0.25, 0.25]:
		var pouch := _box(Vector3(0.22, 0.26, 0.15) * (1.16 if heavy else 1.0), material, Vector3(x, -0.10, 0.18))
		_attach(skeleton, layer, "hips", pouch)

static func _shield_boss(skeleton: Skeleton3D, layer: Node3D, material: Material, large: bool = false) -> void:
	var boss := _sphere(Vector3(0.25, 0.25, 0.13) * (1.25 if large else 1.0), material, Vector3(0, -0.02, -0.18))
	_attach(skeleton, layer, "hand_L", boss)

static func _weapon_ring(skeleton: Skeleton3D, layer: Node3D, material: Material) -> void:
	var ring := _cylinder(0.09, 0.08, material, Vector3(0, -0.08, -0.03), 10)
	_attach(skeleton, layer, "hand_R", ring)

static func _refine_human(skeleton: Skeleton3D, layer: Node3D, kind: String, era: int) -> void:
	var leather := _mat("human leather", Color("6f4e32"), 0.0, 0.91, "oak")
	var bone := _mat("human bone", Color("dbcaa5"), 0.0, 0.84)
	var cloth_blue := _mat("human cloth", Color("315f79") if era < 2 else Color("294f6b"), 0.0, 0.96)
	var bronze := _mat("bronze", Color("a87943"), 0.72, 0.42)
	var iron := _mat("iron", Color("8b979d"), 0.82, 0.34)
	var dark_iron := _mat("dark iron", Color("566168"), 0.78, 0.38)
	var metal := bronze if era == 1 else iron

	_belt_pouches(skeleton, layer, leather, kind in ["hauler", "lancer"])
	match kind:
		"hunter":
			_pauldrons(skeleton, layer, leather, 0.78)
			var tooth := _cone(0.055, 0.24, bone, Vector3(0.10, 0.24, -0.17), 7)
			tooth.rotation.z = 0.28
			_attach(skeleton, layer, "chest", tooth)
		"slinger":
			_back_quiver(skeleton, layer, leather, bone, 0.72)
			var ammo := _sphere(Vector3(0.32, 0.24, 0.20), leather, Vector3(-0.28, -0.08, 0.22))
			_attach(skeleton, layer, "hips", ammo)
		"hauler":
			_pauldrons(skeleton, layer, leather, 1.10)
			var collar := _sphere(Vector3(0.80, 0.24, 0.48), leather, Vector3(0, 0.18, 0.02))
			_attach(skeleton, layer, "chest", collar)
		"shield":
			_attach_bespoke(skeleton, layer, "head", "human_bronze_helmet", bronze, Vector3(0, 0.08, 0), Vector3.ONE * 1.02)
			_bespoke_shoulders(skeleton, layer, "human_bronze_pauldron", bronze, 1.0)
			_shield_boss(skeleton, layer, bronze, true)
			_weapon_ring(skeleton, layer, bronze)
		"bowman":
			_attach_bespoke(skeleton, layer, "head", "human_bronze_helmet", bronze, Vector3(0, 0.07, 0), Vector3.ONE * 0.92)
			_back_quiver(skeleton, layer, leather, bone, 1.0)
			_attach_bespoke9(skeleton, layer, "chest", "human_bowman_quiverguard", bronze, Vector3(-0.16, 0.08, 0.21), Vector3.ONE * 0.72, Vector3(0, 0, -0.18))
			var bracer := _cylinder(0.075, 0.28, bronze, Vector3(0, -0.12, 0), 10)
			_attach(skeleton, layer, "forearm_L", bracer)
		"swordsman":
			_attach_bespoke(skeleton, layer, "head", "human_iron_helmet", iron, Vector3(0, 0.07, 0), Vector3.ONE * 1.02)
			_attach_bespoke9(skeleton, layer, "head", "human_swordsman_greathelm", dark_iron, Vector3(0, 0.12, 0), Vector3.ONE * 0.94)
			_bespoke_shoulders(skeleton, layer, "human_iron_pauldron", dark_iron, 1.03)
			_hero_shoulders9(skeleton, layer, "human_swordsman_shoulderguard", iron, 0.92)
			_attach_bespoke(skeleton, layer, "chest", "human_iron_breastplate", iron, Vector3(0, 0.04, -0.11), Vector3.ONE * 1.0)
			_shield_boss(skeleton, layer, iron, true)
		"lancer":
			_attach_bespoke(skeleton, layer, "head", "human_iron_helmet", iron, Vector3(0, 0.07, 0), Vector3.ONE * 1.04)
			_attach_bespoke9(skeleton, layer, "head", "human_lancer_crest", iron, Vector3(0, 0.13, 0), Vector3.ONE * 0.96)
			_bespoke_shoulders(skeleton, layer, "human_iron_pauldron", iron, 1.05)
			_attach_bespoke(skeleton, layer, "chest", "human_iron_breastplate", dark_iron, Vector3(0, 0.04, -0.11), Vector3.ONE * 1.02)
			_back_banner(skeleton, layer, dark_iron, cloth_blue, 0.72)
			_attach_bespoke9(skeleton, layer, "hand_R", "human_lancer_lanceguard", bronze, Vector3(0, -0.10, 0), Vector3.ONE)
		_:
			if era >= 1:
				_pauldrons(skeleton, layer, metal, 0.90)

static func _refine_ogre(skeleton: Skeleton3D, layer: Node3D, kind: String, era: int) -> void:
	var hide := _mat("ogre hide", Color("49392d"), 0.0, 0.96, "oak")
	var bone := _mat("ogre bone", Color("c9b78b"), 0.0, 0.86)
	var bronze := _mat("ogre bronze", Color("806548"), 0.60, 0.55)
	var iron := _mat("ogre iron", Color("555a5e"), 0.76, 0.48)
	var black_iron := _mat("black iron", Color("34383d"), 0.82, 0.44)
	var blood_cloth := _mat("ogre banner", Color("6a2f29"), 0.0, 0.96)
	var metal := bronze if era == 1 else iron

	_belt_pouches(skeleton, layer, hide, kind in ["brute", "ogre_captain", "ram_beast"])
	match kind:
		"raider":
			_attach_bespoke(skeleton, layer, "head", "ogre_raider_helmet", hide, Vector3(0, 0.07, 0), Vector3.ONE * 0.92)
			_bespoke_shoulders(skeleton, layer, "ogre_spiked_pauldron", hide, 0.82)
		"thrower":
			var ammo := _sphere(Vector3(0.38, 0.30, 0.26), hide, Vector3(-0.27, -0.08, 0.22))
			_attach(skeleton, layer, "hips", ammo)
			for x in [-0.08, 0.08]:
				var fang := _cone(0.04, 0.20, bone, Vector3(x, 0.18, -0.17), 7)
				fang.rotation.z = 0.18 if x < 0.0 else -0.18
				_attach(skeleton, layer, "chest", fang)
		"brute":
			_attach_bespoke(skeleton, layer, "head", "ogre_raider_helmet", hide, Vector3(0, 0.08, 0), Vector3.ONE * 1.22)
			_bespoke_shoulders(skeleton, layer, "ogre_spiked_pauldron", hide, 1.18)
			for x in [-0.22, 0.22]:
				var tusk := _cone(0.065, 0.30, bone, Vector3(x, -0.08, -0.18), 8)
				tusk.rotation.x = PI * 0.5
				_attach(skeleton, layer, "head", tusk)
		"orc_guard":
			_attach_bespoke(skeleton, layer, "head", "ogre_bronze_guard_helmet", bronze, Vector3(0, 0.07, 0), Vector3.ONE)
			_bespoke_shoulders(skeleton, layer, "ogre_spiked_pauldron", bronze, 0.96)
			_shield_boss(skeleton, layer, bronze, true)
		"horn_bow":
			_back_quiver(skeleton, layer, hide, bone, 1.08)
			_attach_bespoke(skeleton, layer, "head", "ogre_raider_helmet", hide, Vector3(0, 0.07, 0), Vector3.ONE * 0.78)
		"ram_beast":
			_attach_bespoke(skeleton, layer, "head", "ogre_bronze_guard_helmet", bronze, Vector3(0, 0.07, 0), Vector3.ONE * 0.96)
			_back_banner(skeleton, layer, hide, blood_cloth, 0.72)
			_attach_bespoke(skeleton, layer, "horse_body", "mount_iron_barding", bronze, Vector3(0, 0.03, 0.04), Vector3.ONE * 0.82)
		"iron_breaker":
			_attach_bespoke(skeleton, layer, "head", "ogre_iron_breaker_helmet", black_iron, Vector3(0, 0.08, 0), Vector3.ONE * 1.05)
			_attach_bespoke9(skeleton, layer, "head", "ogre_breaker_crown", iron, Vector3(0, 0.12, 0), Vector3.ONE * 1.02)
			_bespoke_shoulders(skeleton, layer, "ogre_spiked_pauldron", black_iron, 1.10)
			_hero_shoulders9(skeleton, layer, "ogre_breaker_pauldron", black_iron, 1.08)
			_attach_bespoke(skeleton, layer, "chest", "ogre_iron_breastplate", iron, Vector3(0, 0.04, -0.13), Vector3.ONE * 1.08)
			_shield_boss(skeleton, layer, iron, true)
		"warg":
			_attach_bespoke(skeleton, layer, "head", "ogre_iron_breaker_helmet", iron, Vector3(0, 0.07, 0), Vector3.ONE * 0.88)
			_bespoke_shoulders(skeleton, layer, "ogre_spiked_pauldron", iron, 0.92)
			_attach_bespoke(skeleton, layer, "horse_body", "mount_iron_barding", black_iron, Vector3(0, 0.04, 0.04), Vector3.ONE * 0.88)
			_attach_bespoke9(skeleton, layer, "horse_head", "warg_faceplate", black_iron, Vector3(0, 0.02, -0.06), Vector3.ONE * 0.92)
		"ogre_captain":
			_attach_bespoke(skeleton, layer, "head", "ogre_captain_helmet", black_iron, Vector3(0, 0.08, 0), Vector3.ONE * 1.08)
			_attach_bespoke9(skeleton, layer, "head", "ogre_captain_crown", iron, Vector3(0, 0.15, 0), Vector3.ONE * 1.06)
			_bespoke_shoulders(skeleton, layer, "ogre_spiked_pauldron", black_iron, 1.22)
			_hero_shoulders9(skeleton, layer, "ogre_captain_pauldron", black_iron, 1.16)
			_attach_bespoke(skeleton, layer, "chest", "ogre_iron_breastplate", iron, Vector3(0, 0.04, -0.13), Vector3.ONE * 1.18)
			_back_banner(skeleton, layer, black_iron, blood_cloth, 1.05)
			_attach_bespoke(skeleton, layer, "head", "ogre_captain_jaw", iron, Vector3(0, -0.14, -0.11), Vector3.ONE * 1.02)
			for x in [-0.20, 0.20]:
				var tusk := _cone(0.075, 0.36, bone, Vector3(x, -0.13, -0.20), 8)
				tusk.rotation.x = PI * 0.5
				_attach(skeleton, layer, "head", tusk)
		_:
			if era >= 1:
				_pauldrons(skeleton, layer, metal, 0.95, true)
