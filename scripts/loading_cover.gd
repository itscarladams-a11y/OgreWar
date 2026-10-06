extends CanvasLayer

# This canvas survives the loading scene while the large battlefield builds.
# It releases the painting only after the battle has rendered underneath it.
var progress_bar: ProgressBar
var stage_label: Label
var cover_screen: Control

func _init() -> void:
	layer = 100

func start(bar: ProgressBar, stage: Label, screen: Control) -> void:
	progress_bar = bar
	stage_label = stage
	cover_screen = screen
	call_deferred("_await_battle")

func _await_battle() -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while not get_tree().current_scene is MarchMatch and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if not get_tree().current_scene is MarchMatch:
		stage_label.text = "BATTLEFIELD COULD NOT START"
		var home := Button.new()
		home.text = "RETURN TO WAR ROOM"
		cover_screen.add_child(home)
		home.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		home.position.y -= 205.0
		home.pressed.connect(_return_home)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	progress_bar.value = 100
	stage_label.text = "MARCH!"
	var fade := create_tween()
	fade.tween_property(cover_screen, "modulate:a", 0.0, 0.25)
	await fade.finished
	queue_free()

func _return_home() -> void:
	get_tree().change_scene_to_file("res://scenes/home.tscn")
	queue_free()
