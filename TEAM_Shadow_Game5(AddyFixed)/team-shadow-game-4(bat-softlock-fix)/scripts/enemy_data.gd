extends Resource
class_name EnemyData

# grabs data from resource data
@export var name : String =  "Monster"
@export var texture : Texture2D
@export var health : int 
@export var damage : int
@export var battle_scene: PackedScene
@export var min_exp: int 
@export var max_exp: int
@export var speed: int = 10 

# Determines whether enemy flies and how many pixels high
@export var is_flying: bool = false
@export var flying_height: float = 40.0

func get_exp_reward() -> int:
	return randi_range(min_exp, max_exp) 
