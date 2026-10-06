extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func run_checks() -> void:
	var game := MarchMatch.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	var veteran: MarchSoldier = game.soldiers[0]
	var human_stone_arch: Node3D = game.human_fort.architecture
	game.human_fort.damage_gate(120.0)
	var gate_before: float = game.human_fort.gate_hp
	var keep_before: float = game.human_fort.keep_hp
	game.gold[-1] = 1000
	game.age_progress[-1] = 100.0
	check(game.can_advance(-1), "Stone advance unlocks at the progress and gold thresholds")
	check(game.advance_age(-1), "Human Bronze purchase succeeds")
	check(game.audio.current_age == 1 and game.audio.tracks[1].playing, "Bronze battle music starts")
	check(int(game.age[-1]) == 1 and int(game.gold[-1]) == 780, "Bronze charges 220 gold")
	check(game.human_fort.age == 1 and game.human_fort.gate_hp == gate_before, "Bronze appearance keeps gate damage")
	check(game.human_fort.keep_hp == keep_before and human_stone_arch.get_parent() == null, "Bronze replaces old architecture")
	var human_bronze_arch: Node3D = game.human_fort.architecture
	check(human_bronze_arch.name == "Human Bronze Castle", "Bronze has distinct castle architecture")
	check(veteran.era == 0 and veteran.kind == "hunter", "Old Stone soldier remains Stone")
	check(not game.can_advance(-1), "Iron is locked until new progress is earned")
	check(game.current_roster(-1) == ["shield", "bowman", "ram"], "Human Bronze roster")
	var bronze_veteran: MarchSoldier = game.spawn_soldier("shield", -1)
	game.age_progress[-1] = 150.0
	check(game.advance_age(-1), "Human Iron purchase succeeds")
	check(game.audio.current_age == 2 and game.audio.tracks[2].playing and not game.audio.tracks[0].playing, "Iron music replaces the previous age")
	check(int(game.age[-1]) == 2 and int(game.gold[-1]) == 420, "Iron charges 360 gold")
	check(game.human_fort.age == 2 and game.human_fort.gate_hp == gate_before, "Iron appearance keeps gate damage")
	check(game.human_fort.keep_hp == keep_before and human_bronze_arch.get_parent() == null, "Iron replaces Bronze architecture")
	check(game.human_fort.architecture.name == "Human Iron Citadel", "Iron has distinct castle architecture")
	check(game.current_roster(-1) == ["swordsman", "lancer", "torsion"], "Human Iron roster")
	check(veteran.era == 0 and veteran.kind == "hunter", "Stone soldier remains Stone after Iron upgrade")
	check(bronze_veteran.era == 1 and bronze_veteran.kind == "shield", "Bronze soldier remains Bronze after Iron upgrade")
	check(int(game.age[1]) == 0 and game.orc_fort.age == 0, "Orcs can still be Stone while humans are Iron")
	check(not game.can_advance(-1), "Iron is the last age")
	check(not game.recruit("shield", -1), "Previous roster cannot be newly recruited")
	check(game.recruit("swordsman", -1), "Iron soldier is recruitable")
	check(game.soldiers.back().era == 2, "New Iron soldier keeps its era")
	game.orc_fort.damage_gate(MarchFortress.GATE_MAX)
	game.orc_fort.damage_keep(100.0)
	var orc_keep_before: float = game.orc_fort.keep_hp
	game.gold[1] = 1000
	game.age_progress[1] = 100.0
	game.ai_decision()
	check(int(game.age[1]) == 1 and game.orc_fort.age == 1, "Orc AI independently buys Bronze")
	game.age_progress[1] = 150.0
	game.ai_decision()
	check(int(game.age[1]) == 2 and game.orc_fort.age == 2, "Orc AI independently buys Iron")
	check(game.audio.current_age == 2, "Orc upgrades do not change the human battle theme")
	check(game.orc_fort.gate_hp == 0.0 and game.orc_fort.keep_hp == orc_keep_before, "Rebuilding a breached fortress does not heal its gate or keep")
	check(game.current_roster(1) == ["iron_breaker", "warg", "ogre_captain"], "Orc Iron roster")
	check(game.orc_fort.architecture.name == "Ogre Iron Citadel", "Ogre Iron silhouette is its own model")
	var human_keep: BoxMesh = game.human_fort.keep_mesh.mesh as BoxMesh
	var ogre_keep: BoxMesh = game.orc_fort.keep_mesh.mesh as BoxMesh
	check(ogre_keep.size.y > human_keep.size.y and ogre_keep.size.z > human_keep.size.z, "Ogre keep is larger")
	var human_material: StandardMaterial3D = game.human_fort.keep_mesh.material_override as StandardMaterial3D
	var ogre_material: StandardMaterial3D = game.orc_fort.keep_mesh.material_override as StandardMaterial3D
	check(ogre_material.albedo_color.get_luminance() < human_material.albedo_color.get_luminance(), "Ogre masonry is darker")
	game.age_progress[-1] = 0.0
	game.gain_progress(-1, 100.0)
	check(float(game.age_progress[-1]) == 0.0, "No age progress accumulates after Iron")
	if failures == 0:
		print("Ogre War age smoke checks passed.")
	game.free()
	await create_timer(1.0).timeout
	quit(1 if failures > 0 else 0)
