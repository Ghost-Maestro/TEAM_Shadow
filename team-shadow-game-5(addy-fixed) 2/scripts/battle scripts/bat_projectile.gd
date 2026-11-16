extends Area2D

@export var travel_duration: float = 1.2

# Damage dealt
var damage: int = 0
# Prevents damaging Player multiple times
var has_hit_player: bool = false
# Stores specific player this projectile is targeting
var attack_target: CharacterBody2D


func launch(target_position: Vector2, attack_damage: int):
	damage = attack_damage
	var tween = create_tween()
	tween.tween_property(
		self,
		"global_position",
		target_position,
		travel_duration
	).set_trans(Tween.TRANS_LINEAR)
	# Wait until projectile finishes traveling
	await tween.finished
	# Remove projectile if it missed its target
	queue_free()


# Detects when projectile collides with Player
func _on_body_entered(body):
	if has_hit_player:
		return
	# Ignore the other party members completely
	if not is_instance_valid(attack_target):
		return
	if body != attack_target:
		return
	if not attack_target.can_receive_enemy_damage:
		return
	# Prevent multiple hits from the same projectile
	has_hit_player = true
	print("Bat projectile hit ", attack_target.player_name)
	attack_target.take_damage(damage)
	queue_free()
