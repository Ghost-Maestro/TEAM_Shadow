extends CharacterBody2D

var speed = 500 
var player_state

@onready var _movement = $AnimatedSprite2D


func _ready() -> void:
	_movement.play("Back")

# Movement Script
func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction.x == 0 and direction.y == 0:
		player_state = "idle"
	elif direction.x != 0 or direction.y != 0:
		player_state = "walking"
		
		
	
	velocity = direction * speed
	move_and_slide()
	
	play_animation(direction)


# Overworld Movement Animation 
func play_animation(dir):
	# up, down, left, right, stop
	if dir.y > -0.8:
		speed = 0
	if dir.y > 0.8:
		speed = 0
	if dir.x < -0.8:
		speed = 0
	if dir.x > 0.8:
		speed = 0
		
		
	# up left, up right, down right, down left, stop
	if dir.x < 0.4 and dir.y > -0.4:
		speed = 0
	if dir.x < 0.4 and dir.y < 0.4:
		speed = 0
	if dir.x > -0.4 and dir.y < 0.4:
		speed = 0
	if dir.x > -0.4 and dir.y > -0.4:
		speed = 0
	
	# print(dir)
	if player_state == "idle":
		_movement.play("Front")
	
	if player_state == "walking":
	# up, down, left, right, Move
		if dir.y <= -0.8:
			_movement.play("up")
			speed = 700
		if dir.y >= 0.8:
			_movement.play("down")
			speed = 700
		if dir.x <= -0.8:
			speed = 700
			_movement.play("left")
			speed = 700
		#elif speed == 0:
		#	_movement.play("Side_Left")
		if dir.x >= 0.8:
			_movement.play("right")
			speed = 700
			
		# up left, up right, down right, down left, move
		if dir.x > 0.4 and dir.y < -0.4:
			_movement.play("up_right")
			speed = 700
		if dir.x > 0.4 and dir.y > 0.4:
			_movement.play("down_right")
			speed = 700
		if dir.x < -0.4 and dir.y > 0.4:
			_movement.play("down_left")
			speed = 700
		if dir.x < -0.4 and dir.y < -0.4:
			_movement.play("up_left")
			speed = 700


# jump commands
