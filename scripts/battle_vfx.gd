class_name OgreWarBattleVFX
extends Node3D

# Compact adaptation of Castlehold's pooled battle VFX. It deliberately uses
# a bounded pool for Android stability while making impacts readable: sparks,
# chips and soft dust instead of full-screen flashes.
const SLOT_COUNT := 80
var slots: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var light_slots: Array[Dictionary] = []

func _ready() -> void:
	rng.seed = 90517
	var spark := PrismMesh.new()
	spark.size = Vector3(0.045, 0.22, 0.045)
	var chip := PrismMesh.new()
	chip.size = Vector3(0.13, 0.14, 0.11)
	var dust := QuadMesh.new()
	dust.size = Vector2.ONE
	var shock := CylinderMesh.new()
	shock.bottom_radius = 0.52
	shock.top_radius = 0.52
	shock.height = 0.025
	shock.radial_segments = 20
	for index in SLOT_COUNT:
		var kind := "spark" if index < 38 else ("chip" if index < 55 else ("dust" if index < 72 else "shock"))
		var node := MeshInstance3D.new()
		node.name = "VFX %02d %s" % [index, kind]
		node.mesh = spark if kind == "spark" else (chip if kind == "chip" else (dust if kind == "dust" else shock))
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("eec37e") if kind == "spark" else (Color("d3b578") if kind == "shock" else Color("9f8664"))
		material.roughness = 0.94
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if kind != "chip":
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		if kind == "dust":
			material.albedo_texture = load("res://assets/castlehold/materials/dust_soft.png")
		node.material_override = material
		node.visible = false
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		slots.append({"node": node, "material": material, "kind": kind, "life": 0.0, "duration": 1.0, "velocity": Vector3.ZERO, "base": 1.0})
	for index in 8:
		var glow := OmniLight3D.new()
		glow.name = "Impact Glow %02d" % index
		glow.light_color = Color("f0b26b")
		glow.light_energy = 0.0
		glow.omni_range = 4.6
		glow.shadow_enabled = false
		glow.visible = false
		add_child(glow)
		light_slots.append({"node": glow, "life": 0.0, "duration": 0.18, "energy": 0.0})

func burst(pos: Vector3, heavy: bool = false, element: String = "physical") -> void:
	if heavy:
		_flash_light(pos, Color("f0a85c") if element == "wood" else Color("e7c394"), 1.35)
	var wanted := {"spark": 5 if heavy else 2, "chip": 7 if heavy else 1, "dust": 4 if heavy else 1, "shock": 1 if heavy else 0}
	if element == "wood":
		wanted = {"spark": 1, "chip": 8 if heavy else 3, "dust": 5 if heavy else 2, "shock": 1 if heavy else 0}
	elif element == "metal":
		wanted = {"spark": 9 if heavy else 4, "chip": 2 if heavy else 0, "dust": 1 if heavy else 0, "shock": 1 if heavy else 0}
	elif element == "stone":
		wanted = {"spark": 0, "chip": 6 if heavy else 2, "dust": 7 if heavy else 3, "shock": 1 if heavy else 0}
	elif element == "pierce":
		wanted = {"spark": 1 if heavy else 0, "chip": 2 if heavy else 1, "dust": 2 if heavy else 0, "shock": 0}
	elif element == "ground":
		wanted = {"spark": 0, "chip": 1 if heavy else 0, "dust": 6 if heavy else 3, "shock": 0}
	for slot in slots:
		var kind := str(slot.kind)
		if float(slot.life) > 0.0 or int(wanted.get(kind, 0)) <= 0:
			continue
		wanted[kind] = int(wanted[kind]) - 1
		var node: MeshInstance3D = slot.node
		var material: StandardMaterial3D = slot.material
		slot.duration = 0.90 if kind == "dust" and heavy else (0.52 if kind == "dust" else (0.36 if kind == "shock" else (0.62 if kind == "chip" else 0.23)))
		slot.life = slot.duration
		slot.base = (1.15 if heavy else 0.58) if kind == "dust" else ((0.75 if heavy else 0.45) if kind == "shock" else (1.20 if heavy else 0.78))
		node.visible = true
		node.global_position = pos + Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.05, 0.13), rng.randf_range(-0.12, 0.12))
		node.scale = Vector3.ONE * float(slot.base) * (0.42 if kind == "dust" else 1.0)
		var spread := 0.62 if kind == "dust" else (2.5 if heavy else 1.55)
		slot.velocity = Vector3.ZERO if kind == "shock" else Vector3(rng.randf_range(-spread, spread), rng.randf_range(0.42, 1.08) if kind == "dust" else rng.randf_range(1.1, 3.1), rng.randf_range(-spread, spread))
		if kind == "spark":
			material.albedo_color = Color("d9e2e5") if element == "metal" else Color("e9b56b")
		elif element == "wood":
			material.albedo_color = Color("7f684e")
		elif element in ["stone", "ground"]:
			material.albedo_color = Color("8b806e")
		elif element == "pierce":
			material.albedo_color = Color("806f59")
		else:
			material.albedo_color = Color("9f8664")
		material.albedo_color.a = 0.0 if kind == "dust" else 0.82


func footstep_dust(pos: Vector3, heavy: bool = false) -> void:
	var remaining := 3 if heavy else 1
	for slot in slots:
		if remaining <= 0:
			break
		if float(slot.life) > 0.0 or str(slot.kind) != "dust":
			continue
		remaining -= 1
		var node: MeshInstance3D = slot.node
		var material: StandardMaterial3D = slot.material
		slot.duration = 0.42 if heavy else 0.28
		slot.life = slot.duration
		slot.base = 0.48 if heavy else 0.26
		node.visible = true
		node.global_position = pos + Vector3(rng.randf_range(-0.18, 0.18), 0.04, rng.randf_range(-0.18, 0.18))
		node.scale = Vector3.ONE * float(slot.base)
		slot.velocity = Vector3(rng.randf_range(-0.28, 0.28), rng.randf_range(0.18, 0.38), rng.randf_range(-0.24, 0.24))
		material.albedo_color = Color(0.44, 0.39, 0.31, 0.0)

func _flash_light(pos: Vector3, color: Color, energy: float) -> void:
	for slot in light_slots:
		if float(slot.life) > 0.0:
			continue
		var light: OmniLight3D = slot.node
		light.global_position = pos + Vector3.UP * 0.65
		light.light_color = color
		light.light_energy = energy
		light.visible = true
		slot.life = 0.18
		slot.duration = 0.18
		slot.energy = energy
		return

func fortress_event(pos: Vector3, human: bool, major: bool = false) -> void:
	var color := Color("78a8c8") if human else Color("c06a50")
	_flash_light(pos + Vector3.UP * 1.8, color, 1.8 if major else 1.15)
	for offset in [-1.3, -0.45, 0.45, 1.3]:
		burst(pos + Vector3(offset, 0.5 + absf(offset) * 0.15, 0), major, "physical")

func _process(delta: float) -> void:
	for slot in slots:
		if float(slot.life) <= 0.0:
			continue
		slot.life = maxf(0.0, float(slot.life) - delta)
		var t := 1.0 - float(slot.life) / maxf(0.001, float(slot.duration))
		var node: MeshInstance3D = slot.node
		var material: StandardMaterial3D = slot.material
		if str(slot.kind) == "dust":
			node.scale = Vector3.ONE * float(slot.base) * (0.42 + t * 1.25)
			material.albedo_color.a = minf(1.0, t / 0.16) * (1.0 - t) * 0.42
		elif str(slot.kind) == "shock":
			node.scale = Vector3(float(slot.base) * (0.55 + t * 2.65), 0.18, float(slot.base) * (0.55 + t * 2.65))
			material.albedo_color.a = (1.0 - t) * 0.28
		else:
			var velocity: Vector3 = slot.velocity
			velocity.y -= 9.8 * delta
			slot.velocity = velocity
			if str(slot.kind) == "spark":
				material.albedo_color.a = (1.0 - t) * 0.82
			else:
				node.rotate_x(delta * 5.0)
				node.rotate_z(delta * 3.0)
		node.global_position += Vector3(slot.velocity) * delta
		node.visible = float(slot.life) > 0.0
	for light_slot in light_slots:
		if float(light_slot.life) <= 0.0:
			continue
		light_slot.life = maxf(0.0, float(light_slot.life) - delta)
		var light: OmniLight3D = light_slot.node
		var fraction := float(light_slot.life) / maxf(0.001, float(light_slot.duration))
		light.light_energy = float(light_slot.energy) * fraction * fraction
		light.visible = float(light_slot.life) > 0.0

func clear() -> void:
	for slot in slots:
		slot.life = 0.0
		var node: MeshInstance3D = slot.node
		node.visible = false
	for light_slot in light_slots:
		light_slot.life = 0.0
		var light: OmniLight3D = light_slot.node
		light.visible = false
		light.light_energy = 0.0
