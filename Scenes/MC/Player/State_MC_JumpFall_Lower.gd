extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var player = $"../../.."
	
# Called when the state machine enters this state.
func _enter_state() -> void:
	lower_sprite.play("JumpFallLower")


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	if player.is_on_floor():
		lower_state_machine.set_current_state(lower_state_machine.get_node("JumpLandLower"))


# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
