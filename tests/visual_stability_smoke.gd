extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func mesh_count(node: Node) -> int:
	var result := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		result += mesh_count(child)
	return result

func find_named(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child in node.get_children():
		var found := find_named(child, wanted)
		if found != null:
			return found
	return null

func run_checks() -> void:
	var game := MarchMatch.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	var sun := find_named(game, "Valley Sun") as DirectionalLight3D
	check(is_instance_valid(sun), "Valley Sun exists")
	if is_instance_valid(sun):
		check(sun.shadow_enabled, "Bounded directional shadows are enabled")
		check(sun.directional_shadow_max_distance <= 60.0, "Shadow distance stays mobile-bounded")
	check(find_named(game, "Valley Environment") is WorldEnvironment, "World environment exists")
	var grass := find_named(game, "Instanced Valley Grass") as MultiMeshInstance3D
	check(is_instance_valid(grass) and grass.multimesh.instance_count >= 400, "Valley vegetation uses an instanced draw instead of hundreds of nodes")
	check(is_instance_valid(game.vfx) and game.vfx.slots.size() == OgreWarBattleVFX.SLOT_COUNT, "VFX pool is preallocated")
	check(is_instance_valid(game.projectiles) and game.projectiles.slots.size() == OgreWarProjectilePool.SLOT_COUNT, "Projectile pool is preallocated")
	var attacker: MarchSoldier = game.soldiers[0]
	var victim: MarchSoldier = game.soldiers[1]
	victim.position.x = attacker.position.x + 1.0
	var before := mesh_count(game)
	for strike in 3:
		attacker.attack_clock = 0.0
		attacker.strike_soldier(victim)
		check(mesh_count(game) == before, "Melee strike %d uses pooled/prebuilt visuals" % strike)
	check(victim.hp < victim.max_hp and victim.hp > 0.0, "Melee attacks still apply damage")
	var fort_children := game.human_fort.get_node("Fortress Damage State").get_child_count()
	game.fortress_damage.update(game.human_fort)
	check(game.human_fort.get_node("Fortress Damage State").get_child_count() == fort_children, "Unchanged fortress stage does not allocate more damage geometry")
	if failures == 0:
		print("Ogre War current lighting, pooled VFX and visual-stability smoke checks passed.")
	game.free()
	await create_timer(1.0).timeout
	quit(1 if failures > 0 else 0)
