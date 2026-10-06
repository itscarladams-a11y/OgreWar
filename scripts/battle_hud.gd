class_name MarchHUD
extends CanvasLayer

const HUMAN := Color("527f9e")
const HUMAN_BRIGHT := Color("a4d0e7")
const OGRE := Color("9d5142")
const OGRE_BRIGHT := Color("e09073")
const GOLD := Color("f0ca76")
const TEXT := Color("f8eddb")
const MUTED := Color("b9b7ad")
const DARK := Color("0d1214")
const ICON_ROOT := "res://assets/ogre_modern/ui/phase5/"
const P8_ROOT := "res://assets/ogre_modern/ui/phase8/"
const P9_UNIT_ROOT := "res://assets/ogre_modern/ui/phase9/"
const UNIT_ICON := {
	"hunter":"hunter", "slinger":"slinger", "hauler":"hauler",
	"shield":"shield", "bowman":"bowman", "ram":"ram",
	"swordsman":"swordsman", "lancer":"lancer", "torsion":"torsion"
}

var game
var status: Label
var gold_label: Label
var army_label: Label
var timer_label: Label
var banner: Label
var banner_wrap: PanelContainer
var hold_button: Button
var recruit_buttons: Dictionary = {}
var repair_button: Button
var age_button: Button
var pause_button: Button
var audio_button: Button
var audio_qa_button: Button
var audio_qa_label: Label
var pause_panel: PanelContainer
var result_panel: PanelContainer
var result_title: Label
var result_crest: TextureRect
var result_detail: Label
var human_keep_bar: ProgressBar
var human_gate_bar: ProgressBar
var orc_keep_bar: ProgressBar
var orc_gate_bar: ProgressBar
var human_progress_bar: ProgressBar
var orc_progress_bar: ProgressBar
var human_age_label: Label
var orc_age_label: Label
var banner_clock := 0.0
var cooldown_bars: Dictionary = {}
var age_progress_bar: ProgressBar
var command_dock: PanelContainer

func build(arena: Node3D) -> void:
	game = arena
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top(root)
	_build_banner(root)
	_build_command_dock(root)
	pause_panel = modal(root, "BATTLE PAUSED", false)
	var pause_stack: VBoxContainer = pause_panel.get_child(0)
	button(pause_stack, "RESUME BATTLE", game.toggle_pause, 300, "human")
	button(pause_stack, "RESTART MATCH", game.restart, 300, "neutral")
	audio_button = button(pause_stack, "AUDIO ON", game.toggle_audio, 300, "neutral")
	audio_qa_label = _label("AUDIO QA INITIALIZING", 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	pause_stack.add_child(audio_qa_label)
	audio_qa_button = button(pause_stack, "AUDIO CHECK", game.run_audio_qa, 300, "age")
	button(pause_stack, "RETURN TO HOME", game.return_to_home, 300, "danger")
	result_panel = modal(root, "", false)
	var result_stack: VBoxContainer = result_panel.get_child(0)
	result_crest = TextureRect.new()
	result_crest.custom_minimum_size = Vector2(74, 74)
	result_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result_stack.add_child(result_crest)
	result_title = _label("", 33, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	result_stack.add_child(result_title)
	result_detail = _label("", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	result_stack.add_child(result_detail)
	button(result_stack, "PLAY AGAIN", game.restart, 300, "human")
	button(result_stack, "RETURN TO WAR ROOM", game.return_to_home, 300, "neutral")

func _build_top(root: Control) -> void:
	var top := PanelContainer.new()
	top.name = "BattleStatusBar"
	top.anchor_left = 0.012
	top.anchor_right = 0.988
	top.offset_top = 8.0
	top.offset_bottom = 104.0
	top.add_theme_stylebox_override("panel", _panel(Color(0.019,0.032,0.042,0.970), Color("b09260"), 2, 12, 9))
	root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	top.add_child(row)

	var human := _faction_panel("HUMAN KEEP", HUMAN, false)
	var human_panel: PanelContainer = human["panel"]
	human_panel.custom_minimum_size.x = 365
	row.add_child(human_panel)
	human_age_label = human["age"]
	human_keep_bar = human["keep"]
	human_gate_bar = human["gate"]
	human_progress_bar = human["progress"]

	var center_panel := PanelContainer.new()
	center_panel.custom_minimum_size.x = 455
	center_panel.add_theme_stylebox_override("panel", _panel(Color(0.036,0.054,0.064,0.91), Color("736a52"), 1, 9, 0))
	row.add_child(center_panel)
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 2)
	center_panel.add_child(center)
	var title := _label("OGRE WAR", 17, Color("f5d491"), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	title.add_theme_constant_override("shadow_offset_y", 2)
	center.add_child(title)
	status = _label("ADVANCE", 11, Color("c5c2b7"), HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(status)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 6)
	center.add_child(stats)
	gold_label = _stat_chip(stats, P8_ROOT + "coin.svg", "0", GOLD)
	army_label = _stat_chip(stats, P8_ROOT + "army.svg", "0/24", TEXT)
	timer_label = _stat_chip(stats, P8_ROOT + "timer.svg", "00:00", TEXT)

	var orc := _faction_panel("OGRE STRONGHOLD", OGRE, true)
	var orc_panel: PanelContainer = orc["panel"]
	orc_panel.custom_minimum_size.x = 365
	row.add_child(orc_panel)
	orc_age_label = orc["age"]
	orc_keep_bar = orc["keep"]
	orc_gate_bar = orc["gate"]
	orc_progress_bar = orc["progress"]

func _stat_chip(parent: Node, icon_path: String, initial: String, accent: Color) -> Label:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(116, 27)
	chip.add_theme_stylebox_override("panel", _panel(Color(0.055,0.064,0.066,0.90), accent.darkened(0.52), 1, 7, 0))
	parent.add_child(chip)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(19,19)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var value := _label(initial, 13, accent, HORIZONTAL_ALIGNMENT_CENTER)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)
	return value

func _faction_panel(title_text: String, accent: Color, enemy: bool) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel(Color(0.045,0.052,0.053,0.92), accent.darkened(0.30), 1, 9, 0))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	panel.add_child(stack)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 7)
	stack.add_child(head)
	var crest := TextureRect.new()
	crest.custom_minimum_size = Vector2(30, 30)
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.texture = load(P8_ROOT + ("ogre_crest.svg" if enemy else "human_crest.svg"))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", -1)
	var heading := _label(title_text, 13, accent.lightened(0.32), HORIZONTAL_ALIGNMENT_RIGHT if enemy else HORIZONTAL_ALIGNMENT_LEFT)
	var age := _label("STONE AGE", 11, GOLD, HORIZONTAL_ALIGNMENT_RIGHT if enemy else HORIZONTAL_ALIGNMENT_LEFT)
	titles.add_child(heading)
	titles.add_child(age)
	if enemy:
		head.add_child(titles)
		head.add_child(crest)
	else:
		head.add_child(crest)
		head.add_child(titles)
	var keep := _health_bar(accent, "KEEP")
	stack.add_child(keep)
	var gate := _health_bar(accent.darkened(0.08), "GATE")
	stack.add_child(gate)
	var progress := _age_bar(accent)
	stack.add_child(progress)
	return {"panel":panel, "age":age, "keep":keep, "gate":gate, "progress":progress}

func _health_bar(accent: Color, label_text: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size.y = 16
	bar.add_theme_stylebox_override("background", _panel(Color(0.022,0.027,0.028,0.96), Color(0.14,0.15,0.15,1), 1, 4, 0))
	bar.add_theme_stylebox_override("fill", _panel(accent.darkened(0.05), accent.lightened(0.18), 1, 4, 0))
	var label := _label(label_text, 10, Color("f6f1e5"), HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(label)
	return bar

func _age_bar(accent: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size.y = 5
	var background := _panel(Color(0.022,0.027,0.028,0.96), Color(0,0,0,0), 0, 3, 0)
	background.content_margin_top = 0
	background.content_margin_bottom = 0
	var fill := _panel(GOLD if accent == HUMAN else OGRE_BRIGHT, Color(0,0,0,0), 0, 3, 0)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _build_banner(root: Control) -> void:
	banner_wrap = PanelContainer.new()
	banner_wrap.anchor_left = 0.29
	banner_wrap.anchor_right = 0.71
	banner_wrap.offset_top = 110.0
	banner_wrap.offset_bottom = 142.0
	banner_wrap.add_theme_stylebox_override("panel", _panel(Color(0.025,0.03,0.03,0.90), Color("a37f48"), 1, 8, 5))
	banner_wrap.visible = false
	root.add_child(banner_wrap)
	banner = _label("", 17, Color("f2d5a0"), HORIZONTAL_ALIGNMENT_CENTER)
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_wrap.add_child(banner)

func _build_command_dock(root: Control) -> void:
	var dock := PanelContainer.new()
	command_dock = dock
	dock.anchor_left = 0.012
	dock.anchor_right = 0.988
	dock.anchor_top = 1.0
	dock.anchor_bottom = 1.0
	dock.offset_top = -110.0
	dock.offset_bottom = -9.0
	dock.add_theme_stylebox_override("panel", _panel(Color(0.019,0.032,0.042,0.980), Color("ab8c58"), 2, 12, 10))
	root.add_child(dock)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 7)
	dock.add_child(row)
	recruit_buttons[0] = button(row, "SPEAR HUNTER\n65 GOLD", game.try_recruit_slot.bind(0), 150, "human", "hunter")
	recruit_buttons[1] = button(row, "SLING SKIRMISHER\n84 GOLD", game.try_recruit_slot.bind(1), 150, "human", "slinger")
	recruit_buttons[1].add_theme_font_size_override("font_size", 10)
	recruit_buttons[2] = button(row, "STONE HAULER\n145 GOLD", game.try_recruit_slot.bind(2), 150, "human", "hauler")
	for slot in recruit_buttons.keys():
		cooldown_bars[slot] = _button_meter(recruit_buttons[slot], HUMAN_BRIGHT)
	age_button = button(row, "BRONZE AGE\n220 GOLD", game.try_advance_age, 126, "age", "age")
	age_progress_bar = _button_meter(age_button, GOLD)
	hold_button = button(row, "HOLD\nPOSITION", game.toggle_hold, 106, "order", "hold")
	repair_button = button(row, "REPAIR GATE\n135 GOLD", game.try_repair, 126, "repair", "repair")
	var divider := VSeparator.new()
	divider.custom_minimum_size.x = 3
	row.add_child(divider)
	button(row, "FORT", game.focus_human, 76, "nav", "fort")
	button(row, "FRONT", game.focus_front, 80, "nav", "front")
	button(row, "OGRES", game.focus_enemy, 85, "danger", "ogres")
	pause_button = button(row, "", game.toggle_pause, 65, "nav", "pause")

func button(parent: Node, text_value: String, action: Callable, width: int, role: String = "neutral", icon_name: String = "", height: int = 82) -> Button:
	var control := Button.new()
	control.text = text_value
	control.custom_minimum_size = Vector2(width, height)
	control.expand_icon = true
	control.add_theme_constant_override("icon_max_width", 36 if role == "human" else 24)
	control.pressed.connect(action)
	control.add_theme_font_size_override("font_size", 11)
	control.add_theme_color_override("font_color", TEXT)
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_pressed_color", Color.WHITE)
	control.add_theme_color_override("font_disabled_color", Color("6b706f"))
	control.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if icon_name != "":
		control.icon = load(ICON_ROOT + icon_name + ".svg")
		control.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var accent := _role_color(role)
	control.add_theme_stylebox_override("normal", _panel(Color("1c303d").lerp(accent, 0.10), accent.darkened(0.15), 1, 9, 4))
	control.add_theme_stylebox_override("hover", _panel(Color("233c4c").lerp(accent, 0.15), accent.lightened(0.12), 2, 9, 7))
	control.add_theme_stylebox_override("pressed", _panel(accent.darkened(0.53), accent.lightened(0.20), 2, 9, 2))
	control.add_theme_stylebox_override("disabled", _panel(Color(0.035,0.041,0.042,0.94), Color("2c3334"), 1, 8, 0))
	parent.add_child(control)
	var accent_line := ColorRect.new()
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent_line.color = Color(accent.r, accent.g, accent.b, 0.72)
	accent_line.anchor_left = 0.10
	accent_line.anchor_right = 0.90
	accent_line.offset_top = 3
	accent_line.offset_bottom = 5
	control.add_child(accent_line)
	return control

func _button_meter(control: Button, accent: Color) -> ProgressBar:
	var meter := ProgressBar.new()
	meter.min_value = 0
	meter.max_value = 1
	meter.value = 0
	meter.show_percentage = false
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.anchor_left = 0.08
	meter.anchor_right = 0.92
	meter.anchor_top = 1.0
	meter.anchor_bottom = 1.0
	meter.offset_top = -8.0
	meter.offset_bottom = -4.0
	meter.add_theme_stylebox_override("background", _panel(Color(0.015,0.018,0.019,0.9), Color(0,0,0,0), 0, 2, 0))
	meter.add_theme_stylebox_override("fill", _panel(accent, accent, 0, 2, 0))
	control.add_child(meter)
	return meter

func _set_icon(control: Button, icon_name: String) -> void:
	# Phase 9 recruit cards use authored portrait badges instead of generic line icons.
	# Navigation/order buttons still use the lighter Phase 5 icon family.
	var wanted := P9_UNIT_ROOT + icon_name + ".svg"
	if not ResourceLoader.exists(wanted):
		wanted = ICON_ROOT + icon_name + ".svg"
	if control.get_meta("ow_icon", "") == wanted:
		return
	control.icon = load(wanted)
	control.set_meta("ow_icon", wanted)

func _role_color(role: String) -> Color:
	match role:
		"human": return HUMAN_BRIGHT
		"age": return GOLD
		"order": return Color("7fa374")
		"repair": return Color("bd8653")
		"danger": return OGRE_BRIGHT
		"nav": return Color("829194")
		_: return Color("7b8586")

func _panel(bg: Color, border: Color, width: int = 1, radius: int = 6, shadow: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	style.anti_aliasing = true
	if shadow > 0:
		style.shadow_color = Color(0,0,0,0.50)
		style.shadow_size = shadow
		style.shadow_offset = Vector2(0, 3)
	return style

func _label(text_value: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var control := Label.new()
	control.text = text_value
	control.horizontal_alignment = align
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)
	return control

func modal(root: Node, title: String, show_now: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220.0
	panel.offset_right = 220.0
	panel.offset_top = -220.0
	panel.offset_bottom = 220.0
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_theme_stylebox_override("panel", _panel(Color(0.025,0.032,0.034,0.99), Color("a17e4b"), 2, 13, 10))
	root.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 13)
	panel.add_child(stack)
	if title != "":
		var heading := _label(title, 27, Color("f0d7a5"), HORIZONTAL_ALIGNMENT_CENTER)
		stack.add_child(heading)
	panel.visible = show_now
	return panel

func announce(message: String, duration: float) -> void:
	banner.text = message
	banner_clock = duration
	if is_instance_valid(banner_wrap):
		banner_wrap.visible = message != ""

func refresh() -> void:
	if not is_instance_valid(game) or not is_instance_valid(status):
		return
	var hero: MarchFortress = game.human_fort
	var foe: MarchFortress = game.orc_fort
	var hk: float = hero.keep_hp / MarchFortress.KEEP_MAX * 100.0
	var hg: float = hero.gate_hp / MarchFortress.GATE_MAX * 100.0
	var ok: float = foe.keep_hp / MarchFortress.KEEP_MAX * 100.0
	var og: float = foe.gate_hp / MarchFortress.GATE_MAX * 100.0
	human_keep_bar.value = hk
	human_gate_bar.value = hg
	orc_keep_bar.value = ok
	orc_gate_bar.value = og
	_hbar_text(human_keep_bar, "KEEP  %d%%" % ceili(hk))
	_hbar_text(human_gate_bar, "GATE  %d%%" % ceili(hg))
	_hbar_text(orc_keep_bar, "KEEP  %d%%" % ceili(ok))
	_hbar_text(orc_gate_bar, "GATE  %d%%" % ceili(og))
	human_age_label.text = "%s AGE" % game.age_name(-1)
	orc_age_label.text = "%s AGE" % game.age_name(1)
	_update_faction_progress(-1, human_progress_bar)
	_update_faction_progress(1, orc_progress_bar)
	gold_label.text = "%d GOLD" % int(game.gold[-1])
	army_label.text = "%d/%d" % [game.count_side(-1), int(game.POPULATION_CAP)]
	timer_label.text = "%02d:%02d" % [floori(game.match_time / 60.0), int(game.match_time) % 60]
	status.text = "PUSH EAST" if not game.hold_order else "DEFEND HOME"
	hold_button.text = "ADVANCE\nNOW" if game.hold_order else "HOLD\nPOSITION"
	var roster: Array = game.current_roster(-1)
	for slot in recruit_buttons.keys():
		var control: Button = recruit_buttons[slot]
		var unit_kind: String = str(roster[slot])
		var unit_stats: Dictionary = MarchSoldier.CLASSES[unit_kind]
		control.text = "%s\n%d GOLD" % [str(unit_stats["title"]).to_upper(), int(unit_stats["cost"])]
		_set_icon(control, str(UNIT_ICON.get(unit_kind, "hunter")))
		var cooldown_total: float = maxf(0.01, float(unit_stats["cooldown"]))
		var remaining: float = maxf(0.0, float(game.recruit_ready[-1]) - game.match_time)
		var meter: ProgressBar = cooldown_bars[slot]
		meter.value = 1.0 - clampf(remaining / cooldown_total, 0.0, 1.0)
		control.disabled = game.phase != "playing" or get_tree().paused or game.count_side(-1) >= int(game.POPULATION_CAP) or int(game.gold[-1]) < int(unit_stats["cost"]) or remaining > 0.0
	if int(game.age[-1]) == 2:
		age_button.text = "IRON AGE\nMAX"
		age_progress_bar.value = 1.0
	else:
		age_button.text = "%s AGE\n%d GOLD" % ["BRONZE" if int(game.age[-1]) == 0 else "IRON", game.age_cost(-1)]
		age_progress_bar.value = clampf(float(game.age_progress[-1]) / maxf(1.0, game.progress_required(-1)), 0.0, 1.0)
	age_button.disabled = get_tree().paused or not game.can_advance(-1)
	repair_button.disabled = game.phase != "playing" or get_tree().paused or int(game.gold[-1]) < int(game.REPAIR_COST) or int(game.repairs_used[-1]) >= 2 or hero.gate_hp <= 0.0 or hero.gate_hp >= MarchFortress.GATE_MAX
	hold_button.disabled = game.phase != "playing" or get_tree().paused
	pause_button.disabled = game.phase != "playing" or get_tree().paused
	if is_instance_valid(audio_button) and is_instance_valid(game.audio):
		audio_button.text = "AUDIO ON" if game.audio.enabled else "AUDIO OFF"
	if is_instance_valid(audio_qa_label) and is_instance_valid(game.audio):
		var report: Dictionary = game.audio.startup_audit if not game.audio.startup_audit.is_empty() else game.audio.audio_health_report()
		audio_qa_label.text = ("AUDIO RESOURCES OK  •  3 MUSIC  •  %d SFX  •  9 DEATH VOICES" % int(report.get("effects_loaded", 0))) if bool(report.get("ok", false)) else "AUDIO RESOURCE CHECK FAILED  •  SEE DEBUG OUTPUT"
		audio_qa_label.add_theme_color_override("font_color", Color("79a883") if bool(report.get("ok", false)) else OGRE_BRIGHT)

func _update_faction_progress(side: int, bar: ProgressBar) -> void:
	if int(game.age[side]) >= 2:
		bar.value = 1.0
	else:
		bar.value = clampf(float(game.age_progress[side]) / maxf(1.0, game.progress_required(side)), 0.0, 1.0)

func _hbar_text(bar: ProgressBar, value_text: String) -> void:
	if bar.get_child_count() > 0 and bar.get_child(0) is Label:
		(bar.get_child(0) as Label).text = value_text

func set_audio_qa_state(active: bool, message: String = "") -> void:
	if is_instance_valid(audio_qa_button):
		audio_qa_button.text = "STOP AUDIO CHECK" if active else "AUDIO CHECK"
	if message != "" and is_instance_valid(audio_qa_label):
		audio_qa_label.text = message
		audio_qa_label.add_theme_color_override("font_color", GOLD if active else Color("79a883"))

func show_paused(is_paused: bool) -> void:
	pause_panel.visible = is_paused
	refresh()

func show_result(won: bool, seconds: float, human_losses: int, orc_losses: int, score: int) -> void:
	pause_panel.visible = false
	result_panel.visible = true
	if is_instance_valid(result_crest):
		result_crest.texture = load(P8_ROOT + ("human_crest.svg" if won else "ogre_crest.svg"))
	result_title.text = "OGRE KEEP DESTROYED" if won else "YOUR KEEP HAS FALLEN"
	result_title.add_theme_color_override("font_color", HUMAN_BRIGHT if won else OGRE_BRIGHT)
	result_detail.text = "SCORE  %d\nBATTLE  %02d:%02d\n\nHUMAN LOSSES  %d     OGRE LOSSES  %d\nHUMANS  %s AGE     OGRES  %s AGE" % [score, floori(seconds / 60.0), int(seconds) % 60, human_losses, orc_losses, game.age_name(-1), game.age_name(1)]
	announce("THE VALLEY IS OURS" if won else "THE VALLEY HAS FALLEN", 5.0)
	refresh()

func _process(delta: float) -> void:
	if banner_clock > 0.0:
		banner_clock -= delta
		if banner_clock <= 0.0:
			banner.text = ""
			if is_instance_valid(banner_wrap):
				banner_wrap.visible = false
