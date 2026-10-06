extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	OgreWarIntro.mark_seen()
	change_scene_to_file("res://scenes/home.tscn")
	await create_timer(0.1).timeout
	if not current_scene is OgreWarHome:
		fail("Home scene did not open")
		return
	current_scene._on_play()
	await create_timer(0.1).timeout
	if current_scene == null or current_scene.name != "OgreWarLoading":
		fail("Loading scene did not open")
		return
	await create_timer(1.65).timeout
	if not current_scene is MarchMatch:
		fail("Battle scene did not open")
		return
	if root.find_child("OgreWarLoading", true, false) != null:
		fail("Loading cover did not release after the battlefield appeared")
		return
	current_scene.return_to_home()
	await create_timer(0.1).timeout
	if not current_scene is OgreWarHome:
		fail("Return to home failed")
		return
	print("Ogre War home → loading → battle → home flow passed.")
	quit(0)

func fail(reason: String) -> void:
	push_error(reason)
	quit(1)
