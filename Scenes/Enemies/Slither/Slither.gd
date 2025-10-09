extends GroundEnemy
class_name Slither



func _ready() -> void:
	DEFAULT_STATE = "Idle"
	var start_state = state_machine.get_node(DEFAULT_STATE)
	if start_state:
		state_machine.set_current_state(start_state)
	


func _physics_process(delta: float) -> void:
	super._physics_process(delta)


func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
