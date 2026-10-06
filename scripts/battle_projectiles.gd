class_name OgreWarProjectilePool
extends Node3D

# Adapted from Castlehold's pooled projectile system. Ranged attacks now travel
# through the battlefield and land later instead of applying invisible instant
# damage. Friendly troops never block the projectile simulation.
const SLOT_COUNT := 96

var slots: Array[Dictionary] = []
var meshes: Dictionary = {}
var materials: Dictionary = {}
var embedded: Array[Dictionary] = []

func _ready() -> void:
	meshes["stone"] = _sphere_mesh(0.10, 8)
	meshes["rock"] = _sphere_mesh(0.19, 9)
	meshes["arrow"] = _bolt_mesh(0.66, 0.026, 6)
	meshes["bolt"] = _bolt_mesh(1.10, 0.045, 7)
	materials["stone"] = _material(Color("756f65"), 0.96)
	materials["rock"] = _material(Color("5d5852"), 0.98)
	materials["arrow"] = _material(Color("c7aa72"), 0.72)
	materials["bolt"] = _material(Color("87949a"), 0.48, 0.35)
	for index in SLOT_COUNT:
		var projectile := MeshInstance3D.new()
		projectile.name = "Projectile %03d" % index
		projectile.visible = false
		projectile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var trail := MeshInstance3D.new()
		trail.name = "Trail"
		var trail_mesh := CylinderMesh.new()
		trail_mesh.height = 0.72
		trail_mesh.top_radius = 0.012
		trail_mesh.bottom_radius = 0.028
		trail_mesh.radial_segments = 6
		trail.mesh = trail_mesh
		var trail_mat := StandardMaterial3D.new()
		trail_mat.albedo_color = Color(0.86,0.82,0.70,0.26)
		trail_mat.emission_enabled = true
		trail_mat.emission = Color(0.75,0.70,0.58)
		trail_mat.emission_energy_multiplier = 0.45
		trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		trail.material_override = trail_mat
		trail.position.y = -0.44
		trail.visible = false
		projectile.add_child(trail)
		add_child(projectile)
		slots.append({"node": projectile, "trail": trail, "active": false, "t": 0.0})
	# Short-lived embedded arrows/bolts sell contact without leaving hundreds of
	# persistent nodes in long mobile battles.
	for index in 24:
		var stuck := MeshInstance3D.new()
		stuck.name = "Embedded Projectile %02d" % index
		stuck.visible = false
		stuck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(stuck)
		embedded.append({"node": stuck, "life": 0.0, "duration": 0.72})

func _sphere_mesh(radius: float, segments: int) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(4, int(segments / 2))
	return mesh

func _bolt_mesh(length: float, radius: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.height = length
	mesh.top_radius = radius * 0.72
	mesh.bottom_radius = radius
	mesh.radial_segments = segments
	return mesh

func _material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _profile(kind: String) -> String:
	if kind == "slinger":
		return "stone"
	if kind == "thrower":
		return "rock"
	if kind in ["bowman", "horn_bow"]:
		return "arrow"
	return "bolt"

func _speed(profile: String) -> float:
	match profile:
		"stone": return 16.0
		"rock": return 12.0
		"arrow": return 24.0
		_: return 19.0

func _arc(profile: String, distance: float) -> float:
	match profile:
		"stone": return 1.2 + distance * 0.075
		"rock": return 1.8 + distance * 0.09
		"arrow": return 0.65 + distance * 0.035
		_: return 0.42 + distance * 0.02

func _launch_slot(profile: String, start: Vector3, end: Vector3) -> Dictionary:
	for slot in slots:
		if bool(slot.active):
			continue
		var node: MeshInstance3D = slot.node
		node.mesh = meshes[profile]
		node.material_override = materials[profile]
		node.global_position = start
		node.visible = true
		var trail: MeshInstance3D = slot.trail
		trail.visible = profile in ["arrow", "bolt"]
		trail.scale = Vector3(1.0, 1.25 if profile == "bolt" else 0.82, 1.0)
		slot.active = true
		slot.t = 0.0
		slot.start = start
		slot.end = end
		slot.profile = profile
		slot.arc = _arc(profile, start.distance_to(end))
		slot.duration = maxf(0.14, start.distance_to(end) / _speed(profile))
		return slot
	return {}

func launch_unit(attacker: MarchSoldier, target: MarchSoldier, damage: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var profile := _profile(attacker.kind)
	var start := attacker.global_position + Vector3(0, 1.65 if profile != "rock" else 1.95, 0)
	var end := target.global_position + Vector3(0, 1.35 if target.kind not in ["brute", "ram_beast", "ogre_captain"] else 1.9, 0)
	var slot := _launch_slot(profile, start, end)
	if slot.is_empty():
		return
	slot.target = weakref(target)
	slot.target_type = "unit"
	slot.damage = damage
	slot.attacker_side = attacker.side
	slot.attacker_kind = attacker.kind

func launch_structure(attacker: MarchSoldier, fort: MarchFortress, part: String, damage: float) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(fort):
		return
	var profile := _profile(attacker.kind)
	var start := attacker.global_position + Vector3(0, 1.7, 0)
	var x_target: float = fort.gate_x if part == "gate" else fort.keep_x
	var target_height := fort.gate_height * 0.58 if part == "gate" else 3.4 + float(fort.age) * 0.55
	var end := Vector3(x_target, target_height, 0)
	var slot := _launch_slot(profile, start, end)
	if slot.is_empty():
		return
	slot.target = weakref(fort)
	slot.target_type = "structure"
	slot.part = part
	slot.damage = damage
	slot.attacker_side = attacker.side
	slot.attacker_kind = attacker.kind

func _process(delta: float) -> void:
	for slot in slots:
		if not bool(slot.active):
			continue
		var target_ref: WeakRef = slot.target
		var target = target_ref.get_ref()
		if is_instance_valid(target):
			if str(slot.target_type) == "unit" and target.hp > 0.0:
				slot.end = target.global_position + Vector3(0, 1.35 if target.kind not in ["brute", "ram_beast", "ogre_captain"] else 1.9, 0)
			elif str(slot.target_type) == "structure":
				var fort := target as MarchFortress
				var part := str(slot.part)
				var x_target: float = fort.gate_x if part == "gate" else fort.keep_x
				var target_height := fort.gate_height * 0.58 if part == "gate" else 3.4 + float(fort.age) * 0.55
				slot.end = Vector3(x_target, target_height, 0)
		slot.t = float(slot.t) + delta / maxf(0.01, float(slot.duration))
		var t: float = minf(1.0, float(slot.t))
		var node: MeshInstance3D = slot.node
		var previous := node.global_position
		var start: Vector3 = slot.start
		var end: Vector3 = slot.end
		var point: Vector3 = start.lerp(end, t) + Vector3.UP * sin(t * PI) * float(slot.arc)
		node.global_position = point
		var velocity := point - previous
		if velocity.length_squared() > 0.0001 and str(slot.profile) in ["arrow", "bolt"]:
			node.quaternion = Quaternion(Vector3.UP, velocity.normalized())
			var trail: MeshInstance3D = slot.trail
			var tm := trail.material_override as StandardMaterial3D
			tm.albedo_color.a = 0.26 * (1.0 - smoothstep(0.70, 1.0, t))
		if t >= 1.0:
			_impact(slot)
	for stuck_slot in embedded:
		if float(stuck_slot.life) <= 0.0:
			continue
		stuck_slot.life = maxf(0.0, float(stuck_slot.life) - delta)
		var stuck: MeshInstance3D = stuck_slot.node
		if float(stuck_slot.life) <= 0.0:
			stuck.visible = false

func _stick_projectile(profile: String, at: Vector3, orientation: Quaternion) -> void:
	if profile not in ["arrow", "bolt"]:
		return
	for stuck_slot in embedded:
		if float(stuck_slot.life) > 0.0:
			continue
		var stuck: MeshInstance3D = stuck_slot.node
		stuck.mesh = meshes[profile]
		stuck.material_override = materials[profile]
		stuck.global_position = at
		stuck.quaternion = orientation
		stuck.scale = Vector3.ONE * (0.88 if profile == "arrow" else 0.96)
		stuck.visible = true
		stuck_slot.duration = 0.72 if profile == "arrow" else 0.58
		stuck_slot.life = stuck_slot.duration
		return

func _impact(slot: Dictionary) -> void:
	var node: MeshInstance3D = slot.node
	var target_ref: WeakRef = slot.target
	var target = target_ref.get_ref()
	if is_instance_valid(target):
		if str(slot.target_type) == "unit" and target.hp > 0.0:
			var profile := str(slot.profile)
			if is_instance_valid(target.game.vfx):
				var element := "pierce" if profile == "arrow" else ("stone" if profile in ["stone", "rock"] else "metal")
				target.game.vfx.burst(target.global_position + Vector3.UP * 1.05, profile in ["rock", "bolt"], element)
			if profile in ["arrow", "bolt"]:
				_stick_projectile(profile, node.global_position, node.quaternion)
			var dealt: float = target.take_ranged_hit(float(slot.damage), int(slot.attacker_side), str(slot.attacker_kind))
			target.game.gain_progress(int(slot.attacker_side), dealt)
		elif str(slot.target_type) == "structure":
			var fort := target as MarchFortress
			var arena := fort.get_parent()
			var profile := str(slot.profile)
			if is_instance_valid(arena) and is_instance_valid(arena.vfx):
				var element := "wood" if str(slot.part) == "gate" else ("stone" if profile in ["stone", "rock"] else ("metal" if profile == "bolt" else "pierce"))
				arena.vfx.burst(node.global_position, profile in ["rock", "bolt"], element)
			if profile in ["arrow", "bolt"]:
				_stick_projectile(profile, node.global_position, node.quaternion)
			if is_instance_valid(arena) and is_instance_valid(arena.audio):
				arena.audio.play_effect("gate_hit", fort.gate_x, -7.0)
			var part := str(slot.part)
			var remaining: float = fort.gate_hp if part == "gate" else fort.keep_hp
			var dealt := minf(float(slot.damage), remaining)
			if part == "gate" and fort.gate_hp > 0.0:
				fort.damage_gate(float(slot.damage))
				fort.get_parent().gain_progress(int(slot.attacker_side), dealt)
				fort.get_parent().on_structure_hit(fort, "gate", float(slot.damage))
			elif part == "keep" and fort.gate_hp <= 0.0 and fort.keep_hp > 0.0:
				fort.damage_keep(float(slot.damage))
				fort.get_parent().gain_progress(int(slot.attacker_side), dealt)
				fort.get_parent().on_structure_hit(fort, "keep", float(slot.damage))
	slot.active = false
	node.visible = false
	(slot.trail as MeshInstance3D).visible = false

func clear() -> void:
	for slot in slots:
		slot.active = false
		var node: MeshInstance3D = slot.node
		node.visible = false
		(slot.trail as MeshInstance3D).visible = false
	for stuck_slot in embedded:
		stuck_slot.life = 0.0
		(stuck_slot.node as MeshInstance3D).visible = false
