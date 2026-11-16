extends Node2D

var enemy_data: EnemyData
var starting_position: Vector2
var current_health: int
var max_health: int
var enemy_name: String
var attack_active: bool = false
var player_hit_this_attack: bool = false
var attack_target: CharacterBody2D

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
	# Uses player's marker for positioning
	var attack_position = Vector2(
		player_marker.global_position.x + 100,
		player_marker.global_position.y
	)
	await move_to_position(attack_position)
	await get_tree().create_timer(0.5).timeout
	var attack_choice = randi_range(0, 1)

	if attack_choice == 0:
		await dash_attack(player, player_marker)
	else:
		await jump_attack(player, player_marker)
	await get_tree().create_timer(0.5).timeout
	await return_from_right()
	attack_target = null
	print(enemy_name, " finished attacking")


func dash_attack(_player, player_marker):
	print(enemy_name, " chosed DASH")
	player_hit_this_attack = false
	attack_active = true
	
	var dash_target = Vector2(
		-100,
		player_marker.global_position.y
	)
	var tween = create_tween()
	
	tween.tween_property(
		self,
		"global_position",
		dash_target,
		# Dash Speed
		2.6
	)
	await tween.finished
	attack_active = false


func jump_attack(player, player_marker):
	print(enemy_name, " chosed JUMP")
	player_hit_this_attack = false
	attack_active = true
	# rats attack based on the PlayerPosition marker
	var jump_peak = Vector2(
		player_marker.global_position.x + 20,
		player_marker.global_position.y - 45
	)
	var landing_position = Vector2(
		-100,
		player_marker.global_position.y
	)
	var tween = create_tween()
	
	# Jump upward toward the Player's fixed position.
	tween.tween_property(
		self,
		"global_position",
		jump_peak,
		0.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Comes down and continue offscreen
	tween.tween_property(
		self,
		"global_position",
		landing_position,
		0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await tween.finished
	attack_active = false


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
	# register the hit if target can receive damage
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
