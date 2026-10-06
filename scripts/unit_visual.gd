class_name OgreWarUnitVisual
extends Node3D

# Phase-1 visual rebuild. Reuses Castlehold's authored, rigged glTF characters
# wherever the silhouette fits, and keeps the old procedural art only for the
# siege machines that do not yet have a Castlehold equivalent.
const MODEL_BY_KIND := {
	"hunter": "spearman",
	"slinger": "slinger",
	"hauler": "swordsman",
	"raider": "raider",
	"thrower": "enemy_slinger",
	"brute": "ogre",
	"shield": "swordsman",
	"bowman": "archer",
	"orc_guard": "orc_guard",
	"horn_bow": "enemy_archer",
	"ram_beast": "ogre_warthog",
	"swordsman": "swordsman",
	"lancer": "knight",
	"iron_breaker": "orc_guard",
	"warg": "mounted_raider",
	"ogre_captain": "boss_gatebreaker"
}

const SCALE_BY_KIND := {
	"hunter": 1.10,
	"slinger": 1.08,
	"hauler": 1.18,
	"raider": 1.10,
	"thrower": 1.08,
	"brute": 1.24,
	"shield": 1.13,
	"bowman": 1.10,
	"orc_guard": 1.15,
	"horn_bow": 1.11,
	"ram_beast": 0.94,
	"swordsman": 1.19,
	"lancer": 0.98,
	"iron_breaker": 1.25,
	"warg": 1.00,
	"ogre_captain": 0.72
}

const BODY_PROPORTION_BY_KIND := {
	"raider": Vector3(1.04, 1.0, 1.03),
	"thrower": Vector3(1.03, 1.0, 1.02),
	"brute": Vector3(1.13, 1.05, 1.10),
	"orc_guard": Vector3(1.06, 1.02, 1.05),
	"horn_bow": Vector3(1.04, 1.0, 1.03),
	"iron_breaker": Vector3(1.14, 1.06, 1.12),
	"ogre_captain": Vector3(1.20, 1.08, 1.16),
	"swordsman": Vector3(1.04, 1.01, 1.03),
	"lancer": Vector3(1.05, 1.01, 1.04)
}

const SIEGE_KINDS := ["ram", "torsion"]

var kind := "hunter"
var side := -1
var ranged := false
var era := 0
var visual: Node3D
var animator: AnimationPlayer
var siege: OgreWarSiegeVisual
var fallback: MarchUnitArt
var moving_time := 0.0
var attack_time := 0.0
var attack_duration := 0.46
var hurt_time := 0.0
var defeated := false
var attack_index := 0
var current_animation := ""
var base_scale := 1.0

func make(which_kind: String, which_side: int, stats: Dictionary, which_era: int) -> void:
	kind = which_kind
	side = which_side
	era = which_era
	ranged = bool(stats.get("ranged", false))
	name = str(stats["title"]) + " Visual"
	if kind in SIEGE_KINDS:
		siege = OgreWarSiegeVisual.new()
		add_child(siege)
		siege.make(kind, side)
		return
	if not MODEL_BY_KIND.has(kind):
		fallback = MarchUnitArt.new()
		add_child(fallback)
		fallback.make(kind, side, stats, era)
		return

	var model_name: String = str(MODEL_BY_KIND[kind])
	var scene_path := "res://assets/castlehold/characters/%s.gltf" % model_name
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("Ogre War could not load Castlehold model: " + scene_path + ". Using legacy art.")
		fallback = MarchUnitArt.new()
		add_child(fallback)
		fallback.make(kind, side, stats, era)
		return

	visual = packed.instantiate() as Node3D
	add_child(visual)
	visual.rotation.y = PI * 0.5 if side == 1 else -PI * 0.5
	var unit_scale: float = float(SCALE_BY_KIND.get(kind, 1.0))
	base_scale = unit_scale
	var body_proportion: Vector3 = BODY_PROPORTION_BY_KIND.get(kind, Vector3.ONE)
	visual.scale = body_proportion * unit_scale
	_apply_castlehold_materials(visual)
	OgreWarUnitRefinement.apply(visual, kind, side, era)
	animator = _find_animation_player(visual)
	if is_instance_valid(animator):
		for loop_name in ["idle", "walk", "run"]:
			if animator.has_animation(loop_name):
				animator.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR
	_play("idle", true)
	_make_contact_shadow(unit_scale)

func _era_tint() -> Color:
	# A restrained multiplier keeps the Castlehold vertex colors and texture maps
	# readable while separating rough Stone, warm Bronze and cool Iron equipment.
	if era == 0:
		return Color("d9c7aa") if side == -1 else Color("a89472")
	if era == 1:
		return Color("d8bd83") if side == -1 else Color("ad8a5b")
	return Color("b9c4c8") if side == -1 else Color("858b89")

func _apply_castlehold_materials(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		node.extra_cull_margin = 2.0
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface_index in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(surface_index)
			if not original is StandardMaterial3D:
				continue
			var material := original.duplicate() as StandardMaterial3D
			material.vertex_color_use_as_albedo = true
			material.vertex_color_is_srgb = true
			material.albedo_color = _era_tint()
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			if era == 0:
				material.metallic = minf(material.metallic, 0.16)
				material.roughness = maxf(material.roughness, 0.78)
			elif era == 1:
				material.metallic = minf(material.metallic, 0.68)
				material.roughness = maxf(material.roughness, 0.52)
			node.set_surface_override_material(surface_index, material)
	for child in node.get_children():
		_apply_castlehold_materials(child)

func _make_contact_shadow(unit_scale: float) -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "Castlehold Contact Shadow"
	var plane := PlaneMesh.new()
	var width := 2.4 if kind in ["lancer", "warg", "ram_beast"] else (2.0 if kind in ["brute", "ogre_captain"] else 1.35)
	plane.size = Vector2(width * unit_scale, 0.92 * unit_scale)
	shadow.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/castlehold/materials/contact_shadow.png")
	material.albedo_color = Color(1, 1, 1, 0.38)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	shadow.material_override = material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.position.y = 0.022
	add_child(shadow)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _play(animation_name: String, force: bool = false) -> void:
	if not is_instance_valid(animator) or not animator.has_animation(animation_name):
		return
	if not force and current_animation == animation_name:
		return
	current_animation = animation_name
	var speed := 1.0
	if animation_name.begins_with("attack"):
		speed = 0.84 if kind in ["brute", "ogre_captain", "iron_breaker"] else 1.02
	elif animation_name == "shoot":
		speed = 0.92 if kind in ["slinger", "thrower"] else 1.0
	elif animation_name == "hit":
		speed = 1.16
	elif animation_name == "defeat":
		speed = 0.88 if kind in ["brute", "ogre_captain"] else 1.0
	elif animation_name in ["walk", "run"]:
		speed = 0.90 if kind in ["brute", "ogre_captain", "ram_beast"] else 1.0
	animator.speed_scale = speed
	animator.play(animation_name, 0.11 if animation_name not in ["hit"] else 0.05)

func march(delta: float, phase: float) -> void:
	if is_instance_valid(siege):
		siege.march(delta, phase)
		return
	if is_instance_valid(fallback):
		fallback.march(delta, phase)
		return
	if defeated:
		return
	moving_time = maxf(0.0, moving_time - delta)
	attack_time = maxf(0.0, attack_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	# Phase 7 procedural secondary motion sits on top of Castlehold's authored
	# clips. It creates unit-specific anticipation, recoil and weight without
	# replacing the shared skeleton/animation library.
	if is_instance_valid(visual):
		var target_x := 0.0
		var target_y := 0.0
		var target_z := 0.0
		var target_pitch := 0.0
		var target_roll := 0.0
		var forward := -float(side)
		if attack_time > 0.0:
			var p := clampf(1.0 - attack_time / maxf(0.01, attack_duration), 0.0, 1.0)
			var pulse := sin(p * PI)
			# Phase 9 gives the highest-value silhouettes distinct attack weight rather
			# than letting every melee rig share the same secondary motion.
			if kind == "ogre_captain":
				target_y = -0.105 * pulse
				target_x = forward * (0.045 + 0.16 * pulse)
				target_roll = -forward * (0.075 - 0.22 * p) * pulse
				target_pitch = -0.045 * pulse
			elif kind == "iron_breaker":
				target_y = -0.060 * pulse
				target_x = forward * 0.145 * pulse
				target_roll = -forward * 0.105 * pulse
			elif kind == "brute":
				target_y = -0.080 * pulse
				target_x = forward * (0.035 + 0.11 * pulse)
				target_roll = -forward * (0.055 - 0.18 * p) * pulse
			elif kind == "lancer":
				target_x = forward * 0.26 * pulse
				target_y = -0.030 * pulse
				target_pitch = -0.030 * pulse
				target_roll = -forward * 0.040 * pulse
			elif kind == "swordsman":
				target_x = forward * 0.135 * pulse
				target_y = -0.020 * pulse
				target_roll = -forward * (0.065 + 0.035 * sin(p * TAU)) * pulse
			elif kind in ["shield", "orc_guard"]:
				target_x = forward * 0.080 * pulse
				target_y = -0.038 * pulse
				target_roll = -forward * 0.030 * pulse
			elif kind in ["hunter", "raider", "hauler"]:
				target_x = forward * 0.10 * pulse
				target_y = -0.020 * pulse
				target_roll = -forward * 0.045 * pulse
			elif kind in ["slinger", "thrower"]:
				# Slingers visibly wind away from the target then snap through release.
				target_x = -forward * 0.035 * sin(p * PI * 0.85)
				target_roll = forward * (-0.075 * sin(minf(1.0, p / 0.58) * PI) + 0.045 * sin(maxf(0.0, p - 0.52) / 0.48 * PI))
				target_y = 0.020 * sin(p * PI * 2.0)
			elif kind in ["bowman", "horn_bow"]:
				target_x = -forward * 0.025 * (1.0 - p) + forward * 0.055 * sin(maxf(0.0, p - 0.48) / 0.52 * PI)
				target_roll = forward * 0.030 * pulse
			elif kind == "warg":
				target_x = forward * 0.19 * pulse
				target_y = 0.045 * pulse
				target_pitch = -0.055 * pulse
			elif kind == "ram_beast":
				target_x = forward * 0.14 * pulse
				target_y = 0.035 * pulse
				target_pitch = -0.025 * pulse
			else:
				target_y = -0.012 * pulse
		elif hurt_time > 0.0:
			target_x = -forward * 0.065
			target_y = 0.040
			target_roll = forward * 0.055
		elif moving_time > 0.0:
			# Mounted/heavy silhouettes receive a tiny weight bob in addition to the
			# skeletal run cycle; light infantry stay nearly neutral.
			var weight := 0.024 if kind in ["brute", "ogre_captain", "iron_breaker", "warg", "ram_beast"] else 0.008
			target_y = sin(phase * 0.55) * weight
		visual.position.x = lerpf(visual.position.x, target_x, 1.0 - exp(-15.0 * delta))
		visual.position.y = lerpf(visual.position.y, target_y, 1.0 - exp(-12.0 * delta))
		visual.position.z = lerpf(visual.position.z, target_z, 1.0 - exp(-12.0 * delta))
		visual.rotation.x = lerpf(visual.rotation.x, target_pitch, 1.0 - exp(-14.0 * delta))
		visual.rotation.z = lerpf(visual.rotation.z, target_roll, 1.0 - exp(-14.0 * delta))
	if attack_time > 0.0 or hurt_time > 0.0:
		return
	_play("run" if moving_time > 0.0 else "idle")

func moved() -> void:
	if is_instance_valid(siege):
		siege.moved()
		return
	if is_instance_valid(fallback):
		fallback.moved()
		return
	moving_time = 0.18

func impact() -> void:
	if is_instance_valid(siege):
		siege.impact()
		return
	if is_instance_valid(fallback):
		fallback.impact()
		return
	attack_index += 1
	if kind in ["slinger", "thrower"]:
		attack_duration = 0.66
	elif kind in ["bowman", "horn_bow"]:
		attack_duration = 0.58
	elif kind == "ogre_captain":
		attack_duration = 0.72
	elif kind in ["brute", "iron_breaker"]:
		attack_duration = 0.64
	elif kind == "lancer":
		attack_duration = 0.52
	else:
		attack_duration = 0.46
	attack_time = attack_duration
	if ranged:
		_play("shoot", true)
	else:
		_play("attack_a" if attack_index % 2 else "attack_b", true)

func hurt() -> void:
	if is_instance_valid(siege):
		siege.hurt()
		return
	if is_instance_valid(fallback):
		return
	if attack_time > 0.18:
		return
	hurt_time = 0.22
	_play("hit", true)

func defeat() -> void:
	if is_instance_valid(siege):
		siege.defeat()
		return
	if is_instance_valid(fallback):
		return
	defeated = true
	attack_time = 0.0
	hurt_time = 0.0
	_play("defeat", true)
	if is_instance_valid(visual):
		var fall_roll := (0.16 if attack_index % 2 == 0 else -0.16) * (1.35 if kind in ["brute", "ogre_captain"] else 1.0)
		var tween := visual.create_tween().set_parallel(true)
		tween.tween_property(visual, "rotation:z", fall_roll, 0.68).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(visual, "position:y", -0.035, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
