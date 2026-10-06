class_name OgreWarFortressDamage
extends RefCounted

# Phase 7 visual damage-state layer. Fortress gameplay/HP remains authoritative in
# MarchFortress; this layer only adds increasingly severe authored debris, bent
# bracing and soot cues as gate/keep health falls.
const DAMAGE_ROOT := "res://assets/ogre_modern/phase7/damage/"
const OAK_ALBEDO := "res://assets/ogre_modern/materials/oak_albedo_512.png"
const OAK_NORMAL := "res://assets/ogre_modern/materials/oak_normal_512.png"
const STONE_ALBEDO := "res://assets/ogre_modern/materials/sandstone_albedo_512.png"
const STONE_NORMAL := "res://assets/ogre_modern/materials/sandstone_normal_512.png"

var mesh_cache: Dictionary = {}
var material_cache: Dictionary = {}

func apply(fort: MarchFortress) -> void:
	if not is_instance_valid(fort):
		return
	var layer := fort.get_node_or_null("Fortress Damage State")
	if layer == null:
		layer = Node3D.new()
		layer.name = "Fortress Damage State"
		fort.add_child(layer)
	fort.set_meta("ow_damage_gate_stage", -1)
	fort.set_meta("ow_damage_keep_stage", -1)
	update(fort, true)

func update(fort: MarchFortress, force: bool = false) -> void:
	if not is_instance_valid(fort):
		return
	var layer := fort.get_node_or_null("Fortress Damage State") as Node3D
	if layer == null:
		apply(fort)
		return
	var gate_stage := _stage(fort.gate_hp / MarchFortress.GATE_MAX)
	var keep_stage := _stage(fort.keep_hp / MarchFortress.KEEP_MAX)
	var old_gate := int(fort.get_meta("ow_damage_gate_stage", -1))
	var old_keep := int(fort.get_meta("ow_damage_keep_stage", -1))
	if not force and gate_stage == old_gate and keep_stage == old_keep:
		return
	for child in layer.get_children():
		child.queue_free()
	fort.set_meta("ow_damage_gate_stage", gate_stage)
	fort.set_meta("ow_damage_keep_stage", keep_stage)
	_build_gate(layer, fort, gate_stage)
	_build_keep(layer, fort, keep_stage)

func _stage(fraction: float) -> int:
	if fraction <= 0.0:
		return 4
	if fraction <= 0.25:
		return 3
	if fraction <= 0.52:
		return 2
	if fraction <= 0.78:
		return 1
	return 0

func _mesh(file_name: String) -> Mesh:
	var path := DAMAGE_ROOT + file_name + ".obj"
	if mesh_cache.has(path):
		return mesh_cache[path]
	var mesh := load(path) as Mesh
	mesh_cache[path] = mesh
	return mesh

func _material(key: String, tint: Color, family: String = "plain", metallic: float = 0.0, roughness: float = 0.9) -> StandardMaterial3D:
	var cache_key := key + tint.to_html(false) + family + str(metallic) + str(roughness)
	if material_cache.has(cache_key):
		return material_cache[cache_key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.metallic = metallic
	mat.roughness = roughness
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if family == "wood":
		mat.albedo_texture = load(OAK_ALBEDO)
		mat.normal_enabled = true
		mat.normal_texture = load(OAK_NORMAL)
		mat.normal_scale = 0.48
	elif family == "stone":
		mat.albedo_texture = load(STONE_ALBEDO)
		mat.normal_enabled = true
		mat.normal_texture = load(STONE_NORMAL)
		mat.normal_scale = 0.56
	if family in ["wood", "stone"]:
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE * 2.1
	material_cache[cache_key] = mat
	return mat

func _piece(parent: Node3D, file_name: String, at: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE, yaw: float = 0.0, roll: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "Damage " + file_name
	node.mesh = _mesh(file_name)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(node)
	node.position = at
	node.scale = scale_value
	node.rotation.y = yaw
	node.rotation.z = roll
	return node

func _soot(parent: Node3D, at: Vector3, size: Vector2, opacity: float) -> void:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	node.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/castlehold/materials/dust_soft.png")
	mat.albedo_color = Color(0.08, 0.075, 0.07, opacity)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.position = at

func _build_gate(layer: Node3D, fort: MarchFortress, stage: int) -> void:
	if stage <= 0:
		return
	var front := float(-fort.side)
	var x := front * 6.40
	var wood := _material("damage_wood", Color("5b4130") if fort.side == -1 else Color("3f2c27"), "wood")
	var stone := _material("damage_stone", Color("827b6c") if fort.side == -1 else Color("423f42"), "stone")
	var iron := _material("damage_iron", Color("555a5f"), "plain", 0.72, 0.46)
	_soot(layer, Vector3(x - front * 0.52, 2.05, 0), Vector2(3.2, 3.0), 0.16 + float(stage) * 0.05)
	_piece(layer, "timber_splinters", Vector3(x - front * 0.50, 0.05, -1.15), wood, Vector3.ONE * (0.78 + 0.10 * stage), 0.08 * float(fort.side))
	if stage >= 2:
		_piece(layer, "stone_rubble_small", Vector3(x - front * 0.88, 0.02, 1.22), stone, Vector3.ONE * (0.78 + 0.08 * stage), 0.33)
	if stage >= 3:
		_piece(layer, "bent_iron", Vector3(x - front * 0.60, 0.02, 0.15), iron, Vector3.ONE * 0.86, 0.0, 0.08 * front)
		_piece(layer, "gate_shards", Vector3(x - front * 1.05, 0.02, -0.08), wood, Vector3.ONE * 1.05, -0.24)
	if stage >= 4:
		_piece(layer, "stone_rubble_large", Vector3(x - front * 1.25, 0.0, 0.0), stone, Vector3(1.28, 0.88, 1.38), 0.18)
		_piece(layer, "gate_shards", Vector3(x - front * 1.55, 0.01, 1.55), wood, Vector3.ONE * 0.82, 0.52)
		_piece(layer, "stone_rubble_small", Vector3(x - front * 1.75, 0.01, -1.70), stone, Vector3.ONE * 1.12, -0.38)
		_soot(layer, Vector3(x - front * 0.70, 3.15, 1.18), Vector2(2.2, 2.5), 0.24)

func _build_keep(layer: Node3D, fort: MarchFortress, stage: int) -> void:
	if stage <= 0:
		return
	var front := float(-fort.side)
	var face_x := front * (3.15 if fort.side == -1 else 3.75)
	var stone := _material("keep_stone", Color("8f8775") if fort.side == -1 else Color("37363a"), "stone")
	var wood := _material("keep_wood", Color("59422f"), "wood")
	var iron := _material("keep_iron", Color("4e545b"), "plain", 0.74, 0.44)
	_soot(layer, Vector3(face_x - front * 0.12, 3.45 + float(fort.age) * 0.58, -1.45), Vector2(3.0, 3.5), 0.11 + stage * 0.055)
	_piece(layer, "stone_rubble_small", Vector3(face_x - front * 0.82, 0.02, -2.65), stone, Vector3.ONE * (0.82 + 0.11 * stage), -0.22)
	if stage >= 2:
		_piece(layer, "stone_rubble_small", Vector3(face_x - front * 0.98, 0.02, 2.55), stone, Vector3.ONE * 1.08, 0.31)
		_piece(layer, "timber_splinters", Vector3(face_x - front * 0.70, 0.04, 0.9), wood, Vector3.ONE * 0.72, -0.18)
	if stage >= 3:
		_piece(layer, "keep_debris", Vector3(face_x - front * 1.25, 0.0, 0.1), stone, Vector3(1.18, 0.92, 1.18), 0.12)
		_piece(layer, "bent_iron", Vector3(face_x - front * 0.62, 1.0, -0.9), iron, Vector3.ONE * 0.74, 0.0, 0.18 * front)
	if stage >= 4:
		_piece(layer, "stone_rubble_large", Vector3(face_x - front * 1.55, 0.0, 1.55), stone, Vector3.ONE * 1.42, -0.25)
		_piece(layer, "keep_debris", Vector3(face_x - front * 1.82, 0.0, -1.45), stone, Vector3.ONE * 0.94, -0.31)
		_piece(layer, "bent_iron", Vector3(face_x - front * 0.80, 1.25, 1.55), iron, Vector3.ONE * 0.66, 0.22, -0.16 * front)
		_soot(layer, Vector3(face_x - front * 0.20, 5.1 + float(fort.age) * 0.62, 1.15), Vector2(2.6, 3.0), 0.26)
