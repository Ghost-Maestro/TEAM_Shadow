extends Node
# enemies are stored that will appear in battle
var current_enemies: Array = []
# Used to return player to overworld after loosing
var overworld_return_position: Vector2 = Vector2.ZERO
var has_return_position: bool = false
var current_overworld_enemy_id: String = ""
var current_overworld_enemy_position: Vector2 = Vector2.ZERO
# stored defeated enemies data to stop them from respawning unless otherwise
var defeated_overworld_enemies: Array[String] = []
# Stores the scene the Player was in before entering battle.
var previous_overworld_scene: String = ""

func _ready():
	SignalBus.encounter_started.connect(_on_encounter_started)


# Runs when SignalBus announces that an encounter started
func _on_encounter_started(enemies):
	current_enemies = enemies
	print("Encounter Manager received, enemy count: ", current_enemies.size())
	# Changes to the battle scene 
	get_tree().call_deferred(
		"change_scene_to_file",
		"res://scenes/battle/battle.tscn"
	)


# overworld enemy that started battle has its ID saved to prevent reappearing 
# will not appear when the overworld reloads, unless otherwise
func mark_current_enemy_defeated():
	if current_overworld_enemy_id != "":
		# Makes sure the same enemy is not added twice.
		if not defeated_overworld_enemies.has(current_overworld_enemy_id):
			defeated_overworld_enemies.append(current_overworld_enemy_id)
			print(
				"Overworld enemy defeated: ",
				current_overworld_enemy_id
			)

# Returns the Player to the overworld scene where the battle started.
func return_to_overworld():
	if previous_overworld_scene == "":
		push_error("No previous overworld scene was saved!")
		return

	get_tree().call_deferred(
		"change_scene_to_file",
		previous_overworld_scene
	)
