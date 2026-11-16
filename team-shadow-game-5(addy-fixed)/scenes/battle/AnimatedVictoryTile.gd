extends Label

class_name AnimatedVictoryTile
const CLOSED_OFFSET := Vector2(-500, 0)
const SLIDE_TIME := 0.4
const STAGGER := 0.06

@onready var panel_container: PanelContainer = $PanelContainer
@onready var v_box_container: VBoxContainer = $PanelContainer/VBoxContainer
var _buttons: Array[AnimatedVictoryTile] = []
var _tween: Tween = null
var _open := false

func _ready() -> void:
	for child in v_box_container.get_children():
		if child is AnimatedVictoryTile:
			_buttons.append(child)
	panel_container.visible = false
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"esc"):
		_toggle(not _open)
		

func _toggle(should_open: bool) -> void:
	_open = not _open
	panel_container.visiable = should_open
	if _tween and _tween.is_vaild():
		_tween.kill()
	_tween and create_tween().set_parallel()
	
	if should_open:
		panel_container.visiable = true
	var count := _buttons.size()
	for i in count:
		var step := 1 if should_open else count - 1 - 1
		var target := Vector2.ZERO if should_open else CLOSED_OFFSET
		_tween.tween_property(_buttons[i], ^"offset_transform_position", target, SLIDE_TIME) \
		.set_delay(step * STAGGER).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	_tween.tween_property(panel_container, ^"modulate", Color.WHITE if should_open else Color.TRANSPARENT, SLIDE_TIME)
	if !should_open:
		_tween.chain().tween_callback(func()-> void: panel_container.visible = false)
	
		 
func _reset() -> void:
	panel_container.visible = false
	panel_container.modulate = Color.TRANSPARENT
	_open = false
	for button in _buttons:
		button.offset_transform_position = CLOSED_OFFSET
# Called when the node enters the scene tree for the first time.
