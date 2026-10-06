extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OgreWarIntro.SEEN_PATH))
	change_scene_to_file("res://scenes/studio_splash.tscn")
	await create_timer(0.15).timeout
	if not current_scene is OgreWarStudioSplash:
		fail("Startup did not show the Bantam studio screen")
		return
	var splash: OgreWarStudioSplash = current_scene
	if splash.target_scene != "res://scenes/intro.tscn":
		fail("First install should load the opening story")
		return
	if splash.get_node_or_null("BantamLoadingArtwork") == null or splash.progress_bar == null:
		fail("The approved studio artwork or live loading bar is missing")
		return
	if splash.progress_bar.value < 0.0 or splash.progress_bar.value > 100.0:
		fail("Startup progress is out of bounds")
		return
	await create_timer(1.6).timeout
	if not current_scene is OgreWarIntro:
		fail("First launch did not reach the cinematic")
		return
	current_scene._finish_intro()
	await create_timer(0.15).timeout
	if not current_scene is OgreWarHome or not OgreWarIntro.has_seen_intro():
		fail("The cinematic did not return to the war room")
		return
	if current_scene.get_node_or_null("BantamEntertainmentLogo") == null:
		fail("The war room is missing the Bantam logo")
		return
	change_scene_to_file("res://scenes/studio_splash.tscn")
	await create_timer(0.15).timeout
	if not current_scene is OgreWarStudioSplash or current_scene.target_scene != "res://scenes/home.tscn":
		fail("Later launches should load the war room")
		return
	await create_timer(1.6).timeout
	if not current_scene is OgreWarHome:
		fail("Later launch did not reach the war room")
		return
	print("Bantam startup artwork, real progress, cinematic route, and returning launch passed.")
	quit(0)

func fail(reason: String) -> void:
	if current_scene is OgreWarStudioSplash:
		var splash: OgreWarStudioSplash = current_scene
		print("Startup state: target=", splash.target_scene, ", progress=", splash.progress_bar.value, ", status=", splash.stage_label.text, ", loading=", splash._loading)
	elif current_scene != null:
		print("Current scene: ", current_scene.name)
	push_error(reason)
	quit(1)
