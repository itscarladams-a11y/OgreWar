extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run_checks() -> void:
	var bus_count_before := AudioServer.bus_count
	var master_effects_before := AudioServer.get_bus_effect_count(0)
	var game := MarchMatch.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	var report: Dictionary = game.audio.audio_health_report()
	check(bool(report.get("ok", false)), "Audio health report passes")
	check(game.audio.tracks.size() == 3, "Three age-specific music tracks loaded")
	check(game.audio.tracks[0].playing, "Stone music starts at battle launch")
	for index in range(game.audio.tracks.size()):
		var stream: AudioStream = game.audio.tracks[index].stream
		check(stream != null and stream.get_length() > 10.0, "Age %d music is playable" % index)
		if stream is AudioStreamWAV:
			check((stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "WAV age music loops")
		elif stream is AudioStreamOggVorbis:
			check((stream as AudioStreamOggVorbis).loop, "OGG age music loops")
	for unit_kind in MarchSoldier.CLASSES.keys():
		check(game.audio.ATTACK_SOUND.has(unit_kind), "Attack sound assigned: " + str(unit_kind))
		check(game.audio.effects.has(game.audio.ATTACK_SOUND.get(unit_kind, "")), "Attack stream loaded: " + str(unit_kind))
	check(AudioServer.get_bus_index(game.audio.MUSIC_BUS) >= 0, "Music bus exists")
	check(AudioServer.get_bus_index(game.audio.COMBAT_BUS) >= 0, "Combat bus exists")
	check(AudioServer.get_bus_index(game.audio.VOICE_BUS) >= 0, "Voice bus exists")
	game.audio.play_attack("hunter", game.camera.position.x)
	var any_voice := false
	for voice in game.audio.voices:
		if voice.playing:
			any_voice = true
	check(any_voice, "Battle attack creates an audio voice")
	game.audio.start_audio_qa()
	check(game.audio.qa_active and game.audio.qa_steps.size() == 29, "Audio QA sequence contains 3 music + 23 SFX + 3 death-bank checks")
	game.audio.stop_audio_qa(true)
	game.audio.toggle_enabled()
	check(not game.audio.enabled, "Mute disables audio")
	game.audio.toggle_enabled()
	check(game.audio.enabled and game.audio.tracks[game.audio.current_age].playing, "Audio restores current age track")
	game.free()
	check(AudioServer.bus_count == bus_count_before, "Battle audio removes its temporary mixer buses")
	check(AudioServer.get_bus_effect_count(0) == master_effects_before, "Battle audio removes its temporary limiter")
	await create_timer(1.0).timeout
	if failures == 0:
		print("Ogre War age music, SFX, death-bank and audio-QA smoke checks passed.")
	quit(1 if failures > 0 else 0)
