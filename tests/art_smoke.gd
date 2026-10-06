extends SceneTree

var failures := 0
const HUMAN_TYPES := ["hunter", "slinger", "hauler", "shield", "bowman", "ram", "swordsman", "lancer", "torsion"]

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func run_checks() -> void:
	var arena := Node3D.new()
	root.add_child(arena)
	check(MarchSoldier.CLASSES.size() == 18, "Eighteen troop definitions")
	for kind_value in MarchSoldier.CLASSES.keys():
		var kind := str(kind_value)
		var unit := MarchSoldier.new()
		arena.add_child(unit)
		unit.make(kind, -1 if kind in HUMAN_TYPES else 1, arena)
		check(is_instance_valid(unit.art), kind + " creates OgreWarUnitVisual")
		if kind in OgreWarUnitVisual.SIEGE_KINDS:
			check(is_instance_valid(unit.art.siege), kind + " creates authored siege visual")
			check(unit.art.siege.get_child_count() > 0, kind + " siege visual has geometry/crew")
		else:
			check(is_instance_valid(unit.art.visual), kind + " loads Castlehold-derived rigged model")
			check(is_instance_valid(unit.art.animator), kind + " has AnimationPlayer")
			if is_instance_valid(unit.art.animator):
				check(unit.art.animator.has_animation("idle"), kind + " has idle animation")
				check(unit.art.animator.has_animation("defeat"), kind + " has defeat animation")
		unit.art.moved()
		unit.art.march(0.016, 0.9)
		unit.art.impact()
		unit.art.march(0.016, 1.3)
		check(unit.art.attack_time > 0.0 or is_instance_valid(unit.art.siege), kind + " responds to attack presentation")
		unit.queue_free()
	await process_frame
	if failures == 0:
		print("Ogre War current character/siege art smoke checks passed.")
	arena.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
