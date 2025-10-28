extends FlyingEnemy
class_name Cinder

func _ready() -> void:
	var start_state = state_machine.get_node(DEFAULT_STATE)
	if start_state:
		state_machine.set_current_state(start_state)

func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
