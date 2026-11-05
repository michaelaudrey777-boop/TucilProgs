extends Node

@export_category("Bird Ambience")
@export var bird_min_interval: float = 8.0
@export var bird_max_interval: float = 20.0

@onready var music: AudioStreamPlayer = $Music
@onready var bird: AudioStreamPlayer = $Bird
@onready var footsteps: AudioStreamPlayer = $Footsteps
@onready var ui_button: AudioStreamPlayer = $UIButton
@onready var rock_step: AudioStreamPlayer = $RockStep

func _ready() -> void:
	start_music()
	play_bird_occasionally()

func start_music() -> void:
	if music.stream != null:
		music.play()

func play_bird_occasionally() -> void:
	while is_inside_tree():
		var wait_time: float = randf_range(
			bird_min_interval,
			bird_max_interval
		)

		await get_tree().create_timer(wait_time).timeout

		if not is_inside_tree():
			break

		if bird.stream != null:
			bird.play()
			await bird.finished


func play_step(surface_type: String) -> void:
	if surface_type == "rock":
		if rock_step.stream != null:
			rock_step.play()
	else:
		if footsteps.stream != null:
			footsteps.play()


func play_ui_button() -> void:
	if ui_button.stream != null:
		ui_button.play()


func set_music_volume(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Music")

	if bus_index != -1:
		AudioServer.set_bus_volume_linear(
			bus_index,
			clampf(value / 100.0, 0.0, 1.0)
		)


func set_sfx_volume(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("SFX")

	if bus_index != -1:
		AudioServer.set_bus_volume_linear(
			bus_index,
			clampf(value / 100.0, 0.0, 1.0)
		)
