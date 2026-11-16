extends CharacterBody2D

var player_name: String = "THRE-SHI"
var max_health: int
var current_health: int
var can_jump: bool = false
var is_jumping: bool = false
var ground_y: float
var jump_height: float = 37.0
var jump_duration: float = 1.1
# Determines whether this player is the current enemy attack target
var can_receive_enemy_damage: bool = false

@onready var name_label: Label = $HealthUI/NameLabel
@onready var health_bar: ProgressBar = $HealthUI/HealthBar

func _ready():
	max_health = PartyManager.get_player2_max_health()
	current_health = max_health
	ground_y = global_position.y
	setup_health_ui()

func enable_dodging():
	ground_y = global_position.y
	can_jump = true

func disable_dodging():
	can_jump = false

func setup_health_ui():
	name_label.text = player_name
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = current_health
	print("Player name: ", player_name)
	print("Player HP: ", current_health, "/", max_health)
	print("Health bar value: ", health_bar.value)


# Takes damage only when this player is the selected target
func take_damage(amount: int):
	if not can_receive_enemy_damage:
		return
	if current_health <= 0:
		return
	current_health -= amount
	if current_health < 0:
		current_health = 0
	health_bar.value = current_health
	print(player_name, " took ", amount, " damage")
	print("Player HP: ", current_health, "/", max_health)
	if current_health <= 0:
		die()


# Defeated
func die():
	print("Thre-Shi defeated")
	can_jump = false
	can_receive_enemy_damage = false

func jump():
	if not can_jump:
		return
	if is_jumping:
		return
	is_jumping = true
	var start_y = global_position.y
	var tween = create_tween()

	# jump rise 
	tween.tween_property(
		self,
		"global_position:y",
		start_y - jump_height,
		jump_duration * 0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# hang time
	tween.tween_interval(0.12)

	# Jump fall 
	tween.tween_property(
		self,
		"global_position:y",
		start_y,
		jump_duration * 0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	is_jumping = false

# Gives Player 2 XP 
func gain_xp(amount: int):
	PartyManager.player2_xp += amount
	print("gained ", amount, " XP")
	print("XP: ", PartyManager.player2_xp, "/", PartyManager.player2_next_level_xp)
	check_level_up()

# Checks Player 2 has XP to level up
func check_level_up():
	while PartyManager.player2_xp >= PartyManager.player2_next_level_xp:
		PartyManager.player2_xp -= PartyManager.player2_next_level_xp
		PartyManager.player2_level += 1
		print("Current Level ", PartyManager.player2_level)
		PartyManager.player2_next_level_xp += 10
		print("XP: ", PartyManager.player2_xp, "/", PartyManager.player2_next_level_xp)
