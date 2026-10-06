extends SceneTree

const TEST_RECORDS := "user://ogre_war_records_smoke.json"

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORDS))
	var home_scene: PackedScene = load("res://scenes/home.tscn")
	var home: Control = home_scene.instantiate()
	root.add_child(home)
	await process_frame
	assert(home.get_child_count() >= 2)
	var records := OgreWarRecords.load_records(TEST_RECORDS)
	assert(int(records["battles"]) == 0)
	var first := OgreWarRecords.record_match(true, 125.0, 3, 14, 1, 400.0, TEST_RECORDS)
	assert(first > 1000)
	records = OgreWarRecords.load_records(TEST_RECORDS)
	assert(int(records["wins"]) == 1 and int(records["losses"]) == 0)
	assert(int(records["best_score"]) == first)
	assert(int(records["fastest_win"]) == 125)
	assert(int(records["ogres_defeated"]) == 14)
	OgreWarRecords.record_match(false, 180.0, 8, 5, 2, 0.0, TEST_RECORDS)
	records = OgreWarRecords.load_records(TEST_RECORDS)
	assert(int(records["battles"]) == 2 and int(records["losses"]) == 1)
	assert(int(records["best_score"]) == first and int(records["best_age"]) == 2)
	assert(records["last_result"] == "DEFEAT")
	var broken := FileAccess.open(TEST_RECORDS, FileAccess.WRITE)
	broken.store_string("invalid json")
	broken.close()
	assert(int(OgreWarRecords.load_records(TEST_RECORDS)["battles"]) == 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORDS))
	home.queue_free()
	print("Ogre War home and records smoke checks passed.")
	quit(0)
