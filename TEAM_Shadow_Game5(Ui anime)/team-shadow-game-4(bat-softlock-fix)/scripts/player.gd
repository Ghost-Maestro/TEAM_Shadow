extends CharacterBody2D

@export var speed: float = 700.0
var player_state

@onready var _movement = $AnimatedSprite2D


# Custom actions defined, movement
func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		player_state = "idle"
	else:
		player_state = "walking"
	velocity = direction * speed
	move_and_slide()
	play_animation(direction)


# Player position after battle on overworld
func _ready() -> void:
	_movement.play("Back")
	if EncounterManager.has_return_position:
		global_position = EncounterManager.overworld_return_position
		print("Returned from battle, player position: ", global_position)
		EncounterManager.has_return_position = false


# Overworld Movement Animation
func play_animation(dir: Vector2) -> void:
	# Idle
	if player_state == "idle":
		_movement.play("Front")
		return
	# Diagonal movement
	if dir.x > 0.4 and dir.y < -0.4:
		_movement.play("up_right")
	elif dir.x > 0.4 and dir.y > 0.4:
		_movement.play("down_right")
	elif dir.x < -0.4 and dir.y > 0.4:
		_movement.play("down_left")
	elif dir.x < -0.4 and dir.y < -0.4:
		_movement.play("up_left")
		
	# Cardinal movement
	elif dir.y <= -0.4:
		_movement.play("up")
	elif dir.y >= 0.4:
		_movement.play("down")
	elif dir.x <= -0.4:
		_movement.play("left")
	elif dir.x >= 0.4:
		_movement.play("right")
