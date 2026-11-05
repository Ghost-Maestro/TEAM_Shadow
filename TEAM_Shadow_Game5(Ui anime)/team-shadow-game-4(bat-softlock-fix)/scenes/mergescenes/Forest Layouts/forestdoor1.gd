extends Area2D

var entered = false

func _on_body_entered(_body: CharacterBody2D):
	entered = true

func _on_body_exited(_body: CharacterBody2D):
	entered = false

func _physics_process(_delta):
	if entered == true:
		entered = false
		SceneTransition.change_scene("res://Scenes/mergescenes/Forest Layouts/forest_2.tscn")
