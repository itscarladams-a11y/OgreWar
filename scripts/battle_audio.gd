class_name OgreWarAudio
extends Node

const MUSIC_BUS := "Ogre War Music"
const COMBAT_BUS := "Ogre War Combat"
const VOICE_BUS := "Ogre War Voices"

# Castlehold-first audio rebuild. The Stone-age bed and several battlefield
# effects come from the latest Castlehold archive. Ogre War's own age-specific
# weapon effects remain where Castlehold has no equivalent.
const MUSIC_PATHS := [
	"res://assets/castlehold/audio/valley_watch.ogg",
	"res://assets/audio/music_bronze.wav",
	"res://assets/audio/music_iron.wav"
]
const MUSIC_DB := -9.5
const ATTACK_SOUND := {
	"hunter": "bone_spear", "slinger": "stone_sling", "hauler": "stone_rock",
	"raider": "stone_club", "thrower": "stone_rock", "brute": "ogre_club",
	"shield": "bronze_shield", "bowman": "castlehold_bow", "ram": "ram",
	"orc_guard": "bronze_blade", "horn_bow": "castlehold_bow", "ram_beast": "ram",
	"swordsman": "iron_sword", "lancer": "iron_lance", "torsion": "torsion",
	"iron_breaker": "iron_sword", "warg": "warg", "ogre_captain": "ogre_club"
}
const HEAVY := ["hauler", "brute", "ram", "ram_beast", "torsion", "ogre_captain"]
const AGE_NAMES := ["STONE", "BRONZE", "IRON"]
const AUDIO_QA_EFFECT_ORDER := [
	"stone_club", "bone_spear", "stone_sling", "stone_rock", "ogre_club",
	"bronze_shield", "bronze_blade", "castlehold_bow", "ram", "iron_sword",
	"iron_lance", "torsion", "warg", "shield_hit", "gate_hit", "body_hit",
	"age_up", "horn", "boss_roar", "boss_slam", "collapse", "victory", "defeat"
]
const AUDIO_QA_EFFECT_DURATION := {
	"stone_club": 0.62, "bone_spear": 0.48, "stone_sling": 0.48, "stone_rock": 0.62, "ogre_club": 0.82,
	"bronze_shield": 0.78, "bronze_blade": 0.72, "castlehold_bow": 0.46, "ram": 0.82, "iron_sword": 0.84,
	"iron_lance": 0.80, "torsion": 0.82, "warg": 0.66, "shield_hit": 0.55, "gate_hit": 0.52, "body_hit": 0.34,
	"age_up": 1.28, "horn": 1.28, "boss_roar": 1.34, "boss_slam": 1.02, "collapse": 1.18, "victory": 1.58, "defeat": 1.32
}
const EFFECT_PATHS := {
	"stone_club": "res://assets/audio/stone_club.wav",
	"bone_spear": "res://assets/audio/bone_spear.wav",
	"stone_sling": "res://assets/audio/stone_sling.wav",
	"stone_rock": "res://assets/audio/stone_rock.wav",
	"ogre_club": "res://assets/audio/ogre_club.wav",
	"bronze_shield": "res://assets/audio/bronze_shield.wav",
	"bronze_blade": "res://assets/audio/bronze_blade.wav",
	"castlehold_bow": "res://assets/castlehold/audio/bow.wav",
	"ram": "res://assets/audio/ram.wav",
	"iron_sword": "res://assets/audio/iron_sword.wav",
	"iron_lance": "res://assets/audio/iron_lance.wav",
	"torsion": "res://assets/audio/torsion.wav",
	"warg": "res://assets/audio/warg.wav",
	"shield_hit": "res://assets/audio/shield_hit.wav",
	"gate_hit": "res://assets/castlehold/audio/gate.wav",
	"body_hit": "res://assets/castlehold/audio/hit.wav",
	"age_up": "res://assets/audio/age_up.wav",
	"victory": "res://assets/castlehold/audio/victory.wav",
	"defeat": "res://assets/castlehold/audio/defeat.wav",
	"horn": "res://assets/castlehold/audio/horn.wav",
	"collapse": "res://assets/castlehold/audio/collapse.wav",
	"boss_roar": "res://assets/castlehold/audio/boss_roar.wav",
	"boss_slam": "res://assets/castlehold/audio/boss_slam.wav"
}
const HUMAN_DEFEAT := [
	"res://assets/castlehold/audio/voices/human_defeat_1.wav",
	"res://assets/castlehold/audio/voices/human_defeat_2.wav",
	"res://assets/castlehold/audio/voices/human_defeat_3.wav"
]
const ORC_DEFEAT := [
	"res://assets/castlehold/audio/voices/orc_defeat_1.wav",
	"res://assets/castlehold/audio/voices/orc_defeat_2.wav",
	"res://assets/castlehold/audio/voices/orc_defeat_3.wav"
]
const OGRE_DEFEAT := [
	"res://assets/castlehold/audio/voices/ogre_defeat_1.wav",
	"res://assets/castlehold/audio/voices/ogre_defeat_2.wav",
	"res://assets/castlehold/audio/voices/ogre_defeat_3.wav"
]

var arena: Node3D
var tracks: Array[AudioStreamPlayer] = []
var voices: Array[AudioStreamPlayer] = []
var effects: Dictionary = {}
var human_defeat_streams: Array[AudioStream] = []
var orc_defeat_streams: Array[AudioStream] = []
var ogre_defeat_streams: Array[AudioStream] = []
var current_age := 0
var last_attack_ms := -1000
var last_attack_by_sound: Dictionary = {}
var last_defeat_ms := -1000
var last_defeat_by_group: Dictionary = {}
var transition: Tween
var enabled := true
var qa_active := false
var qa_steps: Array[Dictionary] = []
var qa_index := -1
var qa_clock := 0.0
var qa_saved_age := 0
var qa_saved_enabled := true
var startup_audit: Dictionary = {}
var created_buses: Array[String] = []
var created_limiter := false

func start(match_node: Node3D) -> void:
	arena = match_node
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_mixer()
	for path in MUSIC_PATHS:
		var stream: AudioStream = load(path)
		if stream == null:
			push_warning("Ogre War music missing: " + path)
			continue
		if stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		var player := AudioStreamPlayer.new()
		player.name = "Battle Music %d" % tracks.size()
		player.stream = stream
		player.bus = MUSIC_BUS
		player.volume_db = -80.0
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		tracks.append(player)
	for key in EFFECT_PATHS.keys():
		var effect_stream: AudioStream = load(str(EFFECT_PATHS[key]))
		if effect_stream != null:
			effects[key] = effect_stream
	for path in HUMAN_DEFEAT:
		var stream: AudioStream = load(path)
		if stream != null:
			human_defeat_streams.append(stream)
	for path in ORC_DEFEAT:
		var stream: AudioStream = load(path)
		if stream != null:
			orc_defeat_streams.append(stream)
	for path in OGRE_DEFEAT:
		var stream: AudioStream = load(path)
		if stream != null:
			ogre_defeat_streams.append(stream)
	for i in 16:
		var voice := AudioStreamPlayer.new()
		voice.bus = COMBAT_BUS
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(voice)
		voices.append(voice)
	if tracks.is_empty():
		push_warning("Ogre War has no playable music streams.")
		return
	current_age = 0
	tracks[0].volume_db = MUSIC_DB if enabled else -80.0
	tracks[0].play()
	# Some Android devices delay the first decoder start until the player is in-tree.
	# Recheck on the next frame instead of silently leaving the battle without music.
	call_deferred("_ensure_music_playing")
	startup_audit = audio_health_report()
	if not bool(startup_audit.get("ok", false)):
		push_warning("Ogre War audio audit found missing resources: " + str(startup_audit.get("missing", [])))



func _configure_mixer() -> void:
	for bus_name in [MUSIC_BUS, COMBAT_BUS, VOICE_BUS]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			created_buses.append(bus_name)
	# Keep music underneath impacts/voices without relying on per-file loudness.
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), -1.5)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(COMBAT_BUS), 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(VOICE_BUS), -0.8)
	var has_limiter := false
	for index in AudioServer.get_bus_effect_count(0):
		var effect := AudioServer.get_bus_effect(0, index)
		if effect != null and effect.has_meta("ogre_war_limiter"):
			has_limiter = true
	if not has_limiter:
		var limiter := AudioEffectHardLimiter.new()
		limiter.ceiling_db = -0.6
		limiter.set_meta("ogre_war_limiter", true)
		AudioServer.add_bus_effect(0, limiter)
		created_limiter = true

func _exit_tree() -> void:
	if transition != null and transition.is_running():
		transition.kill()
	for player in tracks + voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for bus_name in created_buses:
		var index := AudioServer.get_bus_index(bus_name)
		if index > 0:
			AudioServer.remove_bus(index)
	if created_limiter:
		for index in range(AudioServer.get_bus_effect_count(0) - 1, -1, -1):
			var effect := AudioServer.get_bus_effect(0, index)
			if effect != null and effect.has_meta("ogre_war_limiter"):
				AudioServer.remove_bus_effect(0, index)

func _ensure_music_playing() -> void:
	if tracks.is_empty() or not enabled:
		return
	var track := tracks[current_age]
	if not track.playing:
		track.volume_db = MUSIC_DB
		track.play()

func switch_age(age_index: int) -> void:
	if age_index == current_age or age_index < 0 or age_index >= tracks.size():
		return
	if transition != null and transition.is_running():
		transition.kill()
	var old_track: AudioStreamPlayer = tracks[current_age]
	current_age = age_index
	var next_track: AudioStreamPlayer = tracks[current_age]
	for track in tracks:
		if track != old_track and track != next_track:
			track.stop()
	next_track.volume_db = -70.0
	next_track.play()
	transition = create_tween().set_parallel(true)
	transition.tween_property(old_track, "volume_db", -75.0, 1.2)
	transition.tween_property(next_track, "volume_db", MUSIC_DB if enabled else -80.0, 1.2)
	transition.finished.connect(old_track.stop)
	play_effect("age_up", 0.0, -5.5, true)
	play_effect("horn", 0.0, -8.0, true)

func play_attack(kind: String, world_x: float, armored: bool = false, structure: bool = false) -> void:
	if not enabled or not ATTACK_SOUND.has(kind):
		return
	var now := Time.get_ticks_msec()
	var sound_key := str(ATTACK_SOUND[kind])
	var previous_same := int(last_attack_by_sound.get(sound_key, -1000))
	# Phase 7 replaces the old 62 ms global lockout. Distinct weapons can now be
	# heard in the same clash while identical spam is still rate-limited.
	if now - last_attack_ms < 18 or now - previous_same < 46:
		return
	var distance: float = absf(world_x - arena.camera.position.x)
	if distance > 50.0:
		return
	last_attack_ms = now
	last_attack_by_sound[sound_key] = now
	var quieter: float = -4.5 - minf(20.0, distance * 0.42)
	play_effect(sound_key, world_x, quieter)
	if armored:
		play_effect("shield_hit", world_x, quieter - 5.0)
	elif structure and kind in HEAVY:
		play_effect("gate_hit", world_x, quieter - 3.5)

func play_body_hit(world_x: float) -> void:
	if not enabled:
		return
	play_effect("body_hit", world_x, -12.5)

func play_defeat(side: int, kind: String, world_x: float) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec()
	var group := "human"
	if side == 1:
		group = "ogre" if kind in ["brute", "ram_beast", "ogre_captain"] else "orc"
	var group_last := int(last_defeat_by_group.get(group, -1000))
	# Separate human/orc/ogre voice cooldowns keep mixed casualties audible while
	# still preventing a same-faction death chorus from clipping the mix.
	if now - last_defeat_ms < 85 or now - group_last < 185:
		return
	last_defeat_ms = now
	last_defeat_by_group[group] = now
	var streams: Array[AudioStream] = human_defeat_streams
	if side == 1:
		streams = ogre_defeat_streams if group == "ogre" else orc_defeat_streams
	if streams.is_empty():
		return
	var distance: float = absf(world_x - arena.camera.position.x)
	if distance > 46.0:
		return
	_play_stream(streams[randi() % streams.size()], -8.0 - minf(15.0, distance * 0.32), false, VOICE_BUS)

func play_effect(file_name: String, _world_x: float = 0.0, volume: float = -8.0, priority: bool = false) -> void:
	if not enabled or not effects.has(file_name):
		return
	_play_stream(effects[file_name], volume, priority)

func _play_stream(stream: AudioStream, volume: float, priority: bool, bus_name: String = COMBAT_BUS) -> void:
	var chosen: AudioStreamPlayer = null
	for voice in voices:
		if not voice.playing:
			chosen = voice
			break
	if chosen == null:
		if not priority:
			return
		chosen = voices[0]
		chosen.stop()
	chosen.stream = stream
	chosen.bus = bus_name
	chosen.volume_db = volume
	chosen.pitch_scale = 1.0 if priority else randf_range(0.965, 1.035)
	chosen.play()

func audio_health_report() -> Dictionary:
	var missing: Array[String] = []
	for path in MUSIC_PATHS:
		if not ResourceLoader.exists(path):
			missing.append(path)
	for key in EFFECT_PATHS.keys():
		var path := str(EFFECT_PATHS[key])
		if not ResourceLoader.exists(path):
			missing.append(path)
	for path in HUMAN_DEFEAT + ORC_DEFEAT + OGRE_DEFEAT:
		if not ResourceLoader.exists(path):
			missing.append(path)
	return {
		"ok": missing.is_empty() and tracks.size() == 3 and effects.size() == EFFECT_PATHS.size() and human_defeat_streams.size() == 3 and orc_defeat_streams.size() == 3 and ogre_defeat_streams.size() == 3,
		"missing": missing,
		"music_loaded": tracks.size(),
		"effects_loaded": effects.size(),
		"human_deaths": human_defeat_streams.size(),
		"orc_deaths": orc_defeat_streams.size(),
		"ogre_deaths": ogre_defeat_streams.size(),
		"music_bus": AudioServer.get_bus_index(MUSIC_BUS),
		"combat_bus": AudioServer.get_bus_index(COMBAT_BUS),
		"voice_bus": AudioServer.get_bus_index(VOICE_BUS)
	}

func start_audio_qa() -> void:
	if qa_active:
		stop_audio_qa(true)
		return
	qa_saved_age = current_age
	qa_saved_enabled = enabled
	enabled = true
	qa_steps.clear()
	for age_index in range(3):
		qa_steps.append({"type":"music", "value":age_index, "label":"%s AGE MUSIC" % AGE_NAMES[age_index], "duration":2.25})
	for effect_name in AUDIO_QA_EFFECT_ORDER:
		qa_steps.append({"type":"effect", "value":effect_name, "label":"SFX  " + str(effect_name).to_upper().replace("_", " "), "duration":float(AUDIO_QA_EFFECT_DURATION.get(effect_name, 0.70))})
	qa_steps.append({"type":"death", "value":"human", "label":"HUMAN DEATH VOICE", "duration":0.68})
	qa_steps.append({"type":"death", "value":"orc", "label":"ORC DEATH VOICE", "duration":0.68})
	qa_steps.append({"type":"death", "value":"ogre", "label":"OGRE DEATH VOICE", "duration":0.75})
	qa_active = true
	qa_index = -1
	qa_clock = 0.01
	_qa_note("AUDIO QA STARTED  •  3 MUSIC BEDS + %d SFX + 3 DEATH BANKS" % AUDIO_QA_EFFECT_ORDER.size())

func stop_audio_qa(restore: bool = true) -> void:
	if not qa_active and not restore:
		return
	qa_active = false
	qa_steps.clear()
	qa_index = -1
	qa_clock = 0.0
	for voice in voices:
		voice.stop()
	if restore:
		enabled = qa_saved_enabled
		_qa_play_music_age(qa_saved_age)
		if not enabled and not tracks.is_empty():
			tracks[current_age].volume_db = -80.0
	_qa_note("AUDIO QA COMPLETE  •  BATTLE MIX RESTORED")

func _qa_play_music_age(age_index: int) -> void:
	if tracks.is_empty() or age_index < 0 or age_index >= tracks.size():
		return
	if transition != null and transition.is_running():
		transition.kill()
	for track in tracks:
		track.stop()
	current_age = age_index
	tracks[current_age].volume_db = MUSIC_DB if enabled else -80.0
	tracks[current_age].play()

func _qa_play_death(group: String) -> void:
	var bank: Array[AudioStream] = human_defeat_streams
	if group == "orc":
		bank = orc_defeat_streams
	elif group == "ogre":
		bank = ogre_defeat_streams
	if not bank.is_empty():
		_play_stream(bank[0], -5.5, true, VOICE_BUS)

func _qa_advance() -> void:
	qa_index += 1
	if qa_index >= qa_steps.size():
		stop_audio_qa(true)
		return
	var step: Dictionary = qa_steps[qa_index]
	var step_type := str(step["type"])
	var value = step["value"]
	_qa_note("AUDIO CHECK  %02d/%02d  •  %s" % [qa_index + 1, qa_steps.size(), str(step["label"])])
	if step_type == "music":
		_qa_play_music_age(int(value))
	elif step_type == "effect":
		play_effect(str(value), 0.0, -4.5, true)
	elif step_type == "death":
		_qa_play_death(str(value))
	qa_clock = float(step["duration"])

func _qa_note(message: String) -> void:
	if is_instance_valid(arena) and arena.has_method("on_audio_qa_message"):
		arena.on_audio_qa_message(message)

func _process(delta: float) -> void:
	if not qa_active:
		return
	qa_clock -= delta
	if qa_clock <= 0.0:
		_qa_advance()

func end_battle(won: bool) -> void:
	if transition != null and transition.is_running():
		transition.kill()
	if not tracks.is_empty():
		for track in tracks:
			if track.playing and track == tracks[current_age]:
				track.volume_db = -20.0
			elif track.playing:
				track.stop()
	play_effect("victory" if won else "defeat", 0.0, -3.0, true)

func toggle_enabled() -> void:
	if qa_active:
		stop_audio_qa(false)
	enabled = not enabled
	if not enabled:
		if transition != null and transition.is_running():
			transition.kill()
		for voice in voices:
			voice.stop()
	if tracks.is_empty():
		return
	for track in tracks:
		if track.playing and track != tracks[current_age]:
			track.stop()
		elif track.playing:
			track.volume_db = MUSIC_DB if enabled and track == tracks[current_age] else -80.0
	if enabled and not tracks[current_age].playing:
		tracks[current_age].volume_db = MUSIC_DB
		tracks[current_age].play()
