class_name OgreWarStudioSplash
extends Control

const HOME_SCENE := "res://scenes/home.tscn"
const INTRO_SCENE := "res://scenes/intro.tscn"
const STUDIO_ART := preload("res://assets/ui/bantam/studio_loading_screen.png")
const MIN_DISPLAY_SECONDS := 1.4

var target_scene := ""
var progress_bar: ProgressBar
var stage_label: Label
var retry_button: Button
var _started_ms := 0
var _scene_ready: PackedScene
var _loading := false
var _entering := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	target_scene = HOME_SCENE if OgreWarIntro.has_seen_intro() else INTRO_SCENE
	_build_screen()
	# Paint the studio screen once before scheduling any resource work.
	call_deferred("_begin_loading")

func _build_screen() -> void:
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)

	# The approved illustration includes a decorative, partly filled bar.
	# Show its logo artwork; replace its fixed bar with real loading progress.
	var logo_art := AtlasTexture.new()
	logo_art.atlas = STUDIO_ART
	logo_art.region = Rect2(0, 0, 1672, 690)
	var artwork := TextureRect.new()
	artwork.name = "BantamLoadingArtwork"
	artwork.texture = logo_art
	artwork.anchor_right = 1.0
	artwork.anchor_bottom = 0.75
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)

	stage_label = Label.new()
	stage_label.name = "StudioLoadingStatus"
	stage_label.text = "PREPARING THE VALLEY"
	stage_label.anchor_left = 0.2
	stage_label.anchor_right = 0.8
	stage_label.anchor_top = 0.76
	stage_label.anchor_bottom = 0.8
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 16)
	stage_label.add_theme_color_override("font_color", Color("f7da9b"))
	add_child(stage_label)

	progress_bar = ProgressBar.new()
	progress_bar.name = "StudioLoadProgress"
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false
	progress_bar.anchor_left = 0.24
	progress_bar.anchor_right = 0.76
	progress_bar.anchor_top = 0.82
	progress_bar.anchor_bottom = 0.85
	progress_bar.add_theme_stylebox_override("background", _bar_style(Color("17110e"), Color("c89252")))
	progress_bar.add_theme_stylebox_override("fill", _bar_style(Color("ed3218"), Color("ffa940")))
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_bar)

	var caption := Label.new()
	caption.name = "StudioCaption"
	caption.text = "BANTAM ENTERTAINMENT  ·  OGRE WAR"
	caption.anchor_left = 0.1
	caption.anchor_right = 0.9
	caption.anchor_top = 0.88
	caption.anchor_bottom = 0.93
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Color("b9a793"))
	add_child(caption)

	retry_button = Button.new()
	retry_button.name = "RetryStartup"
	retry_button.text = "RETRY LOADING"
	retry_button.anchor_left = 0.38
	retry_button.anchor_right = 0.62
	retry_button.anchor_top = 0.9
	retry_button.anchor_bottom = 0.98
	retry_button.visible = false
	retry_button.pressed.connect(_begin_loading)
	add_child(retry_button)

func _bar_style(fill_color: Color, edge_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = edge_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

func _begin_loading() -> void:
	_loading = false
	_entering = false
	_scene_ready = null
	progress_bar.value = 0
	stage_label.text = "PREPARING THE VALLEY"
	retry_button.visible = false
	_started_ms = Time.get_ticks_msec()
	var error := ResourceLoader.load_threaded_request(target_scene)
	if error != OK:
		_show_error()
		return
	_loading = true
	set_process(true)

func _process(_delta: float) -> void:
	if not _loading or _entering:
		return
	# load_threaded_get consumes the request, so stop polling after it succeeds.
	if _scene_ready != null:
		_enter_if_ready()
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(target_scene, progress)
	if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS and status != ResourceLoader.THREAD_LOAD_LOADED:
		_show_error()
		return
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		if _scene_ready == null:
			_scene_ready = ResourceLoader.load_threaded_get(target_scene) as PackedScene
			if _scene_ready == null:
				_show_error()
				return
		progress_bar.value = 100
		stage_label.text = "THE VALLEY IS READY"
		_enter_if_ready()
		return
	if not progress.is_empty():
		progress_bar.value = clampf(float(progress[0]) * 100.0, 0.0, 99.0)
	stage_label.text = "PREPARING THE VALLEY"

func _enter_if_ready() -> void:
	if Time.get_ticks_msec() - _started_ms < int(MIN_DISPLAY_SECONDS * 1000.0):
		return
	_entering = true
	if get_tree().change_scene_to_packed(_scene_ready) != OK:
		_show_error()

func _show_error() -> void:
	_loading = false
	_entering = false
	set_process(false)
	progress_bar.value = 0
	stage_label.text = "STARTUP COULD NOT LOAD"
	retry_button.visible = true
