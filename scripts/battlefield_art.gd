class_name OgreWarBattlefield
extends RefCounted

# Battlefield presentation adapted from Castlehold's WorldBuilder. It keeps the
# combat lane clean while adding the valley shader, layered ridges, vegetation,
# rocks and a proper sky instead of the old flat-color block field.
var root: Node3D
var materials: Dictionary = {}
var rng := RandomNumberGenerator.new()
var prop_mesh_cache: Dictionary = {}
const PROP_ROOT := "res://assets/ogre_modern/phase6/props/"
const PHASE7_PROP_ROOT := "res://assets/ogre_modern/phase7/props/"
const PHASE9_PROP_ROOT := "res://assets/ogre_modern/phase9/props/"

func build(parent: Node3D) -> void:
	root = parent
	rng.seed = 41377
	_make_ground()
	_ridgeline(-31.0, 11.5, Color("627c7a"), 0.0)
	_ridgeline(-24.0, 8.2, Color("46695f"), 1.8)
	_ridgeline(-18.0, 5.0, Color("2f5040"), 4.1)
	for index in 23:
		var x := rng.randf_range(-59.0, 59.0)
		var z := rng.randf_range(-16.5, -10.0)
		_tree(Vector3(x, 0, z), rng.randf_range(0.68, 1.12))
	for index in 34:
		var x := rng.randf_range(-58.0, 58.0)
		var z := rng.randf_range(8.7, 13.0) * (1.0 if index % 2 == 0 else -1.0)
		_rock(Vector3(x, 0.14, z), rng.randf_range(0.18, 0.52))
	_grass_field()
	_battlefield_props()
	_phase9_depth_props()
	_make_lighting()

func _material(color: Color, roughness: float = 0.88) -> StandardMaterial3D:
	var key := color.to_html(false) + str(roughness)
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	materials[key] = material
	return material

func _make_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Castlehold Valley Ground"
	var plane := PlaneMesh.new()
	# Extra terrain outside the playable camera limits hides the abrupt edge on
	# wide phones and during small camera shake movements.
	plane.size = Vector2(150.0, 54.0)
	ground.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/castlehold/materials/valley_ground.gdshader")
	ground.material_override = material
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ground)

func _make_lighting() -> void:
	# Main sun now casts a deliberately short, stable shadow field. The limited
	# distance keeps mobile cost bounded while restoring contact and depth.
	var sun := DirectionalLight3D.new()
	sun.name = "Valley Sun"
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color("ffd29a")
	sun.light_energy = 1.18
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 58.0
	sun.shadow_opacity = 0.62
	sun.shadow_bias = 0.055
	sun.shadow_normal_bias = 1.4
	sun.shadow_blur = 1.15
	root.add_child(sun)

	# A cool, non-shadowing fill keeps dark ogre armor readable without erasing
	# the warm sun direction.
	var fill := DirectionalLight3D.new()
	fill.name = "Valley Sky Fill"
	fill.rotation_degrees = Vector3(-28, 138, 0)
	fill.light_color = Color("7898aa")
	fill.light_energy = 0.12
	fill.shadow_enabled = false
	root.add_child(fill)

	var world := WorldEnvironment.new()
	world.name = "Valley Environment"
	world.environment = Environment.new()
	var env := world.environment
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("3f6f8b")
	sky_material.sky_horizon_color = Color("a9bec0")
	sky_material.ground_bottom_color = Color("203328")
	sky_material.ground_horizon_color = Color("687b69")
	sky_material.sky_curve = 0.24
	sky_material.sun_angle_max = 7.0
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Mobile-safe fog only. SSAO is not supported by Godot's Mobile renderer,
	# so do not write SSAO properties here. Contact depth comes from bounded
	# directional shadows plus authored material/texture detail.
	env.set("fog_enabled", true)
	env.set("fog_light_color", Color("829596"))
	env.set("fog_light_energy", 0.30)
	env.set("fog_density", 0.003)
	env.set("fog_height", 0.8)
	env.set("fog_height_density", 0.035)
	env.set("fog_sky_affect", 0.10)
	root.add_child(world)

func _ridgeline(z: float, height: float, color: Color, phase: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 32:
		var x := -69.0 + float(index) * 4.5
		var xx := x + 4.5
		var y := height * (0.55 + 0.20 * sin(x * 0.17 + phase) + 0.16 * sin(x * 0.41 + phase) + 0.09 * sin(x * 0.89))
		var yy := height * (0.55 + 0.20 * sin(xx * 0.17 + phase) + 0.16 * sin(xx * 0.41 + phase) + 0.09 * sin(xx * 0.89))
		for point in [Vector3(x, -1, z), Vector3(x, y, z), Vector3(xx, yy, z), Vector3(x, -1, z), Vector3(xx, yy, z), Vector3(xx, -1, z)]:
			surface.set_color(color.darkened(0.22) if point.y < 0.0 else color.lightened(0.10))
			surface.add_vertex(point)
	surface.generate_normals()
	var ridge := MeshInstance3D.new()
	ridge.mesh = surface.commit()
	var material := _material(Color.WHITE).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ridge.material_override = material
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ridge)

func _foliage(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	var sides := 9
	for row in 7:
		var ring: Array[Vector3] = []
		var latitude := -PI * 0.5 + float(row) * PI / 6.0
		for column in sides:
			var angle := float(column) * TAU / float(sides)
			var radius := maxf(0.015, cos(latitude)) * (1.0 + 0.09 * sin(float(column) * 2.3 + float(row) * 1.7))
			ring.append(Vector3(cos(angle) * radius * size.x, sin(latitude) * size.y, sin(angle) * radius * size.z))
		rings.append(ring)
	for row in 6:
		for column in sides:
			var next := (column + 1) % sides
			for point in [rings[row][column], rings[row + 1][column], rings[row + 1][next], rings[row][column], rings[row + 1][next], rings[row][next]]:
				surface.add_vertex(point)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	mesh.position = at

func _cylinder(parent: Node3D, at: Vector3, bottom: float, top: float, height: float, color: Color, sides: int = 9) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	node.mesh = mesh
	node.material_override = _material(color)
	parent.add_child(node)
	node.position = at
	return node

func _tree(at: Vector3, size: float) -> void:
	var tree_root := Node3D.new()
	root.add_child(tree_root)
	tree_root.position = at
	tree_root.scale = Vector3.ONE * size
	_cylinder(tree_root, Vector3(0, 0.9, 0), 0.15, 0.07, 1.8, Color("5c4c36"), 7)
	var branch := _cylinder(tree_root, Vector3(-0.28, 1.50, 0), 0.09, 0.045, 0.9, Color("5c4c36"), 7)
	branch.rotation.z = -0.67
	branch = _cylinder(tree_root, Vector3(0.29, 1.65, -0.03), 0.085, 0.03, 0.8, Color("5c4c36"), 7)
	branch.rotation.z = 0.71
	_foliage(tree_root, Vector3(-0.40, 1.8, 0.08), Vector3(0.9, 0.85, 0.8), Color("31553d"))
	_foliage(tree_root, Vector3(0.45, 2.0, 0.02), Vector3(0.85, 1.0, 0.82), Color("456d45"))
	_foliage(tree_root, Vector3(0, 2.65, -0.10), Vector3(0.88, 0.85, 0.83), Color("537649"))

func _rock(at: Vector3, size: float) -> void:
	var rock := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 1.35
	sphere.radial_segments = 7
	sphere.rings = 4
	rock.mesh = sphere
	rock.scale = Vector3(1.4, 0.72, 1.0)
	rock.rotation_degrees = Vector3(rng.randf_range(-9, 9), rng.randf_range(0, 180), rng.randf_range(-7, 7))
	rock.material_override = _material(Color("6e7067"), 0.97)
	root.add_child(rock)
	rock.position = at

func _grass_field() -> void:
	# One instanced draw adds depth to the verges without hundreds of grass nodes.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in 5:
		var x := float(blade - 2) * 0.09
		var depth := -0.09 if blade % 2 == 0 else 0.09
		for point in [Vector3(x - 0.05, 0, depth), Vector3(x + 0.04, 0.25 + float(blade % 3) * 0.065, depth + 0.06), Vector3(x + 0.06, 0, depth)]:
			surface.add_vertex(point)
	surface.generate_normals()
	var material := _material(Color.WHITE, 0.98).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = surface.commit()
	instances.instance_count = 460
	for index in instances.instance_count:
		var x := rng.randf_range(-59.0, 59.0)
		var z := rng.randf_range(5.3, 18.0) * (1.0 if index % 2 == 0 else -1.0)
		var width := rng.randf_range(0.75, 1.65)
		var height := rng.randf_range(0.74, 1.52)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(width, height, width))
		instances.set_instance_transform(index, Transform3D(basis, Vector3(x, 0.016, z)))
		var tint := Color("637c44") if x < -12.0 else (Color("797442") if x > 13.0 else Color("72844a"))
		instances.set_instance_color(index, tint.lightened(rng.randf_range(0.0, 0.24)))
	var grass := MultiMeshInstance3D.new()
	grass.name = "Instanced Valley Grass"
	grass.multimesh = instances
	grass.material_override = material
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(grass)


func _castlehold_material(family: String, tint: Color) -> StandardMaterial3D:
	var key := "castlehold_" + family + tint.to_html(false)
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.90
	if family in ["oak", "sandstone", "slate"]:
		material.albedo_texture = load("res://assets/ogre_modern/materials/%s_albedo_512.png" % family)
		material.normal_enabled = true
		material.normal_texture = load("res://assets/ogre_modern/materials/%s_normal_512.png" % family)
		material.normal_scale = 0.32 if family != "sandstone" else 0.48
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE * (1.6 if family == "oak" else 2.0)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	materials[key] = material
	return material

func _prop_box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	node.position = at
	return node

func _authored_prop(file_name: String, at: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE, yaw: float = 0.0) -> MeshInstance3D:
	var path := PROP_ROOT + file_name + ".obj"
	var mesh: Mesh = prop_mesh_cache.get(path)
	if mesh == null:
		mesh = load(path) as Mesh
		prop_mesh_cache[path] = mesh
	var node := MeshInstance3D.new()
	node.name = "Authored " + file_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(node)
	node.position = at
	node.scale = scale_value
	node.rotation.y = yaw
	return node

func _authored_prop7(file_name: String, at: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE, yaw: float = 0.0) -> MeshInstance3D:
	var path := PHASE7_PROP_ROOT + file_name + ".obj"
	var mesh: Mesh = prop_mesh_cache.get(path)
	if mesh == null:
		mesh = load(path) as Mesh
		prop_mesh_cache[path] = mesh
	var node := MeshInstance3D.new()
	node.name = "Phase7 Authored " + file_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(node)
	node.position = at
	node.scale = scale_value
	node.rotation.y = yaw
	return node

func _authored_prop9(file_name: String, at: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE, yaw: float = 0.0, cast_shadow: bool = true) -> MeshInstance3D:
	var path := PHASE9_PROP_ROOT + file_name + ".obj"
	var mesh: Mesh = prop_mesh_cache.get(path)
	if mesh == null:
		mesh = load(path) as Mesh
		prop_mesh_cache[path] = mesh
	var node := MeshInstance3D.new()
	node.name = "Phase9 Depth " + file_name
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
	node.position = at
	node.scale = scale_value
	node.rotation.y = yaw
	return node

func _iron_prop_material() -> StandardMaterial3D:
	var key := "phase6_iron_prop"
	if materials.has(key):
		return materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("596067")
	material.metallic = 0.76
	material.roughness = 0.42
	materials[key] = material
	return material

func _prop_wheel(parent: Node3D, at: Vector3, radius: float) -> void:
	var wheel := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius
	mesh.height = 0.18
	mesh.radial_segments = 10
	wheel.mesh = mesh
	wheel.material_override = _castlehold_material("oak", Color("54402f"))
	parent.add_child(wheel)
	wheel.position = at
	wheel.rotation.x = PI * 0.5

func _broken_cart(at: Vector3, flipped: bool = false) -> void:
	var cart := Node3D.new()
	cart.name = "Broken Siege Cart"
	root.add_child(cart)
	cart.position = at
	cart.rotation.y = 0.28 if flipped else -0.34
	var oak := _castlehold_material("oak", Color("73553a"))
	_prop_box(cart, Vector3(0, 0.45, 0), Vector3(2.2, 0.22, 1.25), oak)
	_prop_box(cart, Vector3(-0.85, 0.78, 0), Vector3(0.16, 0.85, 1.05), oak)
	_prop_box(cart, Vector3(0.86, 0.69, -0.08), Vector3(0.14, 0.62, 0.88), oak)
	_prop_wheel(cart, Vector3(-0.64, 0.24, -0.74), 0.45)
	_prop_wheel(cart, Vector3(0.68, 0.18, 0.78), 0.38)
	var broken_axle := _prop_box(cart, Vector3(1.45, 0.34, 0.2), Vector3(1.45, 0.12, 0.12), oak)
	broken_axle.rotation.z = -0.27

func _banner_post(at: Vector3, cloth: Color, crude: bool) -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	holder.position = at
	var oak := _castlehold_material("oak", Color("684b32"))
	var fabric := _material(cloth, 0.96)
	_prop_box(holder, Vector3(0, 1.25, 0), Vector3(0.10, 2.5, 0.10), oak)
	var flag := _prop_box(holder, Vector3(0, 1.85, 0.48), Vector3(0.08, 0.78, 0.92), fabric)
	flag.rotation.x = 0.16 if crude else -0.05

func _campfire(at: Vector3) -> void:
	var fire := Node3D.new()
	root.add_child(fire)
	fire.position = at
	for i in 6:
		var angle := TAU * float(i) / 6.0
		_rock(at + Vector3(cos(angle) * 0.40, 0.12, sin(angle) * 0.40), 0.16)
	var ember := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.35
	sphere.radial_segments = 8
	sphere.rings = 4
	ember.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d96c31")
	mat.emission_enabled = true
	mat.emission = Color("c45124")
	mat.emission_energy_multiplier = 1.5
	ember.material_override = mat
	root.add_child(ember)
	ember.position = at + Vector3.UP * 0.28
	var light := OmniLight3D.new()
	light.name = "Campfire Glow"
	light.light_color = Color("ff9a58")
	light.light_energy = 0.75
	light.omni_range = 5.2
	light.shadow_enabled = false
	root.add_child(light)
	light.position = at + Vector3.UP * 0.72
	for level in 3:
		var smoke := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(0.65 + float(level) * 0.34, 0.65 + float(level) * 0.34)
		smoke.mesh = quad
		var sm := StandardMaterial3D.new()
		sm.albedo_texture = load("res://assets/castlehold/materials/dust_soft.png")
		sm.albedo_color = Color(0.25, 0.25, 0.24, 0.13 - float(level) * 0.025)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		smoke.material_override = sm
		smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(smoke)
		smoke.position = at + Vector3(0.10 * float(level), 0.85 + float(level) * 0.58, -0.05 * float(level))

func _battlefield_props() -> void:
	# Phase 6 replaces the most obvious runtime-box scenery with authored mesh
	# props. They sit outside the five fighting lanes so readability is preserved.
	# The valley shader handles broken road wear; overlay planes produced four
	# ruler-straight stripes across the entire battlefield.
	var oak := _castlehold_material("oak", Color("73553a"))
	var stone := _castlehold_material("sandstone", Color("74736b"))
	var iron := _iron_prop_material()
	_authored_prop("broken_cart_wood", Vector3(-20.5, 0.02, 7.8), oak, Vector3.ONE, -0.34)
	_authored_prop("broken_cart_wood", Vector3(18.0, 0.02, -8.1), oak, Vector3(0.92,0.92,0.92), 2.78)
	_authored_prop("spike_barricade", Vector3(-31.5, 0.0, -8.7), oak, Vector3.ONE * 0.94, 0.22)
	_authored_prop("spike_barricade", Vector3(32.8, 0.0, 8.5), oak, Vector3.ONE * 1.05, -0.31)
	_authored_prop("ruined_palisade", Vector3(-11.5, 0.0, 10.0), oak, Vector3.ONE * 0.92, -0.18)
	_authored_prop("weapon_pile_iron", Vector3(-38.2, 0.0, 8.3), iron, Vector3.ONE * 0.82, 0.45)
	_authored_prop("weapon_pile_iron", Vector3(39.5, 0.0, -8.0), iron, Vector3.ONE * 0.86, -0.52)
	_authored_prop("shield_stack", Vector3(-44.0, 0.02, -7.6), oak, Vector3.ONE * 0.90, 0.30)
	_authored_prop("boulder_cluster", Vector3(9.5, 0.0, 10.7), stone, Vector3.ONE * 1.25, 0.18)
	_authored_prop("boulder_cluster", Vector3(-5.8, 0.0, -10.5), stone, Vector3.ONE * 0.95, -0.36)
	# Phase 7 authored environment clusters add storytelling and foreground depth
	# while staying outside the five combat lanes.
	_authored_prop7("fallen_banner", Vector3(-27.0, 0.02, 9.3), oak, Vector3.ONE * 0.92, -0.28)
	_authored_prop7("fallen_banner", Vector3(27.8, 0.02, -9.1), oak, Vector3.ONE * 0.88, 2.88)
	_authored_prop7("supply_crates", Vector3(-48.2, 0.02, 7.4), oak, Vector3.ONE * 0.92, 0.18)
	_authored_prop7("camp_bundle", Vector3(-45.6, 0.02, 9.8), oak, Vector3.ONE * 0.88, -0.22)
	_authored_prop7("supply_crates", Vector3(47.9, 0.02, -7.2), oak, Vector3.ONE * 0.94, 2.94)
	_authored_prop7("camp_bundle", Vector3(45.3, 0.02, -9.9), oak, Vector3.ONE * 0.90, 2.80)
	_authored_prop7("stump_cluster", Vector3(-15.8, 0.0, -12.0), oak, Vector3.ONE * 0.95, 0.42)
	_authored_prop7("stump_cluster", Vector3(13.6, 0.0, 12.2), oak, Vector3.ONE * 1.10, -0.35)
	_authored_prop7("rubble_field", Vector3(-3.6, 0.0, 10.6), stone, Vector3.ONE * 1.20, 0.12)
	_authored_prop7("rubble_field", Vector3(5.2, 0.0, -10.7), stone, Vector3.ONE * 1.02, -0.24)
	_authored_prop7("abandoned_wheel", Vector3(-23.4, 0.0, -8.3), oak, Vector3.ONE * 0.84, 0.20)
	_authored_prop7("weapon_rack", Vector3(-50.2, 0.0, -7.1), iron, Vector3.ONE * 0.83, -0.05)
	_authored_prop7("weapon_rack", Vector3(50.0, 0.0, 7.0), iron, Vector3.ONE * 0.86, PI + 0.08)
	# Ruined watchposts sit farther back and provide readable mid-distance landmarks.
	_authored_prop7("ruined_watchpost", Vector3(-33.0, 0.0, -13.2), oak, Vector3.ONE * 1.15, 0.18)
	_authored_prop7("ruined_watchpost", Vector3(34.2, 0.0, 13.0), oak, Vector3.ONE * 1.08, PI - 0.22)
	_banner_post(Vector3(-42.5, 0, 6.8), Color("315f7f"), false)
	_banner_post(Vector3(-37.8, 0, -6.9), Color("315f7f"), false)
	_banner_post(Vector3(42.3, 0, -6.6), Color("71352d"), true)
	_banner_post(Vector3(37.4, 0, 7.0), Color("71352d"), true)
	_campfire(Vector3(-46.0, 0, -8.8))
	_campfire(Vector3(46.2, 0, 8.9))
func _phase9_depth_props() -> void:
	# Phase 9 treats the valley as a composed battlefield instead of a flat prop field.
	# Larger landmarks sit beyond the five combat lanes and create foreground,
	# midground and horizon layers without increasing pathing complexity.
	var oak := _castlehold_material("oak", Color("594230"))
	var stone := _castlehold_material("sandstone", Color("696b63"))
	var dark_stone := _castlehold_material("slate", Color("3f4b4b"))
	var iron := _iron_prop_material()
	_authored_prop9("distant_hamlet", Vector3(-25.0, 0.0, -15.2), stone, Vector3.ONE * 1.05, 0.18, false)
	_authored_prop9("distant_hamlet", Vector3(30.5, 0.0, 14.8), stone, Vector3.ONE * 0.90, PI - 0.22, false)
	_authored_prop9("chapel_ruin", Vector3(-7.5, 0.0, -15.4), stone, Vector3.ONE * 1.05, -0.12, true)
	_authored_prop9("ridge_ruin", Vector3(12.0, 0.0, 15.5), dark_stone, Vector3.ONE * 1.18, 0.10, true)
	_authored_prop9("siege_tower_wreck", Vector3(-35.5, 0.0, 11.8), oak, Vector3.ONE * 1.08, 0.28, true)
	_authored_prop9("wagon_barricade", Vector3(25.0, 0.0, -11.0), oak, Vector3.ONE * 1.05, -0.32, true)
	_authored_prop9("charred_tree_cluster", Vector3(40.5, 0.0, 14.0), dark_stone, Vector3.ONE * 1.18, 0.24, false)
	_authored_prop9("charred_tree_cluster", Vector3(-43.0, 0.0, -13.6), dark_stone, Vector3.ONE, -0.17, false)
	_authored_prop9("banner_cluster", Vector3(-50.0, 0.0, 11.2), oak, Vector3.ONE, 0.04, true)
	_authored_prop9("banner_cluster", Vector3(50.2, 0.0, -11.3), iron, Vector3.ONE * 1.05, PI, true)
	_authored_prop9("rock_outcrop", Vector3(-1.0, 0.0, -13.5), stone, Vector3.ONE * 1.28, 0.10, true)
	_authored_prop9("rock_outcrop", Vector3(5.0, 0.0, 13.6), dark_stone, Vector3.ONE * 1.12, -0.20, true)
