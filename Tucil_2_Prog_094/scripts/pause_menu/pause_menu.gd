extends Control

@onready var music_slider: HScrollBar = $thethings/musicscroll
@onready var sfx_slider: HScrollBar = $thethings/sfxscroll

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1

	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _on_music_slider_changed(value: float) -> void:
	AudioManager.set_music_volume(value)


func _on_sfx_slider_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

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
