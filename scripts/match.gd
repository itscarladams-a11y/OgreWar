class_name MarchMatch
extends Node3D

const LEFT_BASE := -54.0
const RIGHT_BASE := 54.0
const PLAYFIELD_HALF_LENGTH := 66.0
const CAMERA_EDGE_BUFFER := 3.5
const CAMERA_MAX_TARGET_X := 47.0
const CAMERA_CLOSE_SIZE := 20.0
const CAMERA_WIDE_SIZE := 29.5
const POPULATION_CAP := 24
const INCOME_INTERVAL := 5.0
const INCOME_AMOUNT := 46
const ORC_INCOME_AMOUNT := 66
const REPAIR_COST := 135
const REPAIR_AMOUNT := 165.0
const BRONZE_PROGRESS_REQUIRED := 100.0
const BRONZE_GOLD_COST := 220
const IRON_PROGRESS_REQUIRED := 150.0
const IRON_GOLD_COST := 360

const FORTRESS_SKIN_SCRIPT := preload("res://scripts/fortress_skin.gd")
const FORTRESS_DETAIL_SCRIPT := preload("res://scripts/fortress_detail.gd")
const FORTRESS_DAMAGE_SCRIPT := preload("res://scripts/fortress_damage.gd")

var fortress_skin = FORTRESS_SKIN_SCRIPT.new()
var fortress_detail = FORTRESS_DETAIL_SCRIPT.new()
var fortress_damage = FORTRESS_DAMAGE_SCRIPT.new()

var human_fort: MarchFortress
var orc_fort: MarchFortress
var soldiers: Array[MarchSoldier] = []
var camera: Camera3D
var hud: MarchHUD
var audio: OgreWarAudio
var projectiles: OgreWarProjectilePool
var vfx: OgreWarBattleVFX
var gold := {-1: 245, 1: 275}
var age := {-1: 0, 1: 0}
var age_progress := {-1: 0.0, 1: 0.0}
var recruit_ready := {-1: 0.0, 1: 0.0}
var repairs_used := {-1: 0, 1: 0}
var casualties := {-1: 0, 1: 0}
var match_time := 0.0
var income_clock := INCOME_INTERVAL
var ai_clock := 2.1
var ai_cycle := 0
var hold_order := false
var phase := "playing"
var camera_target_x := LEFT_BASE + 14.0
var camera_mode := "free"
var mouse_drag := false
var touch_finger := -1
var touch_points: Dictionary = {}
var notice_clock := 0.0
var hud_clock := 0.0
var camera_trauma := 0.0
var camera_shake_phase := 0.0

func _ready() -> void:
	make_environment()
	human_fort = MarchFortress.new()
	add_child(human_fort)
	human_fort.position = Vector3(LEFT_BASE, 0, 0)
	human_fort.build(-1)
	fortress_skin.apply(human_fort)
	fortress_detail.apply(human_fort)
	fortress_damage.apply(human_fort)
	orc_fort = MarchFortress.new()
	add_child(orc_fort)
	orc_fort.position = Vector3(RIGHT_BASE, 0, 0)
	orc_fort.build(1)
	fortress_skin.apply(orc_fort)
	fortress_detail.apply(orc_fort)
	fortress_damage.apply(orc_fort)
	vfx = OgreWarBattleVFX.new()
	vfx.name = "Castlehold Battle VFX"
	add_child(vfx)
	projectiles = OgreWarProjectilePool.new()
	projectiles.name = "Castlehold Projectile Pool"
	add_child(projectiles)
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_WIDE_SIZE
	camera.near = 0.5
	camera.far = 190.0
	camera.current = true
	camera_target_x = clamp_camera_x(camera_target_x)
	set_camera_x(camera_target_x)
	hud = MarchHUD.new()
	add_child(hud)
	hud.build(self)
	audio = OgreWarAudio.new()
	add_child(audio)
	audio.start(self)
	spawn_soldier("hunter", -1)
	spawn_soldier("raider", 1)
	hud.announce("TRAIN TROOPS • DRAG TO SCOUT • PINCH TO ZOOM", 4.0)
	hud.refresh()

func make_environment() -> void:
	OgreWarBattlefield.new().build(self)

func spawn_soldier(kind: String, side: int) -> MarchSoldier:
	var troop := MarchSoldier.new()
	add_child(troop)
	var count := count_side(side)
	var lanes := [-2.0, -1.0, 0.0, 1.0, 2.0]
	troop.position = Vector3(LEFT_BASE + 10.0 if side == -1 else RIGHT_BASE - 10.0, 0.0, lanes[count % lanes.size()])
	troop.make(kind, side, self)
	soldiers.append(troop)
	return troop

func count_side(side: int) -> int:
	var count := 0
	for soldier in soldiers:
		if soldier.side == side and soldier.hp > 0.0:
			count += 1
	return count

func try_recruit(kind: String) -> bool:
	return recruit(kind, -1)

func current_roster(side: int) -> Array:
	if side == -1:
		if int(age[side]) == 2:
			return ["swordsman", "lancer", "torsion"]
		return ["shield", "bowman", "ram"] if int(age[side]) == 1 else ["hunter", "slinger", "hauler"]
	if int(age[side]) == 2:
		return ["iron_breaker", "warg", "ogre_captain"]
	return ["orc_guard", "horn_bow", "ram_beast"] if int(age[side]) == 1 else ["raider", "thrower", "brute"]

func try_recruit_slot(slot: int) -> bool:
	var roster := current_roster(-1)
	if slot < 0 or slot >= roster.size():
		return false
	return recruit(str(roster[slot]), -1)

func recruit(kind: String, side: int) -> bool:
	if phase != "playing" or not MarchSoldier.CLASSES.has(kind):
		return false
	if kind not in current_roster(side):
		return false
	var unit_stats: Dictionary = MarchSoldier.CLASSES[kind]
	var cost: int = int(unit_stats["cost"])
	if int(gold[side]) < cost or float(recruit_ready[side]) > match_time or count_side(side) >= POPULATION_CAP:
		return false
	gold[side] = int(gold[side]) - cost
	recruit_ready[side] = match_time + float(unit_stats["cooldown"])
	spawn_soldier(kind, side)
	if kind == "ogre_captain" and is_instance_valid(audio):
		audio.play_effect("boss_roar", 0.0, -5.0, true)
	if kind in ["hauler", "brute", "ram", "ram_beast", "torsion", "ogre_captain"]:
		hud.announce("SIEGE TROOPS MARCH" if side == -1 else "ORC SIEGE BEAST APPROACHING", 2.0)
	hud.refresh()
	return true

func gain_progress(side: int, damage_done: float, kill_bonus: float = 0.0) -> void:
	if phase != "playing" or int(age[side]) >= 2 or damage_done + kill_bonus <= 0.0:
		return
	age_progress[side] = minf(progress_required(side), float(age_progress[side]) + damage_done * 0.06 + kill_bonus)

func progress_required(side: int) -> float:
	return BRONZE_PROGRESS_REQUIRED if int(age[side]) == 0 else IRON_PROGRESS_REQUIRED

func age_cost(side: int) -> int:
	return BRONZE_GOLD_COST if int(age[side]) == 0 else IRON_GOLD_COST

func age_name(side: int) -> String:
	if int(age[side]) == 2:
		return "IRON"
	return "BRONZE" if int(age[side]) == 1 else "STONE"

func progress_text(side: int) -> String:
	if int(age[side]) == 2:
		return "MAX"
	return "%d/%d" % [int(age_progress[side]), int(progress_required(side))]

func can_advance(side: int) -> bool:
	return phase == "playing" and int(age[side]) < 2 and float(age_progress[side]) >= progress_required(side) and int(gold[side]) >= age_cost(side)

func try_advance_age() -> bool:
	return advance_age(-1)

func advance_age(side: int) -> bool:
	if not can_advance(side):
		return false
	gold[side] = int(gold[side]) - age_cost(side)
	age[side] = int(age[side]) + 1
	age_progress[side] = 0.0
	var fort: MarchFortress = human_fort if side == -1 else orc_fort
	fort.set_age(int(age[side]))
	fortress_skin.apply(fort)
	fortress_detail.apply(fort)
	fortress_damage.apply(fort)
	if is_instance_valid(vfx):
		vfx.fortress_event(fort.global_position + Vector3(0, 1.1, 0), side == -1, true)
	add_camera_trauma(0.18 if side == -1 else 0.12)
	if side == -1:
		audio.switch_age(int(age[side]))
	if int(age[side]) == 2:
		hud.announce("IRON AGE — MARCH ON THE STRONGHOLD" if side == -1 else "THE ORCS ENTER THE IRON AGE", 3.5)
	else:
		hud.announce("BRONZE AGE — THE FORGE IS LIT" if side == -1 else "THE ORCS ENTER THE BRONZE AGE", 3.5)
	hud.refresh()
	return true

func toggle_hold() -> void:
	if phase != "playing":
		return
	hold_order = not hold_order
	hud.announce("HOLD NEAR THE FORT" if hold_order else "ADVANCE ON THE STRONGHOLD", 1.7)
	hud.refresh()

func try_repair() -> bool:
	if phase != "playing" or int(repairs_used[-1]) >= 2 or int(gold[-1]) < REPAIR_COST:
		return false
	if not human_fort.repair_gate(REPAIR_AMOUNT):
		return false
	fortress_damage.update(human_fort)
	gold[-1] = int(gold[-1]) - REPAIR_COST
	repairs_used[-1] = int(repairs_used[-1]) + 1
	hud.announce("GATE REPAIRED — %d GOLD" % REPAIR_COST, 1.6)
	hud.refresh()
	return true

func orc_repair() -> void:
	if int(repairs_used[1]) >= 2 or orc_fort.gate_hp <= 0.0 or orc_fort.gate_hp > 240.0:
		return
	if int(gold[1]) >= REPAIR_COST and orc_fort.repair_gate(REPAIR_AMOUNT):
		fortress_damage.update(orc_fort)
		gold[1] = int(gold[1]) - REPAIR_COST
		repairs_used[1] = int(repairs_used[1]) + 1
		hud.announce("ORCS REINFORCE THEIR GATE", 2.0)

func ai_decision() -> void:
	if phase != "playing":
		return
	ai_cycle += 1
	var human_pressure := 0
	for troop in soldiers:
		if troop.side == -1 and troop.position.x > 26.0:
			human_pressure += 1
	if human_pressure >= 2:
		orc_repair()
	if can_advance(1):
		advance_age(1)
	if count_side(1) >= POPULATION_CAP:
		return
	if int(age[1]) < 2 and float(age_progress[1]) >= progress_required(1) * 0.85 and human_pressure < 3 and count_side(1) >= 2:
		return
	var roster := current_roster(1)
	# The opposing army uses a mix of frontline, ranged, and siege troops.
	# Avoid idle turns while humans can keep recruiting on cooldown.
	var preferred := 0
	if ai_cycle % 4 == 0 and human_pressure < 3:
		preferred = 2
	elif ai_cycle % 3 == 0 and count_side(1) > 1:
		preferred = 1
	# Keep defending when a preferred siege or ranged troop is unaffordable.
	if not recruit(str(roster[preferred]), 1) and preferred != 0:
		recruit(str(roster[0]), 1)

func _physics_process(delta: float) -> void:
	if phase != "playing" or get_tree().paused:
		return
	match_time += delta
	for side in [-1, 1]:
		if int(age[side]) < 2:
			age_progress[side] = minf(progress_required(side), float(age_progress[side]) + 0.1 * delta)
	income_clock -= delta
	if income_clock <= 0.0:
		income_clock += INCOME_INTERVAL
		gold[-1] = int(gold[-1]) + INCOME_AMOUNT
		gold[1] = int(gold[1]) + ORC_INCOME_AMOUNT
	ai_clock -= delta
	if ai_clock <= 0.0:
		ai_clock += 1.15
		ai_decision()
	for troop in soldiers.duplicate():
		if phase != "playing":
			break
		if is_instance_valid(troop) and troop.hp > 0.0:
			troop.tick(delta)
	if human_fort.keep_hp <= 0.0:
		end_match(false)
	elif orc_fort.keep_hp <= 0.0:
		end_match(true)
	hud_clock -= delta
	if hud_clock <= 0.0:
		hud_clock = 0.15
		hud.refresh()

func soldier_died(victim: MarchSoldier, attacker_side: int) -> void:
	if not soldiers.has(victim):
		return
	soldiers.erase(victim)
	casualties[victim.side] = int(casualties[victim.side]) + 1
	if is_instance_valid(vfx):
		vfx.burst(victim.global_position + Vector3.UP * 0.85, victim.kind in ["brute", "ram", "ram_beast", "torsion", "ogre_captain"], "wood" if victim.kind in ["ram", "torsion"] else "physical")
	if is_instance_valid(audio):
		audio.play_defeat(victim.side, victim.kind, victim.position.x)
	var reward := maxi(8, int(float(MarchSoldier.CLASSES[victim.kind]["cost"]) / 5.0))
	gold[attacker_side] = int(gold[attacker_side]) + reward
	gain_progress(attacker_side, 0.0, 4.0)
	victim.art.defeat()
	var death_tween := victim.create_tween()
	death_tween.tween_interval(0.82)
	death_tween.tween_property(victim, "scale", Vector3.ONE * 0.03, 0.18)
	death_tween.tween_callback(victim.queue_free)

func on_structure_hit(fort: MarchFortress, part: String, _damage: float) -> void:
	fortress_damage.update(fort)
	var hit_x := fort.gate_x if part == "gate" else fort.keep_x
	add_camera_trauma(0.08 if _damage < 48.0 else 0.14)
	if is_instance_valid(vfx):
		vfx.burst(Vector3(hit_x, 1.25 if part == "gate" else 3.0, 0), part == "gate" and fort.gate_hp <= 0.0, "wood" if part == "gate" else "physical")
	if part == "gate" and fort.gate_hp <= 0.0:
		add_camera_trauma(0.38)
		if is_instance_valid(vfx):
			vfx.fortress_event(Vector3(hit_x, 1.0, 0), fort.side == -1, true)
		if is_instance_valid(audio):
			audio.play_effect("collapse", hit_x, -3.5, true)
		hud.announce("ORC GATE BREACHED — PUSH TO THE KEEP!" if fort.side == 1 else "OUR GATE IS DOWN — DEFEND THE KEEP!", 3.0)
	elif part == "keep" and fort.keep_hp <= 0.0:
		add_camera_trauma(0.55)
		if is_instance_valid(vfx):
			vfx.fortress_event(Vector3(hit_x, 2.4, 0), fort.side == -1, true)
		if is_instance_valid(vfx):
			for offset in [-2.2, 0.0, 2.2]:
				vfx.burst(Vector3(hit_x, 2.6, offset), true, "physical")
		end_match(fort.side == 1)

func end_match(won: bool) -> void:
	if phase != "playing":
		return
	phase = "won" if won else "lost"
	if is_instance_valid(projectiles):
		projectiles.clear()
	audio.end_battle(won)
	var score := OgreWarRecords.record_match(won, match_time, int(casualties[-1]), int(casualties[1]), int(age[-1]), human_fort.keep_hp)
	hud.show_result(won, match_time, int(casualties[-1]), int(casualties[1]), score)

func toggle_pause() -> void:
	if phase != "playing":
		return
	get_tree().paused = not get_tree().paused
	hud.show_paused(get_tree().paused)

func toggle_audio() -> void:
	audio.toggle_enabled()
	hud.refresh()

func run_audio_qa() -> void:
	if is_instance_valid(audio):
		audio.start_audio_qa()

func on_audio_qa_message(message: String) -> void:
	if is_instance_valid(hud):
		hud.announce(message, 1.3)
		hud.set_audio_qa_state(is_instance_valid(audio) and audio.qa_active, message)

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func return_to_home() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/home.tscn")

func focus_human() -> void:
	camera_mode = "free"
	camera_target_x = clamp_camera_x(LEFT_BASE + 13.0)

func focus_enemy() -> void:
	camera_mode = "free"
	camera_target_x = clamp_camera_x(RIGHT_BASE - 12.0)

func focus_front() -> void:
	camera_mode = "front"
	update_front_target()

func update_front_target() -> void:
	var human_front := LEFT_BASE + 12.0
	var orc_front := RIGHT_BASE - 12.0
	for troop in soldiers:
		if troop.side == -1:
			human_front = maxf(human_front, troop.position.x)
		else:
			orc_front = minf(orc_front, troop.position.x)
	camera_target_x = clamp_camera_x((human_front + orc_front) * 0.5)

func camera_limit() -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	var half_width := camera.size * maxf(1.0, viewport_size.x) / maxf(1.0, viewport_size.y) * 0.5
	return maxf(0.0, minf(CAMERA_MAX_TARGET_X, PLAYFIELD_HALF_LENGTH - half_width - CAMERA_EDGE_BUFFER))

func clamp_camera_x(x: float) -> float:
	var limit := camera_limit()
	return clampf(x, -limit, limit)

func set_camera_x(x: float, shake_y: float = 0.0) -> void:
	camera.position = Vector3(x, 23.5 + shake_y, 39.0)
	camera.look_at(Vector3(x, 1.1 + shake_y * 0.28, 0))

func add_camera_trauma(amount: float) -> void:
	camera_trauma = clampf(camera_trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if camera_mode == "front" and phase == "playing":
		update_front_target()
	camera_target_x = clamp_camera_x(camera_target_x)
	camera_trauma = maxf(0.0, camera_trauma - delta * 1.85)
	camera_shake_phase += delta * 31.0
	var x: float = lerpf(camera.position.x, camera_target_x, 1.0 - exp(-7.0 * delta))
	var strength := camera_trauma * camera_trauma
	var shake_x := sin(camera_shake_phase) * 0.24 * strength
	var shake_y := sin(camera_shake_phase * 1.61 + 0.7) * 0.18 * strength
	set_camera_x(x + shake_x, shake_y)

func _unhandled_input(event: InputEvent) -> void:
	if phase != "playing" or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_finger == -1 and _is_battlefield_touch(event.position):
			touch_finger = event.index
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_zoom_at(event.position.x, 0.90 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.10)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and touch_finger == -1:
		mouse_drag = true
	if event is InputEventScreenDrag and touch_finger == event.index and touch_points.size() <= 1:
		pan_by(event.relative.x)
	elif event is InputEventMouseMotion and mouse_drag and touch_finger == -1:
		pan_by(event.relative.x)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _is_battlefield_touch(event.position):
			touch_points[event.index] = event.position
			if touch_finger == -1:
				touch_finger = event.index
			if touch_points.size() > 1:
				mouse_drag = false
		elif not event.pressed:
			touch_points.erase(event.index)
			if touch_finger == event.index:
				touch_finger = int(touch_points.keys()[0]) if not touch_points.is_empty() else -1
	elif event is InputEventScreenDrag and touch_points.has(event.index):
		var keys := touch_points.keys()
		if keys.size() == 2 and phase == "playing" and not get_tree().paused:
			var first: Vector2 = touch_points[keys[0]]
			var second: Vector2 = touch_points[keys[1]]
			var old_distance := first.distance_to(second)
			var old_midpoint := (first + second) * 0.5
			touch_points[event.index] = event.position
			first = touch_points[keys[0]]
			second = touch_points[keys[1]]
			var new_distance := first.distance_to(second)
			if old_distance > 16.0 and new_distance > 16.0:
				_zoom_from_pinch(old_midpoint.x, (first.x + second.x) * 0.5, old_distance / new_distance)
		else:
			touch_points[event.index] = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		mouse_drag = false

func _is_battlefield_touch(position: Vector2) -> bool:
	var height := get_viewport().get_visible_rect().size.y
	return position.y >= 148.0 and position.y < height - 110.0

func _zoom_at(screen_x: float, scale: float) -> void:
	_zoom_from_pinch(screen_x, screen_x, scale)

func _zoom_from_pinch(old_screen_x: float, new_screen_x: float, scale: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var viewport_height := maxf(1.0, viewport_size.y)
	var center_x := viewport_size.x * 0.5
	var world_under_fingers := camera_target_x + (old_screen_x - center_x) * camera.size / viewport_height
	camera.size = clampf(camera.size * scale, CAMERA_CLOSE_SIZE, CAMERA_WIDE_SIZE)
	camera_target_x = clamp_camera_x(world_under_fingers - (new_screen_x - center_x) * camera.size / viewport_height)
	camera_mode = "free"

func pan_by(pixels: float) -> void:
	camera_mode = "free"
	var viewport_width := maxf(1.0, get_viewport().get_visible_rect().size.x)
	var world_width := camera.size * viewport_width / maxf(1.0, get_viewport().get_visible_rect().size.y)
	camera_target_x = clamp_camera_x(camera_target_x - pixels * world_width / viewport_width)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		mouse_drag = false
		touch_finger = -1
		touch_points.clear()
		if is_instance_valid(hud) and phase == "playing":
			get_tree().paused = true
			hud.show_paused(true)
