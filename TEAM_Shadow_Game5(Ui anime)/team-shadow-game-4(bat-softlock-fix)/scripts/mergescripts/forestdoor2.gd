extends Area2D

var entered = false

func _on_body_entered(_body: Node2D) -> void:
	entered = true 

func _on_body_exited(_body: Node2D) -> void:
	entered = false
	

func _physics_process(_delta):
	if entered == true:
		get_tree().change_scene_to_file("res://Scenes/Forest Layouts/forest_3.tscn")
