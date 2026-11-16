extends CanvasLayer

# Black overlay used for the fade effect
@onready var fade_rect: ColorRect = $ColorRect
@export var fade_duration: float = 0.5
var is_transitioning: bool = false

# Changes scenes with a fade to black and back
func change_scene(scene_path: String):
	if is_transitioning:
		return
	is_transitioning = true

	# Fade the current scene to black
	var fade_out = create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await fade_out.finished

	# Switch scenes while the screen is black
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("Could not load scene: " + scene_path)
		var failed_fade = create_tween()
		failed_fade.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
		await failed_fade.finished
		is_transitioning = false
		return

	# Wait for the new scene to finish entering the tree
	await get_tree().process_frame
	# Fade back in to reveal the new scene
	var fade_in = create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	await fade_in.finished
	is_transitioning = false
