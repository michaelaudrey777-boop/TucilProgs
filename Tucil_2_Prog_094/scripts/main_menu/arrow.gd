extends Sprite2D

var p1 = Vector2(740, 442)
var p2 = Vector2(626, 563)
var p3 = Vector2(751, 682)
var thep = [p1,p2,p3]
var x = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = p1
	$"../../..".visible = true
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("Up") or Input.is_action_pressed("Left"):
		x -= 1
		if x < 0:
			x = 2
	if Input.is_action_pressed("Down") or Input.is_action_pressed("Right"):
		x += 1
		if x > 2:
			x = 0
	position = thep[x]
	if Input.is_action_pressed("ui_accept"):
		if $"../Exit".has_focus():
			get_tree().quit()
		if $"../Play".has_focus():
			$"../../..".queue_free()
			get_tree().paused = false
			
func _process(delta: float) -> void:
	if position == p1:
		$"../Play".grab_focus()
	if position == p2:
		$"../Settings".grab_focus()
	if position == p3:
		$"../Exit".grab_focus()
