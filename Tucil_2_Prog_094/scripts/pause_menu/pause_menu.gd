extends Control

var pause_button = preload("res://assets/pause_menu/Pause.png")
var start_button = preload("res://assets/pause_menu/Start.png")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # so it works while the tree is paused
	visible = false

func _on_button_pressed() -> void:
	toggle_pause()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var paused = not get_tree().paused
	get_tree().paused = paused
	visible = paused
	if paused == false:
		$"../Button".icon = pause_button
	else:
		$"../Button".icon = start_button
