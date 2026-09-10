extends AnimatedSprite2D

@onready var _maestro_movement = $"maestro_movement"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_maestro_movement.play("Front")
	

func _input(event):
	if event.is_action_pressed("y_button"):
		_maestro_movement.play("Right")
