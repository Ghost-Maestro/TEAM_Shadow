extends Node2D

@export var battle_player_scene: PackedScene
@onready var player_container = $PlayerContainer
@onready var player_position = $PlayerPosition
@onready var enemies_container = $Enemies
@onready var command_panel = $BattleUI/CommandPanel
@onready var enemy_positions = [
	$EnemyPosition/EnemyPosition1,
	$EnemyPosition/EnemyPosition2,
	$EnemyPosition/EnemyPosition3
]
# Stores which command Player currently has selected
# 0 = Attack, 1 = Run
var selected_command: int = 0
# Gets command labels from battle UI
@onready var attack_label: Label = $BattleUI/CommandPanel/VBoxContainer/AttackLabel
@onready var run_label: Label = $BattleUI/CommandPanel/VBoxContainer/RunLabel

# Player 2's scene and spawn position
@export var battle_player2_scene: PackedScene
@onready var player_position2 = $PlayerPosition2
# Tracks Player 2 and player currently taking turn
var player2_instance
var active_player
# Tracks which player an enemy is attacking
var enemy_target

# stores all enemies in battle
var battle_enemies: Array = []
# stores the BattlePlayer 
var player_instance
# begins with the Player's turn, then keeps track of the current turn
var battle_state: BattleState = BattleState.PLAYER_TURN
# Stores all XP earned during current battle
var battle_xp: int = 0
# Whether Player is currently selecting an enemy to attack
var is_selecting_target: bool = false
# The index of currently selected enemy
var selected_enemy_index: int = 0
var turn_order: Array = []
var current_turn_index: int = 0

# victory screen UI
@onready var victory_panel = $BattleUI/VictoryPanel
@onready var victory_title = $BattleUI/VictoryPanel/VBoxContainer/VictoryTitle
@onready var victory_player_name = $BattleUI/VictoryPanel/VBoxContainer/PlayerNameLabel
@onready var victory_level = $BattleUI/VictoryPanel/VBoxContainer/LevelLabel
@onready var victory_exp_bar = $BattleUI/VictoryPanel/VBoxContainer/EXPBar
@onready var victory_exp_label = $BattleUI/VictoryPanel/VBoxContainer/EXPLabel
@onready var victory_stats = $BattleUI/VictoryPanel/VBoxContainer/StatsLabel
@onready var victory_continue = $BattleUI/VictoryPanel/VBoxContainer/ContinueLabel
# Only allows the Player to continue after the EXP animation
var victory_ready_to_continue: bool = false
# Prevents victory sequence from running more than once
var victory_started: bool = false
# Stores total EXP earned from this battle
var victory_total_xp: int = 0
# Tracks which member is currently receiving their EXP
var victory_player_index: int = 0

# control whether it is currently the Players or enemies turn
enum BattleState {
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY
}


# Creates the Player and enemies, then starts the Speed-based turn order.
func _ready():
	spawn_player()
	spawn_enemies()
	victory_panel.hide()
	command_panel.hide()
	build_turn_order()
	start_next_turn()


# Creates Player 1 and optionally Player 2
func spawn_player():
	if player_container == null or player_position == null:
		return
	if battle_player_scene == null:
		return
	# Spawn Player 1
	player_instance = battle_player_scene.instantiate()
	player_container.add_child(player_instance)
	player_instance.global_position = player_position.global_position
	# Debug Player 1's spawn
	print("Player 1 scene: ", player_instance.scene_file_path)
	print("Player 1 position: ", player_instance.global_position)
	print("Player 1 marker: ", player_position.global_position)
	# Spawn Player 2 when enabled
	if PartyManager.player2_enabled:
		if battle_player2_scene == null:
			push_error("Player 2 battle scene is not assigned")
			return
		player2_instance = battle_player2_scene.instantiate()
		player_container.add_child(player2_instance)
		player2_instance.global_position = player_position2.global_position
		# Debug Player 2's spawn
		print("Player 2 scene: ", player2_instance.scene_file_path)
		print("Player 2 position: ", player2_instance.global_position)
		print("Player 2 marker: ", player_position2.global_position)



func spawn_enemies():
	# gets enemies that were selected in encounter manager when encounter started
	var enemies = EncounterManager.current_enemies
	if enemies_container == null:
		return
	# goes through every enemy that needs to be created
	for i in range(enemies.size()):
		# gets enemy's, EnemyData resource.
		var enemy_data = enemies[i]
		print(
			"Battle scene: ",
			enemy_data.battle_scene,
			". Using position: ",
			enemy_positions[i]
		)
		if enemy_positions[i] == null:
			print("ERROR: enemy position ", i, " not found")
			continue
		if enemy_data.battle_scene == null:
			print("ERROR: enemy does not have battle scene")
			continue

# creates enemy's battle scene
		var enemy_instance = enemy_data.battle_scene.instantiate()
# adds enemy to battle
		enemies_container.add_child(enemy_instance)
# gets the enemy's ground position from its assigned marker
		var spawn_position = enemy_positions[i].global_position
# flying enemies spawn above their marker
		if enemy_data.is_flying:
			spawn_position.y -= enemy_data.flying_height
# places enemy at final position
		enemy_instance.global_position = spawn_position
# gives enemy its EnemyData 
		enemy_instance.setup(enemy_data)
# adds the enemy to the list of active enemies
		battle_enemies.append(enemy_instance)


# Handles victory, player commands, enemy targeting, and dodging
func _input(event):
	# VICTORY SCREEN
	if battle_state == BattleState.VICTORY:
		# Wait until EXP animation finishes
		if not victory_ready_to_continue:
			return
		# Press Y to continue to the next player or exit battle
		if event.is_action_pressed("shi_y") and not event.is_echo():
			victory_ready_to_continue = false
			victory_continue.text = ""
			victory_player_index += 1
			show_next_victory_player()
		return

	# PLAYER TURN
	elif battle_state == BattleState.PLAYER_TURN:
		# ENEMY TARGET SELECTION
		if is_selecting_target:
			if event.is_action_pressed("ui_left"):
				change_target(-1)
			elif event.is_action_pressed("ui_right"):
				change_target(1)
			elif event.is_action_pressed("shi_y"):
				confirm_command()
			elif event.is_action_pressed("ui_cancel"):
				stop_target_selection()
			return

		# ATTACK / RUN SELECTION
		if event.is_action_pressed("ui_up"):
			selected_command -= 1
			if selected_command < 0:
				selected_command = 1
			update_command_ui()
		elif event.is_action_pressed("ui_down"):
			selected_command += 1
			if selected_command > 1:
				selected_command = 0
			update_command_ui()
		elif event.is_action_pressed("shi_y"):
			confirm_command()
		return

	# ENEMY TURN
	elif battle_state == BattleState.ENEMY_TURN:
		# Press Y to jump during enemy attacks.
		if event.is_action_pressed("shi_y"):
			if is_player_alive(enemy_target):
				enemy_target.jump()


# Executes the active player's selected command
func confirm_command():
	if battle_state != BattleState.PLAYER_TURN:
		return
	# Confirms the selected attack target
	if is_selecting_target:
		stop_target_selection()
		battle_state = BattleState.ENEMY_TURN
		command_panel.hide()
		# Player 1 attacks selected enemy
		if active_player == player_instance:
			call_deferred("player_basic_attack")
		# Player 2 attacks every enemy
		elif active_player == player2_instance:
			call_deferred("player2_basic_attack")
		return
	# ATTACK command
	if selected_command == 0:
		start_target_selection()
	# RUN command
	elif selected_command == 1:
		run_from_battle()


# Updates command UI showing which option is selected
func update_command_ui():
	if selected_command == 0:
		attack_label.text = "> ATTACK"
		run_label.text = "  RUN"

	elif selected_command == 1:
		attack_label.text = "  ATTACK"
		run_label.text = "> RUN"


# Performs Player's basic two-strike, also checks for when a crit strikes activates
# Performs Player's basic two-strike attack and checks for critical hits.
func player_basic_attack():
	if battle_enemies.is_empty():
		return

	# Gets the enemy selected by the Player
	var front_enemy = battle_enemies[selected_enemy_index]
	# Randomly determines damage for each strike
	var strike_one_roll = randi_range(1, 2)
	var strike_two_roll = randi_range(2, 4)
	# Adds Player 1's Strength bonus
	var strength = PartyManager.get_player1_strength()
	var strike_one = strike_one_roll + strength
	var strike_two = strike_two_roll + strength

	print("----------------")
	print("PLAYER ATTACK")
	print("Strike 1: ", strike_one)
	# First strike
	if is_instance_valid(front_enemy) and not front_enemy.is_queued_for_deletion():
		front_enemy.take_damage(strike_one)
	print("Strike 2: ", strike_two)
	# Second strike, if the target is still alive
	if is_instance_valid(front_enemy) and not front_enemy.is_queued_for_deletion():
		front_enemy.take_damage(strike_two)
	# Critical attack
	if strike_one_roll == 3 and strike_two_roll == 5:
		print("CRITICAL ATTACK")
		critical_third_strike()
	clean_enemy_list()
	if battle_enemies.is_empty():
		battle_won()
	else:
		advance_turn()


# Performs a critical third strike on enemy and enemy behind it, if one exists
func critical_third_strike():
	if battle_enemies.is_empty():
		return
	# Deals bonus damage to the selected enemy
	var target_enemy = battle_enemies[selected_enemy_index]
	var strength = PartyManager.get_player1_strength()
	if is_instance_valid(target_enemy):
		target_enemy.take_damage(strength)
	# Deals damage to the next enemy behind the selected target
	var behind_index = selected_enemy_index + 1
	if behind_index < battle_enemies.size():
		var enemy_behind = battle_enemies[behind_index]
		if is_instance_valid(enemy_behind):
			enemy_behind.take_damage(strength/2)


# Player 2 attacks every living enemy.
func player2_basic_attack():
	clean_enemy_list()
	var strength = PartyManager.get_player2_strength()
	for enemy in battle_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			var player2_basic_attack = randi_range(3, 4)
			var damage = player2_basic_attack + strength
			enemy.take_damage(damage)
	clean_enemy_list()
	if battle_enemies.is_empty():
		battle_won()
	else:
		advance_turn()


# Leaves battle without defeating enemy
func run_from_battle():
	print("----------------")
	print("PLAYER RAN FROM BATTLE")
	print("----------------")
	# Uses the saved return position, 15 pixels left of the enemy.
	EncounterManager.return_to_overworld()


# target selection and highlights first living enemy
func start_target_selection():
	clean_enemy_list()
	if battle_enemies.is_empty():
		return
	is_selecting_target = true
	selected_enemy_index = 0
	
	# Player 1 selects one enemy
	if active_player == player_instance:
		update_target_highlight()
	# Player 2 targets every enemy
	elif active_player == player2_instance:
		for enemy in battle_enemies:
			if is_instance_valid(enemy):
				enemy.set_targeted(true)


# updates which enemy is blinking
func update_target_highlight():
	for i in range(battle_enemies.size()):
		var enemy = battle_enemies[i]
		if is_instance_valid(enemy):
			enemy.set_targeted(i == selected_enemy_index)


# stops targeting and restores enemy sprites
func stop_target_selection():
	is_selecting_target = false
	for enemy in battle_enemies:
		if is_instance_valid(enemy):
			enemy.set_targeted(false)


# Builds turn order from highest Speed to lowest.
func build_turn_order():
	turn_order.clear()

	# Player 1
	if is_player_alive(player_instance):
		turn_order.append({
			"actor": player_instance,
			"speed": PartyManager.get_player1_speed(),
			"is_player": true
		})

	# Player 2
	if PartyManager.player2_enabled and is_player_alive(player2_instance):
		turn_order.append({
			"actor": player2_instance,
			"speed": PartyManager.get_player2_speed(),
			"is_player": true
		})

	# Enemies
	for enemy in battle_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			turn_order.append({
				"actor": enemy,
				"speed": enemy.enemy_data.speed,
				"is_player": false
			})

	turn_order.sort_custom(func(a, b):
		return a["speed"] > b["speed"]
	)
	current_turn_index = 0
	print("TURN ORDER:")
	for entry in turn_order:
		print(entry["actor"].name, " | Speed: ", entry["speed"])


# Checks whether party member is alive
func is_player_alive(player) -> bool:
	return is_instance_valid(player) and player.current_health > 0

# Returns all living members
func get_living_players() -> Array:
	var living_players: Array = []
	if is_player_alive(player_instance):
		living_players.append(player_instance)
	if PartyManager.player2_enabled and is_player_alive(player2_instance):
		living_players.append(player2_instance)
	return living_players

# Checks whether the entire party is defeated
func is_party_defeated() -> bool:
	return get_living_players().is_empty()


# Starts the next living character's turn
func start_next_turn():
	if battle_state == BattleState.VICTORY:
		return
	# Check for party defeat
	if is_party_defeated():
		party_defeated()
		return
	# Check for victory
	clean_enemy_list()
	if battle_enemies.is_empty():
		battle_won()
		return

	var checked: int = 0
	while checked < turn_order.size():
		if current_turn_index >= turn_order.size():
			current_turn_index = 0
		var entry = turn_order[current_turn_index]
		var actor = entry["actor"]
		var can_act = is_instance_valid(actor) and not actor.is_queued_for_deletion()
		if can_act and entry["is_player"]:
			can_act = is_player_alive(actor)
			
		if can_act:
			if entry["is_player"]:
				start_player_turn(actor)
			else:
				start_single_enemy_turn(actor)
			return
		current_turn_index += 1
		checked += 1
	push_warning("No living characters available for a turn.")


# Advances to the next character
func advance_turn():
	current_turn_index += 1
	start_next_turn()

# Starts selected party member's turn
func start_player_turn(player):
	active_player = player
	battle_state = BattleState.PLAYER_TURN
	is_selecting_target = false
	selected_command = 0
	update_command_ui()
	command_panel.show()
	print("PLAYER TURN: ", active_player.player_name)


# Changes selected target using the Left/Right arrows
func change_target(direction: int):
	# Player 2 targets all enemies
	if active_player == player2_instance:
		return
	if battle_enemies.is_empty():
		return
	selected_enemy_index += direction
	if selected_enemy_index < 0:
		selected_enemy_index = battle_enemies.size() - 1
	elif selected_enemy_index >= battle_enemies.size():
		selected_enemy_index = 0
	update_target_highlight()


# Removes enemies from list, keeps battle from interacting with deleted enemies
func clean_enemy_list():
	# duplicate() safely removes enemies while checking original list
	for enemy in battle_enemies.duplicate():
		# Removes enemies that no longer exist 
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			battle_enemies.erase(enemy)


# Selects one living player and performs enemy attack
func start_single_enemy_turn(enemy):
	battle_state = BattleState.ENEMY_TURN
	command_panel.hide()
	var living_players = get_living_players()
	if living_players.is_empty():
		party_defeated()
		return
		
	# Randomly select living party member
	enemy_target = living_players.pick_random()
	
	# Prevent other party members from taking damage
	if is_instance_valid(player_instance):
		player_instance.can_receive_enemy_damage = false
	if is_instance_valid(player2_instance):
		player2_instance.can_receive_enemy_damage = false
		
	# Only the targeted player can receive damage
	enemy_target.can_receive_enemy_damage = true
	print(enemy.name, " is targeting ", enemy_target.player_name)
	
	# Only targeted player can dodge 
	enemy_target.enable_dodging()
	await get_tree().create_timer(0.5).timeout
	
	# Enemy attacks selected player
	if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
		if is_player_alive(enemy_target):
			var target_marker = player_position
			if enemy_target == player2_instance:
				target_marker = player_position2
			await enemy.perform_attack(enemy_target, target_marker)
			
	# Disable dodging and damage after the attack finishes
	if is_instance_valid(enemy_target):
		enemy_target.disable_dodging()
		enemy_target.can_receive_enemy_damage = false
		
	if is_party_defeated():
		party_defeated()
		return
	if battle_state != BattleState.VICTORY:
		advance_turn()


# Ends battle when all party members are defeated
func party_defeated():
	print("----------------")
	print("PARTY DEFEATED")
	# Prevent further battle input
	battle_state = BattleState.ENEMY_TURN
	command_panel.hide()
	EncounterManager.return_to_overworld()


# Starts victory when enemies are defeated
func battle_won():
	if victory_started:
		return
	victory_started = true
	battle_state = BattleState.VICTORY
	# Hide battle commands
	command_panel.hide()
	# Calculate EXP rewards
	victory_total_xp = 0
	for enemy_data in EncounterManager.current_enemies:
		victory_total_xp += enemy_data.get_exp_reward()
	print("BATTLE WON! Total EXP: ", victory_total_xp)
	# Show victory screen and start with Player 1
	victory_player_index = 0
	victory_ready_to_continue = false
	victory_panel.show()
	show_next_victory_player()


# Displays next Player or finishes Victory
func show_next_victory_player():
	if victory_player_index == 0:
		await show_player1_victory()
	elif victory_player_index == 1 and PartyManager.player2_enabled:
		await show_player2_victory()
	else:
		finish_victory()


# Displays Player 1's results
func show_player1_victory():
	victory_ready_to_continue = false
	victory_player_name.text = "PLAYER 1"
	victory_title.text = "VICTORY!"
	victory_continue.text = ""
	update_player1_victory_ui()
	await animate_player1_exp(victory_total_xp)
	# Show the prompt, but NOT automatically advance
	victory_continue.text = "Press Y to Continue"
	victory_ready_to_continue = true

# Displays Player 2's victory results.
func show_player2_victory():
	victory_ready_to_continue = false

	victory_player_name.text = "PLAYER 2"
	victory_title.text = "VICTORY!"
	victory_continue.text = ""
	update_player2_victory_ui()
	await animate_player2_exp(victory_total_xp)
	victory_continue.text = "Press Y to Continue"
	victory_ready_to_continue = true


# Updates Player 1's stats and EXP progress
func update_player1_victory_ui():
	victory_level.text = "LEVEL " + str(PartyManager.player1_level)
	victory_exp_bar.min_value = 0
	victory_exp_bar.max_value = PartyManager.player1_next_level_xp
	victory_exp_bar.value = PartyManager.player1_xp
	victory_exp_label.text = (
		str(PartyManager.player1_xp)
		+ " / "
		+ str(PartyManager.player1_next_level_xp)
		+ " EXP"
	)
	victory_stats.text = (
		"MAX HP: " + str(PartyManager.get_player1_max_health())
		+ "\nSTRENGTH: " + str(PartyManager.get_player1_strength())
		+ "\nSPEED: " + str(PartyManager.get_player1_speed())
	)


# Updates Player 2's level, EXP bar, and stats 
func update_player2_victory_ui():
	victory_level.text = "LEVEL " + str(PartyManager.player2_level)
	victory_exp_bar.min_value = 0
	victory_exp_bar.max_value = PartyManager.player2_next_level_xp
	victory_exp_bar.value = PartyManager.player2_xp
	victory_exp_label.text = (
		str(PartyManager.player2_xp)
		+ " / "
		+ str(PartyManager.player2_next_level_xp)
		+ " EXP"
	)
	victory_stats.text = (
		"MAX HP: " + str(PartyManager.get_player2_max_health())
		+ "\nSTRENGTH: " + str(PartyManager.get_player2_strength())
		+ "\nSPEED: " + str(PartyManager.get_player2_speed())
	)


# Animates EXP one point at a time and updates stats on level-up
func animate_player1_exp(amount: int):
	victory_continue.text = ""
	for i in range(amount):
		# Award one EXP point
		PartyManager.give_player1_xp(1)
		# Update the progress bar and current stats
		update_player1_victory_ui()
		# Brief pause so the bar visibly fills
		await get_tree().create_timer(0.05).timeout

# Animates Player 2 gaining EXP one point at a time
func animate_player2_exp(amount: int):
	victory_continue.text = ""
	for i in range(amount):
		PartyManager.give_player2_xp(1)
		update_player2_victory_ui()
		await get_tree().create_timer(0.05).timeout


# Finishes victory after the Player confirms the final results
func finish_victory():
	# Mark the overworld enemy as defeated
	EncounterManager.mark_current_enemy_defeated()
	EncounterManager.overworld_return_position = \
		EncounterManager.current_overworld_enemy_position
	EncounterManager.has_return_position = true
	EncounterManager.return_to_overworld()
