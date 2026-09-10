extends Node2D


@onready var _y_button = $y_button
@onready var _b_button = $b_button
@onready var _a_button = $a_button
@onready var _x_button = $x_button




func _ready() -> void:
	_y_button.play("Normal")
	_b_button.play("Normal")
	_a_button.play("Normal")
	_x_button.play("Normal")

# Simple Button Code
func _input(event):
	if event.is_action_pressed("y_button"):
		_y_button.play("Pressed")
		print("Thre-Shi Jump")
	
	if event.is_action_pressed("b_button"):
		_b_button.play("Pressed")
		print("Add-E-Quint Jump")
	
	if event.is_action_pressed("a_button"):
		_a_button.play("Pressed")
		print("Ex-El Jump")
	
	
	if event.is_action_pressed("x_button"):
		_x_button.play("Pressed")
	
	
	if event.is_action_released("y_button"):
		_y_button.play("Normal")
	
	
	if event.is_action_released("b_button"):
		_b_button.play("Normal")
	
	
	if event.is_action_released("a_button"):
		_a_button.play("Normal")
	
	
	if event.is_action_released("x_button"):
		_x_button.play("Normal")
