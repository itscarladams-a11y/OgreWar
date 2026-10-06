class_name OgreWarIntro
extends Control

const CINEMATIC_PATH := "res://assets/ui/phase10/humanitys_last_stand.ogv"
const SEEN_PATH := "user://ogre_war_intro_seen.txt"

var video: VideoStreamPlayer
var exiting := false

static func has_seen_intro() -> bool:
	return FileAccess.file_exists(SEEN_PATH)

static func mark_seen() -> void:
	var file := FileAccess.open(SEEN_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("watched_or_skipped")
		file.close()

func _ready() -> void:
	get_tree().paused = false
	_build_player()
	if not ResourceLoader.exists(CINEMATIC_PATH):
		_finish_intro()
		return
	var clip := load(CINEMATIC_PATH)
	if clip == null:
		_finish_intro()
		return
	video.stream = clip
	video.finished.connect(_finish_intro)
	video.play()

func _build_player() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("070c11")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var frame := AspectRatioContainer.new()
	frame.name = "CinematicFrame"
	frame.ratio = 16.0 / 9.0
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	video = VideoStreamPlayer.new()
	video.name = "OpeningCinematic"
	video.expand = true
	video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(video)
	var heading := Label.new()
	heading.text = "OGRE WAR   •   HUMANITY'S LAST STAND"
	heading.anchor_left = 0.0; heading.anchor_right = 0.0
	heading.offset_left = 24; heading.offset_right = 440
	heading.offset_top = 20; heading.offset_bottom = 61
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", Color("f3dfae"))
	heading.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
	heading.add_theme_constant_override("shadow_offset_y", 2)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heading)
	var skip := Button.new()
	skip.name = "SkipIntro"
	skip.text = "SKIP INTRO  ›"
	skip.anchor_left = 1.0; skip.anchor_right = 1.0
	skip.offset_left = -193; skip.offset_right = -24
	skip.offset_top = 18; skip.offset_bottom = 66
	skip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip.add_theme_font_size_override("font_size", 15)
	skip.add_theme_color_override("font_color", Color("fff0d3"))
	skip.add_theme_color_override("font_hover_color", Color.WHITE)
	skip.add_theme_stylebox_override("normal", _skip_style(Color(0.02,0.03,0.04,0.85), Color("b79a66")))
	skip.add_theme_stylebox_override("hover", _skip_style(Color(0.12,0.16,0.19,0.98), Color("f1ca75")))
	skip.add_theme_stylebox_override("pressed", _skip_style(Color(0.07,0.09,0.10,1), Color("f1ca75")))
	skip.add_theme_stylebox_override("focus", _skip_style(Color.TRANSPARENT, Color.WHITE))
	skip.pressed.connect(_finish_intro)
	add_child(skip)

func _skip_style(bg: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0,0,0,0.5)
	style.shadow_size = 5
	return style

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish_intro()

func _finish_intro() -> void:
	if exiting: return
	exiting = true
	if is_instance_valid(video):
		video.stop()
	mark_seen()
	get_tree().change_scene_to_file("res://scenes/home.tscn")
