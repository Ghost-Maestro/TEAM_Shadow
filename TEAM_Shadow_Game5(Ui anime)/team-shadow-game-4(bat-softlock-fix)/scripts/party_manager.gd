extends Node

# Enables or disables Player 2 for testing
var player2_enabled: bool = true

# Player 1 permanent lvl progression
var player1_level: int = 1
var player1_xp: int = 0
var player1_next_level_xp: int = 10

# Player 2 permanent lvl progression
var player2_level: int = 1
var player2_xp: int = 0
var player2_next_level_xp: int = 10


# Player 1 Stats
func get_player1_max_health() -> int:
	return 5 + (10 * player1_level)      #Level 1, 15 Health, +10 each level
func get_player1_speed() -> int:     
	return 10 + (2 * player1_level)      #Level 1, 12 Speed, +2 speed each level
func get_player1_strength() -> int:
	return 3 * player1_level             #Level 1, 3 strength bonus

# Player 2's stats
func get_player2_max_health() -> int:
	return 15 + (15 * player2_level)      #Level 1, 30 Health, +15 each level
func get_player2_speed() -> int:
	return 9 + (1 * player2_level)       #Level 1, 10 Speed, +1 speed each level
func get_player2_strength() -> int:
	return 2 * player2_level             #Level 1, 2 strength bonus

# Gives XP to player 1
func give_player1_xp(amount: int):
	player1_xp += amount
	print("Player 1 gained ", amount, " XP")
	print("XP: ", player1_xp, "/", player1_next_level_xp)
	check_player1_level_up()

# Gives XP to player 2 and level up
func give_player2_xp(amount: int):
	player2_xp += amount
	while player2_xp >= player2_next_level_xp:
		player2_xp -= player2_next_level_xp
		player2_level += 1
		player2_next_level_xp = 10 * player2_level


# Checks if player 1 earned enough XP to level up
func check_player1_level_up():
	while player1_xp >= player1_next_level_xp:
		player1_xp -= player1_next_level_xp
		player1_level += 1
		player1_next_level_xp += 10
		print("PLAYER 1 LEVEL UP, ", player1_level)
