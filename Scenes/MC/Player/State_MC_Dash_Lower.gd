extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine

# Called when the state machine enters this state.
func _enter_state() -> void:
	lower_sprite.play("DashLower")


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	pass


# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
