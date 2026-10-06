extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run_checks() -> void:
	var game := MarchMatch.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	await process_frame

	# Every command must be inside the 1280x720 mobile-safe viewport.
	var screen := root.get_visible_rect()
	check(game.hud.command_dock != null, "Battle command dock exists")
	var status_bar := game.hud.find_child("BattleStatusBar", true, false) as Control
	check(status_bar != null and status_bar.get_global_rect().end.y <= 110.0, "Compact status leaves room for the battlefield: " + str(status_bar.get_global_rect() if status_bar != null else "missing"))
	check(game.hud.command_dock.get_global_rect().size.y <= 112.0, "One-row commands leave room for the battlefield")
	for control in game.hud.command_dock.find_children("*", "Button", true, false):
		var rect: Rect2 = control.get_global_rect()
		check(rect.position.x >= -1.0 and rect.end.x <= screen.end.x + 1.0, "Command button fits horizontally: " + control.text)
		check(rect.position.y >= -1.0 and rect.end.y <= screen.end.y + 1.0, "Command button fits vertically: " + control.text)
	check(game.hud.command_dock.find_children("*", "Button", true, false).size() == 10, "All recruit, order, scout and pause buttons exist")
	check(game.camera_target_x >= -game.camera_limit(), "Initial camera keeps the valley edge hidden")

	# Desktop touch emulation can deliver both touch and mouse movement. A
	# single swipe should move the camera once, regardless of event order.
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	game._unhandled_input(mouse_down)
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(520, 300)
	game._input(touch_down)
	game._unhandled_input(touch_down)
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 0
	touch_drag.position = Vector2(640, 300)
	touch_drag.relative = Vector2(120, 0)
	game._input(touch_drag)
	game._unhandled_input(touch_drag)
	var after_touch := game.camera_target_x
	var mouse_move := InputEventMouseMotion.new()
	mouse_move.relative = Vector2(120, 0)
	game._unhandled_input(mouse_move)
	check(is_equal_approx(game.camera_target_x, after_touch), "A synthesized mouse move must not pan twice during touch")
	var second_down := InputEventScreenTouch.new()
	second_down.index = 1
	second_down.position = Vector2(820, 300)
	second_down.pressed = true
	game._input(second_down)
	var pinch := InputEventScreenDrag.new()
	pinch.index = 1
	pinch.position = Vector2(900, 300)
	pinch.relative = Vector2(80, 0)
	game._input(pinch)
	game._unhandled_input(pinch)
	check(game.camera.size < game.CAMERA_WIDE_SIZE and game.camera.size >= game.CAMERA_CLOSE_SIZE, "Two fingers zoom the battlefield in")
	var after_pinch := game.camera_target_x
	game._unhandled_input(mouse_move)
	check(is_equal_approx(game.camera_target_x, after_pinch), "Mouse emulation does not pan during a pinch")
	var second_up := InputEventScreenTouch.new()
	second_up.index = 1
	game._input(second_up)
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	game._input(touch_up)
	var mouse_up := InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	game._input(mouse_up)
	game.pan_by(100000.0)
	check(is_equal_approx(game.camera_target_x, -game.camera_limit()), "Left edge is clamped at the current zoom")
	game.pan_by(-200000.0)
	check(is_equal_approx(game.camera_target_x, game.camera_limit()), "Right edge is clamped at the current zoom")
	game.focus_human()
	check(game.camera_target_x >= -game.camera_limit(), "Fort scout button respects camera bounds")
	game.focus_enemy()
	check(game.camera_target_x <= game.camera_limit(), "Ogre scout button respects camera bounds")
	game._zoom_at(640.0, 0.01)
	check(is_equal_approx(game.camera.size, game.CAMERA_CLOSE_SIZE), "Pinch zoom has a readable maximum")
	game._zoom_at(640.0, 100.0)
	check(is_equal_approx(game.camera.size, game.CAMERA_WIDE_SIZE), "Zoom out stops before revealing the map edge")

	game.phase = "won"
	game._unhandled_input(mouse_down)
	var after_result := game.camera_target_x
	mouse_move.relative = Vector2(-100, 0)
	game._unhandled_input(mouse_move)
	check(is_equal_approx(game.camera_target_x, after_result), "Result screen should not pan the battlefield")
	game._input(mouse_up)
	game.phase = "playing"
	game.toggle_pause()
	check(paused and game.hud.pause_panel.visible, "Pause menu opens while the match stops")
	game.toggle_pause()
	check(not paused and not game.hud.pause_panel.visible, "Resume returns to active battle")
	game.hud.show_result(true, 110.0, 2, 4, 1800)
	check(game.hud.result_panel.visible and not game.hud.pause_panel.visible, "Win result is visible and closes pause")
	game.gold[1] = 2000
	for turn in 8:
		game.match_time += 10.0
		game.ai_decision()
	check(game.count_side(1) >= 8, "Orcs reinforce consistently when resources and cooldowns permit")
	var kinds: Array = []
	for soldier in game.soldiers:
		if soldier.side == 1:
			kinds.append(soldier.kind)
	check(kinds.has("thrower") and kinds.has("brute"), "Orc waves include ranged and siege troops")
	game.ai_cycle = 3
	game.match_time += 10.0
	game.gold[1] = 70
	var before_fallback := game.count_side(1)
	game.ai_decision()
	check(game.count_side(1) == before_fallback + 1, "Orcs field an affordable defender when their siege choice costs too much")

	game.free()
	await create_timer(1.0).timeout
	if failures == 0:
		print("Ogre War camera, pinch, mobile dock, AI, result and pause regression checks passed.")
	call_deferred("quit", 1 if failures > 0 else 0)
