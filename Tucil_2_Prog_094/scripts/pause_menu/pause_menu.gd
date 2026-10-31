extends Control

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
	$"../pause".visible = not paused

func _on_return_pressed() -> void:
	toggle_pause()
