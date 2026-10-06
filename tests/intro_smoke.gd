extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OgreWarIntro.SEEN_PATH))
	change_scene_to_file("res://scenes/home.tscn")
	await create_timer(0.2).timeout
	if not current_scene is OgreWarIntro:
		fail("First launch did not open the cinematic")
		return
	var intro: OgreWarIntro = current_scene
	if not is_instance_valid(intro.video) or intro.video.stream == null:
		fail("Cinematic stream is missing")
		return
	if intro.video.get_stream_length() < 23.0 or not intro.video.is_playing():
		fail("Cinematic did not start or has the wrong duration")
		return
	intro._finish_intro()
	await create_timer(0.12).timeout
	if not current_scene is OgreWarHome or not OgreWarIntro.has_seen_intro():
		fail("Skip did not return to the war room")
		return
	current_scene._on_cinematic()
	await create_timer(0.12).timeout
	if not current_scene is OgreWarIntro:
		fail("Watch Story did not replay the cinematic")
		return
	current_scene._finish_intro()
	await create_timer(0.12).timeout
	if not current_scene is OgreWarHome:
		fail("Replay did not return to the war room")
		return
	print("Ogre War first-launch / skip / replay intro checks passed.")
	quit(0)

func fail(reason: String) -> void:
	push_error(reason)
	quit(1)
