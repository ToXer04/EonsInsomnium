extends StateMachineState

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var state_machine: StateMachine = %StateMachine

# Called when the state machine enters this state.
func _enter_state() -> void:
	sprite.play("JumpTransition")


# Called every frame when this state is active.
func _process(delta: float) -> void:
	if not sprite.is_playing():
		state_machine.set_current_state($"../JumpFall")


# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
