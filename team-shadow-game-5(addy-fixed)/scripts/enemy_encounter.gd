extends CharacterBody2D

# Contains the rat's battle stats and battle scene
@export var enemy_data: Resource
# Identifies specfic overworld enemy beaten
@export var enemy_id: String = "rat_1"
@export var wander_distance: float = 30.0
@export var wander_speed: float = 32.0
@export var wander_wait_time: float = 2.5
# Controls how quickly the enemy returns
@export var return_speed: float = 35.0
# area that limits enemy wandering
@onready var wander_shape: CollisionShape2D = $WanderZone/CollisionShape2D
# Stores the enemy's original spawn position
var spawn_position: Vector2
# Prevents the enemy from starting the same encounter multiple times
var encounter_triggered := false
var is_wandering: bool = false
# Stores the direction the rat is currently moving
var wander_direction: Vector2 = Vector2.ZERO
# Tracks distance rat traveled during wander
var distance_traveled: float = 0.0
var wander_timer: float = 0.0
# Tracks whether the enemy is returning to its spawn
var is_returning: bool = false

# Runs enemies physics and controls wandering behavior
# it can wait, wander, or battle
func _physics_process(delta):
	if is_returning:
		return_to_spawn(delta)
		return
	if encounter_triggered:
		velocity = Vector2.ZERO
		return
	if is_wandering:
		wander(delta)
	else:
		wait_to_wander(delta)


# timer to move again after moving
func wait_to_wander(delta):
	velocity = Vector2.ZERO
	wander_timer += delta

	if wander_timer >= wander_wait_time:
		wander_timer = 0.0
		choose_wander_direction()


# Randomized 8 direction movement
func choose_wander_direction():
	var directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2(1, 1).normalized(),
		Vector2(-1, 1).normalized(),
		Vector2(1, -1).normalized(),
		Vector2(-1, -1).normalized()
	]
	wander_direction = directions.pick_random()
	distance_traveled = 0.0
	is_wandering = true


# Wanders until hitting a wall, boundary, or max distance
func wander(delta):
	velocity = wander_direction * wander_speed
	var previous_position = global_position
	var next_position = global_position + velocity * delta
	# Returns to spawn when reaching the WanderZone boundary
	if not is_inside_wander_zone(next_position):
		start_returning()
		return
	move_and_slide()

	# Returns to spawn when hitting a wall
	if get_slide_collision_count() > 0:
		start_returning()
		return
	distance_traveled += global_position.distance_to(previous_position)
	if distance_traveled >= wander_distance:
		stop_wandering()

	var movement_amount = global_position.distance_to(previous_position)
	distance_traveled += movement_amount
	if distance_traveled >= wander_distance:
		stop_wandering()


# Stops enemy and resets its wandering values so it can wait before moving again
func stop_wandering():
	velocity = Vector2.ZERO
	is_wandering = false
	distance_traveled = 0.0
	wander_timer = 0.0


# Switches the enemy from wandering to returning.
func start_returning():
	is_wandering = false
	is_returning = true
	velocity = Vector2.ZERO


# Detects when Player enters enemy area and starts battle
func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and not encounter_triggered:
		encounter_triggered = true
		start_encounter()


# Creates encounter, randomly chooses 1-3 enemies, saves info needed to return after battle to enemy
func start_encounter():
	var enemy_count = randi_range(1, 3)
	var enemies = []

	# rats EnemyData saved to the battle list for every enemy
	for i in range(enemy_count):
		enemies.append(enemy_data)

	# saves orignal overworld rat that started battle id
	EncounterManager.current_overworld_enemy_id = enemy_id
	# saves orignal overworld rats position
	EncounterManager.current_overworld_enemy_position = global_position
	# Remembers which overworld scene the encounter started in.
	EncounterManager.previous_overworld_scene = get_tree().current_scene.scene_file_path
	# If the Player loses, returns 15 pixels to the left of the rat
	EncounterManager.overworld_return_position = Vector2(
		global_position.x - 275,
		global_position.y
	)
	EncounterManager.has_return_position = true
	print("battle started, overworld ID: ", enemy_id,", # of enemies: ", enemy_count)
	# sends enemy list through SignalBus
	SignalBus.encounter_started.emit(enemies)


# Runs when the overworld enemy first loads,If the rat was already defeated its removed
# setup for later if adding saves or respawning enemies or timers
func _ready():
	# Remembers enemy's starting position
	spawn_position = global_position
	if EncounterManager.defeated_overworld_enemies.has(enemy_id):
		queue_free()



# Checks whether a position is inside enemy's wander zone
func is_inside_wander_zone(target_position: Vector2) -> bool:
	var rectangle = wander_shape.shape as RectangleShape2D
	if rectangle == null:
		return true
	# Converts  world position into the shape's coordinates
	var local_position = wander_shape.to_local(target_position)
	var half_size = rectangle.size / 2.0
	return (
		abs(local_position.x) <= half_size.x
		and abs(local_position.y) <= half_size.y
	)

# Moves the enemy back to its original spawn position
func return_to_spawn(delta):
	var direction = global_position.direction_to(spawn_position)
	velocity = direction * return_speed
	move_and_slide()
	if global_position.distance_to(spawn_position) <= 2.0:
		global_position = spawn_position
		velocity = Vector2.ZERO
		is_returning = false
		stop_wandering()
