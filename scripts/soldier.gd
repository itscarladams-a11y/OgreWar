class_name MarchSoldier
extends Node3D

const CLASSES := {
	"hunter": {"title": "Spear Hunter", "hp": 110.0, "damage": 20.0, "speed": 4.2, "range": 1.9, "interval": 1.1, "cost": 65, "cooldown": 2.4, "structure": 1.0, "ranged": false, "color": "849e9b"},
	"slinger": {"title": "Sling Skirmisher", "hp": 73.0, "damage": 16.0, "speed": 3.8, "range": 8.0, "interval": 1.9, "cost": 84, "cooldown": 3.0, "structure": 0.4, "ranged": true, "color": "b6a887"},
	"hauler": {"title": "Stone Hauler", "hp": 260.0, "damage": 26.0, "speed": 2.7, "range": 2.1, "interval": 1.65, "cost": 145, "cooldown": 5.0, "structure": 2.8, "ranged": false, "color": "887f76"},
	"raider": {"title": "Bone Raider", "hp": 100.0, "damage": 19.0, "speed": 4.25, "range": 1.9, "interval": 1.1, "cost": 63, "cooldown": 2.4, "structure": 1.0, "ranged": false, "color": "8d6953"},
	"thrower": {"title": "Rock Thrower", "hp": 70.0, "damage": 15.0, "speed": 3.75, "range": 8.0, "interval": 1.85, "cost": 82, "cooldown": 3.0, "structure": 0.4, "ranged": true, "color": "998669"},
	"brute": {"title": "Cave Ogre", "hp": 270.0, "damage": 27.0, "speed": 2.55, "range": 2.4, "interval": 1.7, "cost": 148, "cooldown": 5.4, "structure": 2.8, "ranged": false, "color": "696a57"},
	"shield": {"title": "Bronze Shield", "hp": 230.0, "damage": 25.0, "speed": 3.45, "range": 2.0, "interval": 1.2, "cost": 115, "cooldown": 3.1, "structure": 0.85, "ranged": false, "armor": 0.44, "color": "687e78"},
	"bowman": {"title": "Recurve Bowman", "hp": 95.0, "damage": 30.0, "speed": 3.5, "range": 9.1, "interval": 1.65, "cost": 135, "cooldown": 3.3, "structure": 0.5, "ranged": true, "color": "a4916b"},
	"ram": {"title": "Bronze Ram", "hp": 340.0, "damage": 20.0, "speed": 2.2, "range": 2.5, "interval": 1.85, "cost": 205, "cooldown": 6.0, "structure": 4.6, "ranged": false, "color": "89684a"},
	"orc_guard": {"title": "Orc Bulwark", "hp": 225.0, "damage": 25.0, "speed": 3.4, "range": 2.0, "interval": 1.2, "cost": 115, "cooldown": 3.1, "structure": 0.85, "ranged": false, "armor": 0.44, "color": "59614d"},
	"horn_bow": {"title": "Horn Bowman", "hp": 93.0, "damage": 29.0, "speed": 3.45, "range": 9.1, "interval": 1.65, "cost": 133, "cooldown": 3.3, "structure": 0.5, "ranged": true, "color": "76684f"},
	"ram_beast": {"title": "Ram Beast", "hp": 350.0, "damage": 21.0, "speed": 2.15, "range": 2.5, "interval": 1.9, "cost": 208, "cooldown": 6.1, "structure": 4.6, "ranged": false, "color": "5c604e"},
	"swordsman": {"title": "Iron Swordsman", "hp": 305.0, "damage": 34.0, "speed": 3.35, "range": 2.1, "interval": 1.15, "cost": 170, "cooldown": 3.4, "structure": 0.9, "ranged": false, "armor": 0.48, "melee_armor": 0.16, "color": "606e75"},
	"lancer": {"title": "Armored Lancer", "hp": 220.0, "damage": 32.0, "speed": 4.65, "range": 2.6, "interval": 1.3, "cost": 188, "cooldown": 3.8, "structure": 0.75, "ranged": false, "anti_heavy": 1.65, "anti_charge": 0.42, "color": "82919a"},
	"torsion": {"title": "Torsion Crew", "hp": 175.0, "damage": 29.0, "speed": 2.15, "range": 10.3, "interval": 2.45, "cost": 280, "cooldown": 6.3, "structure": 4.1, "ranged": true, "pierce": 0.65, "color": "77746e"},
	"iron_breaker": {"title": "Ironclad Breaker", "hp": 345.0, "damage": 33.0, "speed": 3.0, "range": 2.2, "interval": 1.3, "cost": 175, "cooldown": 3.5, "structure": 1.05, "ranged": false, "armor": 0.45, "melee_armor": 0.17, "color": "4f5450"},
	"warg": {"title": "Warg Outrider", "hp": 185.0, "damage": 34.0, "speed": 5.3, "range": 2.1, "interval": 1.3, "cost": 187, "cooldown": 3.8, "structure": 0.7, "ranged": false, "charge": 1.7, "color": "696859"},
	"ogre_captain": {"title": "Ogre Siege Captain", "hp": 460.0, "damage": 40.0, "speed": 2.2, "range": 2.7, "interval": 1.85, "cost": 285, "cooldown": 6.5, "structure": 3.6, "ranged": false, "color": "535849"}
}

var kind := "hunter"
var side := -1
var hp := 100.0
var max_hp := 100.0
var stats: Dictionary = {}
var attack_clock := 0.0
var walk_phase := 0.0
var art: OgreWarUnitVisual
var game
var era := 0
var charge_distance := 0.0
var step_fx_clock := 0.0

func make(which_kind: String, which_side: int, arena: Node3D) -> void:
	kind = which_kind
	side = which_side
	game = arena
	stats = CLASSES[kind]
	era = 2 if kind in ["swordsman", "lancer", "torsion", "iron_breaker", "warg", "ogre_captain"] else (1 if kind in ["shield", "bowman", "ram", "orc_guard", "horn_bow", "ram_beast"] else 0)
	max_hp = float(stats["hp"])
	hp = max_hp
	name = str(stats["title"])
	art = OgreWarUnitVisual.new()
	add_child(art)
	art.make(kind, side, stats, era)

func tick(delta: float) -> void:
	if hp <= 0.0:
		return
	attack_clock = maxf(0.0, attack_clock - delta)
	step_fx_clock = maxf(0.0, step_fx_clock - delta)
	art.march(delta, walk_phase)
	var target := _find_target()
	# Rams are gate-breakers first. They only peel off for an enemy already on top of them.
	if kind in ["ram", "ram_beast"] and is_instance_valid(target) and absf(target.position.x - position.x) > 2.65:
		target = null
	if is_instance_valid(target):
		var nearest: float = absf(target.position.x - position.x)
		var reach: float = float(stats["range"]) + (0.45 if target.kind in ["brute", "hauler", "ram", "ram_beast", "iron_breaker", "torsion", "ogre_captain"] else 0.0)
		if nearest <= reach:
			strike_soldier(target)
		elif bool(stats["ranged"]):
			move_ranged_support(target, delta, reach)
		else:
			walk_towards(target.position.x, delta)
		return

	var opposing_fort: MarchFortress = game.orc_fort if side == -1 else game.human_fort
	var objective := opposing_fort.gate_x if opposing_fort.gate_hp > 0.0 else opposing_fort.keep_x
	var desired := objective
	if side == -1 and game.hold_order:
		desired = -32.0
	var siege_reach: float = float(stats["range"]) if bool(stats["ranged"]) else (2.4 if opposing_fort.gate_hp > 0.0 else 3.0)
	if absf(position.x - objective) <= siege_reach and (side != -1 or not game.hold_order):
		if attack_clock <= 0.0:
			attack_clock = float(stats["interval"])
			art.impact()
			game.audio.play_attack(kind, position.x, false, true)
			var amount: float = float(stats["damage"]) * float(stats["structure"])
			var part := "gate" if opposing_fort.gate_hp > 0.0 else "keep"
			if bool(stats["ranged"]):
				game.projectiles.launch_structure(self, opposing_fort, part, amount)
			else:
				var remaining: float = opposing_fort.gate_hp if part == "gate" else opposing_fort.keep_hp
				game.gain_progress(side, minf(amount, remaining))
				if part == "gate":
					opposing_fort.damage_gate(amount)
					game.on_structure_hit(opposing_fort, "gate", amount)
				else:
					opposing_fort.damage_keep(amount)
					game.on_structure_hit(opposing_fort, "keep", amount)
		return
	if bool(stats["ranged"]):
		move_ranged_to_objective(objective, delta, siege_reach)
	else:
		walk_towards(desired, delta)

func _find_target() -> MarchSoldier:
	var enemy_side := -side
	var target: MarchSoldier = null
	var nearest := INF
	var sensing_range := maxf(12.0, float(stats["range"]) + 4.0) if bool(stats["ranged"]) else 9.5
	for candidate in game.soldiers:
		if candidate.side != enemy_side or candidate.hp <= 0.0:
			continue
		if side == -1 and game.hold_order and candidate.position.x > -26.0:
			continue
		var dx: float = absf(candidate.position.x - position.x)
		if dx < nearest and dx <= sensing_range:
			nearest = dx
			target = candidate
	return target

func move_ranged_support(target: MarchSoldier, delta: float, reach: float) -> void:
	# Ranged units intentionally form a second line behind living melee troops.
	# This replaces the old behavior where they walked into a friendly back and
	# simply stopped shooting because they could not close the last few meters.
	var front_found := false
	var front_x := -INF if side == -1 else INF
	for ally in game.soldiers:
		if ally == self or ally.side != side or ally.hp <= 0.0 or bool(ally.stats["ranged"]):
			continue
		front_found = true
		front_x = maxf(front_x, ally.position.x) if side == -1 else minf(front_x, ally.position.x)
	var desired: float
	if front_found:
		desired = front_x + float(side) * 3.15
	else:
		desired = target.position.x + float(side) * maxf(1.0, reach - 0.55)
	if side == -1 and game.hold_order:
		desired = minf(desired, -32.0)
	walk_towards(desired, delta, true)

func move_ranged_to_objective(objective: float, delta: float, reach: float) -> void:
	if side == -1 and game.hold_order:
		walk_towards(-32.0, delta, true)
		return
	var firing_line := objective + float(side) * maxf(1.0, reach - 0.55)
	walk_towards(firing_line, delta, true)

func strike_soldier(target: MarchSoldier) -> void:
	if attack_clock > 0.0 or not is_instance_valid(target) or target.hp <= 0.0:
		return
	attack_clock = float(stats["interval"])
	art.impact()
	var shield_contact := target.kind in ["shield", "orc_guard"]
	game.audio.play_attack(kind, position.x, shield_contact)
	if kind == "ogre_captain":
		game.audio.play_effect("boss_slam", position.x, -6.0)
	var damage: float = float(stats["damage"])
	if kind == "lancer" and target.kind in ["hauler", "brute", "ram", "ram_beast", "torsion", "iron_breaker", "ogre_captain"]:
		damage *= float(stats["anti_heavy"])
	if bool(stats["ranged"]):
		game.projectiles.launch_unit(self, target, damage)
		return
	var charged := float(stats.get("charge", 1.0)) > 1.0 and charge_distance >= 4.0
	if charged:
		damage *= float(stats["charge"])
	charge_distance = 0.0
	var dealt: float = target.take_hit(damage, self, charged)
	game.gain_progress(side, dealt)

func walk_towards(x_target: float, delta: float, allow_lane_shift: bool = false) -> void:
	if absf(x_target - position.x) < 0.16:
		return
	var travel_direction: float = signf(x_target - position.x)
	for ally in game.soldiers:
		if ally == self or ally.side != side or ally.hp <= 0.0:
			continue
		var gap: float = (ally.position.x - position.x) * travel_direction
		var spacing: float = body_radius() + ally.body_radius()
		if gap > 0.0 and gap < spacing and absf(ally.position.z - position.z) < maxf(0.62, spacing * 0.48):
			if allow_lane_shift:
				var shift_direction := -1.0 if position.z >= ally.position.z else 1.0
				if absf(position.z) > 2.15:
					shift_direction = -signf(position.z)
				position.z = clampf(position.z + shift_direction * float(stats["speed"]) * delta * 0.52, -2.35, 2.35)
				walk_phase += delta * float(stats["speed"]) * 3.2
				art.moved()
			return
	var step := minf(float(stats["speed"]) * delta, absf(x_target - position.x))
	position.x += travel_direction * step
	charge_distance = minf(10.0, charge_distance + step)
	walk_phase += delta * float(stats["speed"]) * 5.0
	art.moved()
	if step_fx_clock <= 0.0 and kind in ["brute", "ogre_captain", "iron_breaker", "warg", "ram_beast", "lancer"] and is_instance_valid(game.vfx):
		step_fx_clock = 0.34 if kind in ["warg", "lancer"] else 0.46
		game.vfx.footstep_dust(global_position + Vector3(0, 0.02, 0), kind in ["brute", "ogre_captain", "ram_beast"])


func body_radius() -> float:
	if kind in ["ram", "torsion", "ram_beast"]:
		return 1.12
	if kind in ["brute", "ogre_captain", "hauler", "lancer", "warg"]:
		return 0.82
	return 0.56

func take_hit(amount: float, attacker: MarchSoldier, charged: bool = false) -> float:
	if not is_instance_valid(attacker):
		return 0.0
	return _apply_damage(amount, attacker.side, attacker.kind, bool(attacker.stats["ranged"]), charged)

func take_ranged_hit(amount: float, attacker_side: int, attacker_kind: String) -> float:
	return _apply_damage(amount, attacker_side, attacker_kind, true, false)

func _apply_damage(amount: float, attacker_side: int, attacker_kind: String, ranged_attack: bool, charged: bool) -> float:
	if hp <= 0.0 or not CLASSES.has(attacker_kind):
		return 0.0
	var attacker_stats: Dictionary = CLASSES[attacker_kind]
	if ranged_attack:
		amount *= 1.0 - float(stats.get("armor", 0.0)) * (1.0 - float(attacker_stats.get("pierce", 0.0)))
	else:
		amount *= 1.0 - float(stats.get("melee_armor", 0.0))
	if charged:
		amount *= 1.0 - float(stats.get("anti_charge", 0.0))
	var dealt := minf(hp, amount)
	hp = maxf(0.0, hp - amount)
	if is_instance_valid(game.audio):
		game.audio.play_body_hit(position.x)
	if is_instance_valid(game.vfx):
		var impact_element := "physical"
		if attacker_kind in ["swordsman", "lancer", "orc_guard", "iron_breaker"]:
			impact_element = "metal"
		elif attacker_kind in ["hunter", "bowman", "horn_bow", "torsion"]:
			impact_element = "pierce"
		elif attacker_kind in ["slinger", "thrower"]:
			impact_element = "stone"
		elif attacker_kind in ["raider", "brute", "ogre_captain", "hauler", "warg", "ram_beast"]:
			impact_element = "wood"
		game.vfx.burst(global_position + Vector3.UP * 1.0, charged or amount >= 36.0, impact_element)
	if (charged or amount >= 36.0) and game.has_method("add_camera_trauma"):
		game.add_camera_trauma(0.10 if amount < 55.0 else 0.16)
	if hp <= 0.0:
		game.soldier_died(self, attacker_side)
	else:
		art.hurt()
	return dealt
