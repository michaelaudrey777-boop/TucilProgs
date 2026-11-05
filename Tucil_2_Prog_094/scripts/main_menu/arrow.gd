extends Sprite2D

var p1 = Vector2(740, 442)
var p2 = Vector2(626, 563)
var p3 = Vector2(751, 682)
var thep = [p1,p2,p3]
var x = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = p1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("Up") or Input.is_action_pressed("Left"):
		x -= 1
		if x < 0:
			x = 2
	if Input.is_action_pressed("Down") or Input.is_action_pressed("Right"):
		x += 1
		if x > 2:
			x = 0
	position = thep[x]
