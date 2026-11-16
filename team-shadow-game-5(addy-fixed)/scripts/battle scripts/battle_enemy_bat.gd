extends Node2D

var enemy_data: EnemyData
var starting_position: Vector2
var current_health: int
var max_health: int
var enemy_name: String
var attack_active: bool = false
var player_hit_this_attack: bool = false
var attack_target: CharacterBody2D

# Controls the size of Bat's circular attack
var spin_radius_x: float = 55.0
var spin_radius_y: float = 40.0
# Controls how long one circle takes
var spin_duration: float = 2.0
# controls how long the Bat takes to dive and return
var spin_dive_duration: float = 0.7
var spin_return_duration: float = 0.8

# projectile scene used, and how long before spitting
@export var projectile_scene: PackedScene
@export var spit_windup: float = 0.6
@onready var name_label = $HealthUI/NameLabel
@onready var health_bar = $HealthUI/HealthBar

# Controls enemy is blinking as the selected target
var is_targeted: bool = false
# Counts time between sprite visibility 
var blink_timer: float = 0.0
# Controls how quickly selected enemy blinks
var blink_interval: float = 0.15
@onready var enemy_sprite: Sprite2D = $Sprite2D


func setup(data: EnemyData):
	starting_position = global_position
	enemy_data = data
	enemy_name = data.name
	max_health = data.health
	current_health = max_health
	name_label.text = enemy_name
	health_bar.max_value = max_health
	health_bar.value = current_health
	print(enemy_name, " entered battle with ", current_health, " HP")


func take_damage(amount: int):
	current_health -= amount
	if current_health < 0:
		current_health = 0
	health_bar.value = current_health
	print(enemy_name, " took ", amount, " damage")
	print(enemy_name, " HP: ", current_health, "/", max_health)
	if current_health <= 0:
		die()

func die():
	print(enemy_name, " was defeated!")
	queue_free()

# Performs attack against selected player
func perform_attack(player, player_marker):
	# Store the player selected by battle manager
	attack_target = player
	print(enemy_name, " is attacking ", attack_target.player_name)
	var attack_position = Vector2(
		player_marker.global_position.x + 100,
		player_marker.global_position.y - 25
	)
	await move_to_position(attack_position)
	await get_tree().create_timer(0.5).timeout
	var attack_choice = randi_range(0, 1)
	if attack_choice == 0:
		await flying_spin_attack(player, player_marker)
	else:
		await spit_projectile_attack(player, player_marker)
	await get_tree().create_timer(0.5).timeout
	await move_to_position(starting_position)
	attack_target = null
	print(enemy_name, " finished attacking")

# Makes the Bat dive toward the Player, then circle around them a random amount of times
func flying_spin_attack(_player, player_marker):
	print(enemy_name, " used FLYING SPIN")
	var spin_count = randi_range(1, 3)
	print("Spins: ", spin_count)

	var player_ground = player_marker.global_position
	# Places circle's center above Player
	var circle_center = Vector2(
		player_ground.x,
		player_ground.y - spin_radius_y
	)
	# Calculates highest point of circle
	var circle_top = Vector2(
		circle_center.x,
		circle_center.y - spin_radius_y
	)
	# Resets Bat's damage tracking
	player_hit_this_attack = false
	attack_active = false
	await move_to_position(circle_top)

	# Performs randomut # of circles around Player
	for i in range(spin_count):
		# Allows Bat to damage Player once each circle
		player_hit_this_attack = false
		attack_active = true
		await perform_spin_circle(circle_center)
		attack_active = false


# Moves the Bat around one complete circle
func perform_spin_circle(circle_center: Vector2):
	var spin_tween = create_tween()
	# Number of points used to create circular movement
	var steps: int = 32
	# Divides full spin duration between each point
	var step_duration = spin_duration / steps

	for step in range(1, steps + 1):
		# Calculates current angle around the circle
		var angle = -PI / 2.0 + TAU * float(step) / steps
		# Calculates next position on the circular path
		var next_position = Vector2(
			circle_center.x + cos(angle) * spin_radius_x,
			circle_center.y + sin(angle) * spin_radius_y
		)
		# Moves Bat to the next point on  circle
		spin_tween.tween_property(
			self,
			"global_position",
			next_position,
			step_duration
		).set_trans(Tween.TRANS_LINEAR)
	await spin_tween.finished


# Spits projectile toward Player's marker
func spit_projectile_attack(_player, player_marker):
	print(enemy_name, " used SPIT PROJECTILE")
	# Gives Player moment to prepare.
	await get_tree().create_timer(spit_windup).timeout

	if projectile_scene == null:
		push_warning("Bat projectile scene has not been assigned")
		return
	# Creates projectile
	var projectile = projectile_scene.instantiate()
	# Adds projectile to  battle scene
	get_tree().current_scene.add_child(projectile)
	# Starts projectile at Bat's current position.
	projectile.global_position = global_position

	var target_position = player_marker.global_position
	projectile.attack_target = attack_target
	# Launches projectile and waits for finish
	projectile.launch(target_position, enemy_data.damage)
	await get_tree().create_timer(3.0).timeout
	print("Bat projectile attack finished")


func move_to_position(target_position: Vector2):
	var tween = create_tween()
	tween.tween_property(
		self,
		"global_position",
		target_position,
		# speed to getting in position to attack Player
		1.0
	)
	await tween.finished


func return_from_right():
	var right_offscreen_x = 700.0
	# reappears offscreen at THIS Rat's original Marker2D height
	global_position = Vector2(
		right_offscreen_x,
		starting_position.y
	)
	var tween = create_tween()
	
	tween.tween_property(
		self,
		"global_position",
		starting_position,
		1.0
	)
	await tween.finished


func _on_attack_hitbox_body_entered(body):
	if not attack_active:
		return
	if player_hit_this_attack:
		return
	if not is_instance_valid(attack_target):
		return
	if body != attack_target:
		return
	if not attack_target.can_receive_enemy_damage:
		return
		
	player_hit_this_attack = true
	print(enemy_name, " HIT ", attack_target.player_name)
	attack_target.take_damage(enemy_data.damage)


# updates the blinking effect while enemy is selected
func _process(delta):
	if is_targeted:
		blink_timer += delta
		if blink_timer >= blink_interval:
			blink_timer = 0.0
			enemy_sprite.visible = not enemy_sprite.visible


# Turns the targeted blink effect on or off
func set_targeted(targeted: bool):
	is_targeted = targeted
	blink_timer = 0.0
	# makes  sprite visible when targeting ends
	if not targeted:
		enemy_sprite.visible = true
