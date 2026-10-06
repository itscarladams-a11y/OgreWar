extends Control

const BATTLE_SCENE := "res://scenes/match.tscn"
const TITLE_ART := preload("res://assets/ui/phase10/loading_backdrop.png")
const MENU_LOGO := preload("res://assets/ui/phase10/ogre_war_logo.png")
const LOADING_COVER := preload("res://scripts/loading_cover.gd")
const P8_ROOT := "res://assets/ogre_modern/ui/phase8/"

var progress_bar: ProgressBar
var stage_label: Label
var start_ms := 0

func _ready() -> void:
	start_ms = Time.get_ticks_msec()
	_build_loading_screen()
	call_deferred("_load_battle")

func _build_loading_screen() -> void:
	var art := TextureRect.new(); art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); art.texture = TITLE_ART; art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(art)
	var shade := ColorRect.new(); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color = Color(0.01,0.016,0.026,0.20); shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(shade)
	var logo := TextureRect.new(); logo.name = "LoadingLogo"; logo.texture = MENU_LOGO; logo.anchor_left = 0.5; logo.anchor_right = 0.5; logo.offset_left = -355; logo.offset_right = 355; logo.offset_top = 27; logo.offset_bottom = 188; logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; logo.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(logo)
	var tagline := _label("HUMANITY'S LAST STAND", 16, Color("f4dfae")); tagline.anchor_left = 0.5; tagline.anchor_right = 0.5; tagline.offset_left = -200; tagline.offset_right = 200; tagline.offset_top = 176; tagline.offset_bottom = 205; tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tagline.add_theme_color_override("font_shadow_color", Color(0,0,0,0.85)); tagline.add_theme_constant_override("shadow_offset_y", 2); add_child(tagline)

	var panel := PanelContainer.new(); panel.name = "LoadingPanel"; panel.anchor_left = 0.17; panel.anchor_right = 0.83; panel.anchor_top = 1.0; panel.anchor_bottom = 1.0; panel.offset_top = -179; panel.offset_bottom = -25; panel.add_theme_stylebox_override("panel", _panel(Color(0.018,0.031,0.042,0.97), Color("d5af69"), 2, 13)); add_child(panel)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 15); panel.add_child(row)
	row.add_child(_crest(P8_ROOT + "human_crest.svg"))
	var center := VBoxContainer.new(); center.size_flags_horizontal = Control.SIZE_EXPAND_FILL; center.alignment = BoxContainer.ALIGNMENT_CENTER; center.add_theme_constant_override("separation", 6); row.add_child(center)
	var title := _label("ENTERING THE VALLEY", 24, Color("f6dca8")); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; center.add_child(title)
	stage_label = _label("MUSTERING THE HOSTS", 13, Color("d5cfbf")); stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; center.add_child(stage_label)
	progress_bar = ProgressBar.new(); progress_bar.name = "BattleLoadProgress"; progress_bar.min_value = 0; progress_bar.max_value = 100; progress_bar.value = 8; progress_bar.show_percentage = false; progress_bar.custom_minimum_size = Vector2(500,16); progress_bar.add_theme_stylebox_override("background", _panel(Color(0.03,0.04,0.05,1), Color("4b5960"),1,4)); progress_bar.add_theme_stylebox_override("fill", _panel(Color("dcb05e"), Color("f5da91"),1,4)); center.add_child(progress_bar)
	var ages := _label("STONE   ◇   BRONZE   ◇   IRON", 12, Color("d7c08d")); ages.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; center.add_child(ages)
	row.add_child(_crest(P8_ROOT + "ogre_crest.svg"))

func _crest(path: String) -> TextureRect:
	var c := TextureRect.new(); c.texture = load(path); c.custom_minimum_size = Vector2(66,66); c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; return c

func _label(value: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.text = value; l.add_theme_font_size_override("font_size",size); l.add_theme_color_override("font_color",color); return l

func _panel(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(width); s.set_corner_radius_all(radius); s.content_margin_left=14; s.content_margin_right=14; s.content_margin_top=10; s.content_margin_bottom=10; s.shadow_color=Color(0,0,0,0.55); s.shadow_size=8; s.shadow_offset=Vector2(0,3); return s

func _load_battle() -> void:
	var started := ResourceLoader.load_threaded_request(BATTLE_SCENE)
	var prog: Array = []
	var fake := 8.0
	if started == OK:
		while ResourceLoader.load_threaded_get_status(BATTLE_SCENE, prog) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var real := float(prog[0]) * 100.0 if not prog.is_empty() else fake
			fake = minf(88.0, fake + 0.9)
			progress_bar.value = maxf(real, fake)
			stage_label.text = "RAISING BANNERS" if progress_bar.value < 45 else ("FORMING THE LINES" if progress_bar.value < 78 else "OPENING THE GATES")
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(BATTLE_SCENE) == ResourceLoader.THREAD_LOAD_LOADED:
			# A loaded scene file still needs to construct its 3D valley, HUD and
			# first rendered frame. Keep the illustration up through that work.
			progress_bar.value = 92; stage_label.text = "BUILDING THE BATTLEFIELD"
			var elapsed := float(Time.get_ticks_msec() - start_ms) / 1000.0
			if elapsed < 0.78: await get_tree().create_timer(0.78 - elapsed).timeout
			var scene: PackedScene = ResourceLoader.load_threaded_get(BATTLE_SCENE)
			# Move the artwork into a persistent canvas before replacing this
			# scene. The new valley takes extra time to construct on phones.
			var cover := LOADING_COVER.new()
			get_tree().root.add_child(cover)
			var cover_screen := Control.new()
			cover_screen.mouse_filter = Control.MOUSE_FILTER_STOP
			cover.add_child(cover_screen)
			cover_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			for child in get_children():
				child.reparent(cover_screen)
			if get_tree().change_scene_to_packed(scene) != OK:
				for child in cover_screen.get_children():
					child.reparent(self)
				cover.queue_free()
				_show_load_error()
				return
			cover.start(progress_bar, stage_label, cover_screen)
			return
	_show_load_error()

func _show_load_error() -> void:
	stage_label.text = "BATTLEFIELD COULD NOT LOAD"
	stage_label.add_theme_color_override("font_color", Color("f5aa91"))
	progress_bar.value = 0
	var retry := Button.new()
	retry.text = "TRY AGAIN"
	retry.anchor_left = 0.5; retry.anchor_right = 0.5
	retry.anchor_top = 0.5; retry.anchor_bottom = 0.5
	retry.offset_left = -204; retry.offset_right = -14
	retry.offset_top = -25; retry.offset_bottom = 25
	add_child(retry)
	var home := Button.new()
	home.text = "WAR ROOM"
	home.anchor_left = 0.5; home.anchor_right = 0.5
	home.anchor_top = 0.5; home.anchor_bottom = 0.5
	home.offset_left = 14; home.offset_right = 204
	home.offset_top = -25; home.offset_bottom = 25
	add_child(home)
	retry.pressed.connect(_retry_load.bind(retry, home))
	home.pressed.connect(_return_home)

func _retry_load(retry: Button, home: Button) -> void:
	retry.queue_free()
	home.queue_free()
	progress_bar.value = 8
	stage_label.text = "MUSTERING THE HOSTS"
	call_deferred("_load_battle")

func _return_home() -> void:
	get_tree().change_scene_to_file("res://scenes/home.tscn")
