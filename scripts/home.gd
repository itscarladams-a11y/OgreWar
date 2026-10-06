class_name OgreWarHome
extends Control

const UI_ROOT := "res://assets/ui/phase10/"
const P8_ROOT := "res://assets/ogre_modern/ui/phase8/"
const BACKDROP := preload("res://assets/ui/phase10/menu_backdrop.png")
const LOGO := preload("res://assets/ui/phase10/ogre_war_logo.png")
const STUDIO_LOGO := preload("res://assets/ui/bantam/studio_logo.png")
const GOLD := Color("f0ca76")
const TEXT := Color("f8eddb")
const MUTED := Color("c5c1b2")

var records_panel: PanelContainer
var records_dim: ColorRect

func _ready() -> void:
	get_tree().paused = false
	build_screen()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.42)
	# Launch the story once per installation; the menu can replay it at any time.
	if get_tree().current_scene == self and not OgreWarIntro.has_seen_intro():
		call_deferred("_on_cinematic")

func build_screen() -> void:
	var art := TextureRect.new()
	art.name = "MenuBackdrop"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = BACKDROP
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.024, 0.033, 0.19)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var lower := ColorRect.new()
	lower.anchor_left = 0.0; lower.anchor_right = 1.0
	lower.anchor_top = 0.60; lower.anchor_bottom = 1.0
	lower.color = Color(0.012, 0.022, 0.031, 0.39)
	lower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower)

	_badge(false)
	_badge(true)
	var motto := label(self, "THE VALLEY WILL REMEMBER WHO HOLDS IT", 13, Color("ecdbb6"))
	motto.name = "Motto"
	motto.anchor_left = 0.29; motto.anchor_right = 0.71
	motto.offset_top = 21.0; motto.offset_bottom = 47.0
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	motto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	motto.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	motto.add_theme_constant_override("shadow_offset_x", 1)
	motto.add_theme_constant_override("shadow_offset_y", 2)

	var title := TextureRect.new()
	title.name = "OgreWarLogo"
	title.texture = LOGO
	title.anchor_left = 0.5; title.anchor_right = 0.5
	title.offset_left = -438; title.offset_right = 438
	title.offset_top = 49; title.offset_bottom = 276
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subline := label(self, "HUMANITY'S LAST STAND", 17, Color("fff1cd"))
	subline.anchor_left = 0.5; subline.anchor_right = 0.5
	subline.offset_left = -230; subline.offset_right = 230
	subline.offset_top = 266; subline.offset_bottom = 299
	subline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subline.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	subline.add_theme_constant_override("shadow_offset_y", 2)

	var studio_mark := TextureRect.new()
	studio_mark.name = "BantamEntertainmentLogo"
	studio_mark.texture = STUDIO_LOGO
	studio_mark.anchor_top = 1.0; studio_mark.anchor_bottom = 1.0
	studio_mark.offset_left = 23; studio_mark.offset_right = 253
	studio_mark.offset_top = -98; studio_mark.offset_bottom = -19
	studio_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	studio_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	studio_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(studio_mark)

	var campaign := PanelContainer.new()
	campaign.name = "WarRoom"
	campaign.anchor_left = 0.5; campaign.anchor_right = 0.5
	campaign.anchor_top = 1.0; campaign.anchor_bottom = 1.0
	campaign.offset_left = -324; campaign.offset_right = 324
	campaign.offset_top = -276; campaign.offset_bottom = -21
	campaign.add_theme_stylebox_override("panel", panel_style(Color(0.018,0.032,0.045,0.96), Color("c49b56"), 2, 15, 15))
	add_child(campaign)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	campaign.add_child(body)
	var lead := label(body, "THE WAR ROOM", 23, GOLD)
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var instruction := label(body, "RAISE AN ARMY  •  BREAK THE GATE  •  TAKE THE KEEP", 12, MUTED)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var play := premium_button(body, "MARCH TO WAR", 0, 64, GOLD, Color("241b10"), true)
	play.name = "MarchToWar"
	play.pressed.connect(_on_play)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	body.add_child(actions)
	var how := premium_button(actions, "FIELD GUIDE", 171, 47, Color("668eaa"), TEXT)
	how.pressed.connect(_on_help)
	var records_btn := premium_button(actions, "BATTLE RECORDS", 171, 47, Color("a68c5a"), TEXT)
	records_btn.pressed.connect(_show_records)
	var intro_btn := premium_button(actions, "WATCH STORY", 171, 47, Color("ad6f57"), TEXT)
	intro_btn.name = "WatchStory"
	intro_btn.pressed.connect(_on_cinematic)
	var eras := label(body, "STONE  ◇  BRONZE  ◇  IRON", 12, Color("d7bb84"))
	eras.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var glint := ColorRect.new()
	glint.color = Color(1.0, 0.86, 0.55, 0.40)
	glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glint.anchor_left = 0.08; glint.anchor_right = 0.92
	glint.offset_top = 3; glint.offset_bottom = 5
	campaign.add_child(glint)

	records_dim = ColorRect.new()
	records_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	records_dim.color = Color(0.0, 0.01, 0.02, 0.67)
	records_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	records_dim.visible = false
	add_child(records_dim)
	records_panel = _records_panel()
	records_panel.visible = false
	add_child(records_panel)

func _badge(enemy: bool) -> void:
	var card := PanelContainer.new()
	card.name = "OgreBadge" if enemy else "HumanBadge"
	card.anchor_left = 1.0 if enemy else 0.0
	card.anchor_right = card.anchor_left
	card.offset_left = -244.0 if enemy else 22.0
	card.offset_right = -22.0 if enemy else 244.0
	card.offset_top = 18.0; card.offset_bottom = 68.0
	card.add_theme_stylebox_override("panel", panel_style(Color(0.018,0.035,0.046,0.91), Color("a25e4b") if enemy else Color("789db1"), 1, 10, 5))
	add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	card.add_child(row)
	var crest := TextureRect.new()
	crest.texture = load(P8_ROOT + ("ogre_crest.svg" if enemy else "human_crest.svg"))
	crest.custom_minimum_size = Vector2(32, 32)
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not enemy: row.add_child(crest)
	var caption := label(row, "OGRE HOST" if enemy else "HUMAN LEGIONS", 13, Color("df9b82") if enemy else Color("b1d6ea"))
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if enemy else HORIZONTAL_ALIGNMENT_LEFT
	if enemy: row.add_child(crest)

func _records_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "RecordsPanel"
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -262; panel.offset_right = 262
	panel.offset_top = -174; panel.offset_bottom = 174
	panel.add_theme_stylebox_override("panel", panel_style(Color(0.018,0.031,0.041,0.99), GOLD, 2, 14, 14))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	panel.add_child(body)
	var head := HBoxContainer.new()
	body.add_child(head)
	var heading := label(head, "HALL OF DEEDS", 24, GOLD)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := premium_button(head, "CLOSE", 82, 40, Color("7c8d92"), TEXT)
	close.pressed.connect(_show_records)
	var records := OgreWarRecords.load_records()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	body.add_child(grid)
	var fastest := "—" if int(records["fastest_win"]) == 0 else time_text(int(records["fastest_win"]))
	stat(grid, "BEST SCORE", str(records["best_score"]), GOLD)
	stat(grid, "WINS / LOSSES", "%d / %d" % [records["wins"], records["losses"]], TEXT)
	stat(grid, "FASTEST WIN", fastest, TEXT)
	stat(grid, "BATTLES", str(records["battles"]), TEXT)
	stat(grid, "OGRES DEFEATED", str(records["ogres_defeated"]), TEXT)
	stat(grid, "LAST RESULT", str(records["last_result"]), TEXT)
	var footer := label(body, "LOCAL CAMPAIGN RECORDS", 11, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return panel

func _show_records() -> void:
	if not is_instance_valid(records_panel): return
	records_panel.visible = not records_panel.visible
	records_dim.visible = records_panel.visible
	if records_panel.visible:
		records_panel.modulate.a = 0.0
		create_tween().tween_property(records_panel, "modulate:a", 1.0, 0.18)

func stat(parent: Node, caption: String, value: String, accent: Color) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(148, 84)
	card.add_theme_stylebox_override("panel", panel_style(Color(0.048,0.067,0.076,0.96), Color("46606a"), 1, 9, 0))
	parent.add_child(card)
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(body)
	var cap := label(body, caption, 11, MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var val := label(body, value, 20, accent)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func premium_button(parent: Node, text_value: String, width: int, height: int, accent: Color, text_color: Color, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(width, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 22 if primary else 14)
	b.add_theme_color_override("font_color", text_color)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", panel_style(accent.darkened(0.45), accent, 2, 10, 5))
	b.add_theme_stylebox_override("hover", panel_style(accent.darkened(0.26), accent.lightened(0.24), 2, 10, 8))
	b.add_theme_stylebox_override("pressed", panel_style(accent.darkened(0.62), accent.lightened(0.10), 2, 10, 2))
	b.add_theme_stylebox_override("focus", panel_style(Color.TRANSPARENT, Color.WHITE, 2, 10, 0))
	parent.add_child(b)
	return b

func label(parent: Node, content: String, size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = content
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	parent.add_child(item)
	return item

func panel_style(background: Color, border: Color, width: int, radius: int = 7, shadow: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.anti_aliasing = true
	if shadow > 0:
		style.shadow_color = Color(0,0,0,0.64)
		style.shadow_size = shadow
		style.shadow_offset = Vector2(0,4)
	return style

func time_text(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_cinematic() -> void:
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _on_help() -> void:
	var guide := AcceptDialog.new()
	guide.title = "OGRE WAR • FIELD GUIDE"
	guide.dialog_text = "Destroy the ogre gate, then the keep. Protect your own keep.\n\nRecruit from the bottom dock. Troops fight and march automatically.\nDrag to scout and pinch to zoom; use FORT, FRONT and OGRES to jump across the valley.\nEarn age progress in battle, then pay gold to advance Stone → Bronze → Iron.\nHold keeps troops near home; Advance pushes toward the enemy.\nRepair the gate twice per battle before it is breached."
	add_child(guide)
	guide.popup_centered(Vector2i(690,360))
	guide.confirmed.connect(guide.queue_free)
