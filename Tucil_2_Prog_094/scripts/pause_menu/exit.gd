extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self_modulate = Color(1, 1, 1, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	self_modulate = Color(1.5, 1.5, 1.5, 1.0)


func _on_mouse_exited() -> void:
	self_modulate = Color(1, 1, 1, 1)

func _on_pressed() -> void:
	get_tree().quit()
