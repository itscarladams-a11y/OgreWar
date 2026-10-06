class_name OgreWarFortressSkin
extends RefCounted

# Fast Castlehold reuse pass for Ogre War's existing fortress geometry.
# The gameplay-facing gate/keep nodes remain untouched, but their flat-color
# materials are upgraded with Castlehold's authored triplanar surface maps.
const SANDSTONE_ALBEDO := "res://assets/castlehold/materials/sandstone_albedo.png"
const SANDSTONE_NORMAL := "res://assets/castlehold/materials/sandstone_normal.png"
const OAK_ALBEDO := "res://assets/castlehold/materials/oak_albedo.png"
const OAK_NORMAL := "res://assets/castlehold/materials/oak_normal.png"
const SLATE_ALBEDO := "res://assets/castlehold/materials/slate_albedo.png"
const SLATE_NORMAL := "res://assets/castlehold/materials/slate_normal.png"

var texture_cache: Dictionary = {}

func apply(fort: MarchFortress) -> void:
	if not is_instance_valid(fort) or not is_instance_valid(fort.architecture):
		return
	_skin_node(fort.architecture, fort.side, fort.age)

func _texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	var value := load(path) as Texture2D
	texture_cache[path] = value
	return value

func _skin_node(node: Node, faction_side: int, age: int) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var material := mesh_node.material_override as StandardMaterial3D
		if material != null:
			mesh_node.material_override = _castlehold_material(material, faction_side, age)
	for child in node.get_children():
		_skin_node(child, faction_side, age)

func _castlehold_material(source: StandardMaterial3D, faction_side: int, age: int) -> StandardMaterial3D:
	var material := source.duplicate() as StandardMaterial3D
	var tint := material.albedo_color
	var hue := tint.h
	var saturation := tint.s
	var value := tint.v
	var family := "sandstone"

	# Blue/blue-gray roofs and trim get Castlehold slate.
	if hue >= 0.48 and hue <= 0.72 and saturation >= 0.08:
		family = "slate"
	# Dark warm browns are timber. Pale warm colors remain masonry.
	elif hue >= 0.035 and hue <= 0.16 and saturation >= 0.20 and value < 0.54:
		family = "oak"
	# Brighter warm fittings read better as bronze/iron rather than wood grain.
	elif hue >= 0.055 and hue <= 0.16 and saturation >= 0.18 and value >= 0.54:
		family = "metal"
	# Ogre charcoal stone stays stone, but receives a heavier, rougher response.
	elif faction_side == 1 and value < 0.40 and saturation < 0.22:
		family = "sandstone"

	if family == "oak":
		material.albedo_texture = _texture(OAK_ALBEDO)
		material.normal_texture = _texture(OAK_NORMAL)
		material.normal_enabled = true
		material.normal_scale = 0.32
		material.uv1_scale = Vector3.ONE * 1.5
		material.roughness = maxf(material.roughness, 0.80)
	elif family == "slate":
		material.albedo_texture = _texture(SLATE_ALBEDO)
		material.normal_texture = _texture(SLATE_NORMAL)
		material.normal_enabled = true
		material.normal_scale = 0.30
		material.uv1_scale = Vector3.ONE * 1.75
		material.roughness = maxf(material.roughness, 0.65)
	elif family == "metal":
		material.albedo_texture = null
		material.normal_enabled = false
		material.metallic = 0.58
		material.roughness = 0.40 if faction_side == -1 else 0.52
	else:
		material.albedo_texture = _texture(SANDSTONE_ALBEDO)
		material.normal_texture = _texture(SANDSTONE_NORMAL)
		material.normal_enabled = true
		material.normal_scale = 0.50 if faction_side == -1 else 0.62
		material.uv1_scale = Vector3.ONE * (2.05 if faction_side == -1 else 1.68)
		material.roughness = 0.90 if faction_side == -1 else 0.97

	if family != "metal":
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Age progression changes surface character as well as silhouette.
	if faction_side == -1:
		if age == 0:
			material.albedo_color = material.albedo_color.darkened(0.06)
			material.roughness = maxf(material.roughness, 0.84)
		elif age == 2 and family == "sandstone":
			material.albedo_color = material.albedo_color.lightened(0.08)
	else:
		if age == 0:
			material.albedo_color = material.albedo_color.darkened(0.10)
		elif age == 2:
			material.albedo_color = material.albedo_color.darkened(0.18)
			material.roughness = maxf(material.roughness, 0.90)
	return material
