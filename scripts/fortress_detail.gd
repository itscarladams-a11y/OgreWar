class_name OgreWarFortressDetail
extends RefCounted

# Modern-mobile fortress presentation layer.
# Phase 4 compatibility module names: "human_wall" "human_tower" "human_gatehouse" "human_keep" "ogre_wall" "ogre_tower" "ogre_gatehouse" "ogre_keep"
# Core gate/keep gameplay stays in MarchFortress, while the visible silhouette is
# built from reusable authored OBJ modules rather than runtime primitive stacks.

# Compatibility notes retained from Phase 3 validation:
# Visible portcullis behind the timber gate.
# Bailey-era timber fighting platforms now sit around authored modular walls.
# Bronze plates look hammered-on rather than cleanly engineered.
# Iron citadel: enormous black-iron crown is now an authored keep module plus trim.
# Bone trophy poles establish the crude fantasy identity, with horns/banners replacing repetitive props.

const MODULE_ROOT := "res://assets/ogre_modern/fortress_modules/"
const PHASE9_HERO_ROOT := "res://assets/ogre_modern/phase9/fortress_hero/"
const OAK_ALBEDO := "res://assets/ogre_modern/materials/oak_albedo_512.png"
const OAK_NORMAL := "res://assets/ogre_modern/materials/oak_normal_512.png"
const SANDSTONE_ALBEDO := "res://assets/ogre_modern/materials/sandstone_albedo_512.png"
const SANDSTONE_NORMAL := "res://assets/ogre_modern/materials/sandstone_normal_512.png"
const SLATE_ALBEDO := "res://assets/ogre_modern/materials/slate_albedo_512.png"
const SLATE_NORMAL := "res://assets/ogre_modern/materials/slate_normal_512.png"

var material_cache: Dictionary = {}
var mesh_cache: Dictionary = {}

func apply(fort: MarchFortress) -> void:
	if not is_instance_valid(fort):
		return
	var old := fort.get_node_or_null("Modern Fortress Mesh Layer")
	if old != null:
		fort.remove_child(old)
		old.queue_free()
	var legacy := fort.get_node_or_null("Castlehold Detail Layer")
	if legacy != null:
		fort.remove_child(legacy)
		legacy.queue_free()
	# The old procedural architecture remains the gameplay authority, but only
	# the functional gate stays visible. The authored module kit becomes the
	# primary castle silhouette, preventing doubled walls and z-fighting.
	if is_instance_valid(fort.architecture):
		for child in fort.architecture.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = child == fort.gate_mesh
	var layer := Node3D.new()
	layer.name = "Modern Fortress Mesh Layer"
	fort.add_child(layer)
	if fort.side == -1:
		_human(layer, fort.age)
	else:
		_ogre(layer, fort.age)

func _mat(family: String, tint: Color, metallic: float = 0.0, emission: float = 0.0) -> StandardMaterial3D:
	var key := family + tint.to_html(false) + str(metallic) + str(emission)
	if material_cache.has(key):
		return material_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.metallic = metallic
	m.roughness = 0.92 if metallic < 0.2 else 0.42
	if family == "stone":
		m.albedo_texture = load(SANDSTONE_ALBEDO)
		m.normal_enabled = true
		m.normal_texture = load(SANDSTONE_NORMAL)
		m.normal_scale = 0.62
	elif family == "oak":
		m.albedo_texture = load(OAK_ALBEDO)
		m.normal_enabled = true
		m.normal_texture = load(OAK_NORMAL)
		m.normal_scale = 0.42
	elif family == "slate":
		m.albedo_texture = load(SLATE_ALBEDO)
		m.normal_enabled = true
		m.normal_texture = load(SLATE_NORMAL)
		m.normal_scale = 0.46
	if family in ["stone", "oak", "slate"]:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * (2.35 if family == "stone" else 1.75)
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = tint.lightened(0.12)
		m.emission_energy_multiplier = emission
	material_cache[key] = m
	return m

func _module(parent: Node3D, file_name: String, at: Vector3, scale_value: Vector3, material: Material, yaw: float = 0.0) -> MeshInstance3D:
	var path := MODULE_ROOT + file_name + ".obj"
	var mesh: Mesh = mesh_cache.get(path)
	if mesh == null:
		mesh = load(path) as Mesh
		mesh_cache[path] = mesh
	var node := MeshInstance3D.new()
	node.name = file_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	node.position = at
	node.scale = scale_value
	node.rotation.y = yaw
	return node

func _hero_module(parent: Node3D, file_name: String, at: Vector3, scale_value: Vector3, material: Material, yaw: float = 0.0) -> MeshInstance3D:
	var path := PHASE9_HERO_ROOT + file_name + ".obj"
	var mesh: Mesh = mesh_cache.get(path)
	if mesh == null:
		mesh = load(path) as Mesh
		mesh_cache[path] = mesh
	var node := MeshInstance3D.new()
	node.name = "Phase9 Hero " + file_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	node.position = at
	node.scale = scale_value
	node.rotation.y = yaw
	return node

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	node.position = at
	node.rotation = rot
	return node

func _cone(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = 0.0
	mesh.height = height
	mesh.radial_segments = 9
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	node.position = at
	node.rotation = rot
	return node

func _banner(parent: Node3D, at: Vector3, cloth: Material, pole: Material, crude := false) -> void:
	_box(parent, at + Vector3(0, 1.2, 0), Vector3(0.10, 2.5, 0.10), pole)
	var flag := _box(parent, at + Vector3(0.02, 1.78, 0.50), Vector3(0.08, 0.82, 0.98), cloth)
	flag.rotation.x = 0.15 if crude else -0.05

func _brazier(parent: Node3D, at: Vector3, iron: Material, ember: Material) -> void:
	_box(parent, at, Vector3(0.62, 0.18, 0.62), iron)
	for x in [-0.16, 0.0, 0.16]:
		_cone(parent, at + Vector3(x, 0.38 + absf(x), 0), 0.11, 0.68 - absf(x), ember)

func _human(layer: Node3D, age: int) -> void:
	var stone := _mat("stone", Color("b9ad92") if age == 0 else (Color("c5bba4") if age == 1 else Color("cec8b8")))
	var dark_stone := _mat("stone", Color("827a6c") if age < 2 else Color("8b8f8d"))
	var oak := _mat("oak", Color("705238"))
	var slate := _mat("slate", Color("4b5d69") if age < 2 else Color("394b58"))
	var bronze := _mat("plain", Color("a5763f"), 0.72)
	var iron := _mat("plain", Color("7e8b92"), 0.82)
	var blue := _mat("plain", Color("315d79") if age < 2 else Color("244b67"))
	var metal := bronze if age == 1 else iron
	var era_name: String = str(["stone", "bronze", "iron"][age])
	var wall_scale := Vector3.ONE
	var tower_scale := Vector3.ONE
	var gate_scale := Vector3.ONE
	var keep_scale := Vector3.ONE

	# Phase 5 uses unique authored geometry per era instead of stretching one
	# generic castle kit. Age progression now changes architecture, not only trim.
	_module(layer, "human_wall_" + era_name, Vector3(7.55, 0.0, -8.05), wall_scale, stone)
	_module(layer, "human_wall_" + era_name, Vector3(7.55, 0.0, 8.05), wall_scale, stone)
	_module(layer, "human_tower_" + era_name, Vector3(6.15, 0.0, -5.45), tower_scale, dark_stone)
	_module(layer, "human_tower_" + era_name, Vector3(6.15, 0.0, 5.45), tower_scale, dark_stone)
	_module(layer, "human_gatehouse_" + era_name, Vector3(6.55, 0.0, 0.0), gate_scale, stone)
	_module(layer, "human_keep_" + era_name, Vector3(0.0, 0.0, 0.0), keep_scale, stone)
	# Phase 9 hero overlays add high-contrast silhouette detail without replacing the
	# mobile-friendly base modules. These are deliberately concentrated on the gate
	# and keep because those structures carry the visual identity of the siege.
	_hero_module(layer, "human_gate_hero_" + era_name, Vector3(6.55, 0.0, 0.0), Vector3.ONE, metal if age > 0 else oak)
	_hero_module(layer, "human_keep_hero_" + era_name, Vector3(0.0, 0.0, 0.0), Vector3.ONE, dark_stone)

	# Age language sits on top of the authored modules, not in place of them.
	if age == 0:
		for z in [-6.7, -3.9, 3.9, 6.7]:
			_box(layer, Vector3(8.22, 3.45, z), Vector3(0.30, 2.0, 1.35), oak, Vector3(0.06 if z < 0 else -0.06, 0, 0))
		for z in [-5.5, 5.5]:
			var roof := _box(layer, Vector3(6.15, 6.22, z), Vector3(3.8, 0.34, 3.6), slate)
			roof.rotation.x = 0.22 if z < 0 else -0.22
	elif age == 1:
		for z in [-2.55,-1.7,-0.85,0.0,0.85,1.7,2.55]:
			_box(layer, Vector3(6.08, 1.70, z), Vector3(0.12, 3.05, 0.10), bronze)
		for z in [-4.1,0.0,4.1]:
			_banner(layer, Vector3(3.25, 6.45, z), blue, oak)
	else:
		for z in [-4.4,-2.2,0.0,2.2,4.4]:
			_box(layer, Vector3(3.02, 7.35, z), Vector3(0.72, 1.05, 0.68), dark_stone)
		for z in [-3.2,0.0,3.2]:
			_box(layer, Vector3(6.05, 3.15, z), Vector3(0.28, 4.9, 0.98), iron)
			_banner(layer, Vector3(3.30, 7.25, z), blue, iron)

func _ogre(layer: Node3D, age: int) -> void:
	var stone := _mat("stone", Color("575053") if age == 0 else (Color("413f44") if age == 1 else Color("2d3136")))
	var dark_stone := _mat("stone", Color("373337") if age < 2 else Color("1e2328"))
	var oak := _mat("oak", Color("493329"))
	var bone := _mat("plain", Color("c6b184"))
	var bronze := _mat("plain", Color("806044"), 0.62)
	var iron := _mat("plain", Color("4b5057"), 0.80)
	var blood := _mat("plain", Color("612927") if age < 2 else Color("421d21"))
	var ember := _mat("plain", Color("e17939"), 0.0, 1.7)
	var metal := bronze if age == 1 else iron
	var era_name: String = str(["stone", "bronze", "iron"][age])
	var wall_scale := Vector3.ONE
	var tower_scale := Vector3.ONE
	var gate_scale := Vector3.ONE
	var keep_scale := Vector3.ONE

	_module(layer, "ogre_wall_" + era_name, Vector3(-7.70, 0.0, -8.0), wall_scale, stone, PI)
	_module(layer, "ogre_wall_" + era_name, Vector3(-7.70, 0.0, 8.0), wall_scale, stone, PI)
	_module(layer, "ogre_tower_" + era_name, Vector3(-6.05, 0.0, -5.5), tower_scale, dark_stone, PI)
	_module(layer, "ogre_tower_" + era_name, Vector3(-6.05, 0.0, 5.5), tower_scale * Vector3(1.06,0.96,1.0), dark_stone, PI)
	_module(layer, "ogre_gatehouse_" + era_name, Vector3(-6.45, 0.0, 0.0), gate_scale, stone, PI)
	_module(layer, "ogre_keep_" + era_name, Vector3(0.0, 0.0, 0.0), keep_scale, dark_stone, PI)
	_hero_module(layer, "ogre_gate_hero_" + era_name, Vector3(-6.45, 0.0, 0.0), Vector3.ONE, metal if age > 0 else oak, PI)
	_hero_module(layer, "ogre_keep_hero_" + era_name, Vector3(0.0, 0.0, 0.0), Vector3.ONE, iron if age == 2 else dark_stone, PI)

	# Crude faction punctuation deliberately remains asymmetric.
	for z in [-6.4, -2.7, 3.6, 6.1]:
		var lean := 0.10 if z < 0 else -0.12
		_box(layer, Vector3(-8.35, 2.25, z), Vector3(0.34, 4.25, 0.34), oak, Vector3(lean,0,0.06))
	for z in [-5.8, 0.6, 5.45]:
		_brazier(layer, Vector3(-4.85, 5.75 + float(age)*0.95, z), iron, ember)
	for z in [-4.1, 4.35]:
		_banner(layer, Vector3(-4.45, 6.1 + float(age)*1.15, z), blood, oak, true)

	if age == 0:
		for z in [-5.0,-3.1,-1.2,2.0,3.9,5.6]:
			_cone(layer, Vector3(-8.2, 4.0, z), 0.17, 1.65, oak, Vector3(0.0,0,0.12 if z < 0 else -0.12))
	elif age == 1:
		for z in [-4.6,-2.25,0.25,2.65,4.8]:
			_box(layer, Vector3(-4.0, 5.25, z), Vector3(0.28, 1.5, 1.12), bronze, Vector3(0.04 if z<0 else -0.05,0,0.04))
	else:
		for z in [-5.0,-3.3,-1.65,0.0,1.65,3.3,5.0]:
			_box(layer, Vector3(-3.7, 8.8, z), Vector3(0.66, 1.18, 0.72), iron, Vector3(0.04 if z < 0 else -0.04,0,0.05))
			_cone(layer, Vector3(-3.65, 9.88, z), 0.18, 1.5, metal)
	for z in [-3.1, 3.1]:
		_cone(layer, Vector3(-6.12, 4.0 + float(age)*0.22, z), 0.30, 2.3 + float(age)*0.25, bone, Vector3(0.35 if z < 0 else -0.35,0,0))
