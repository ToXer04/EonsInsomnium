extends StateMachineState

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var state_machine: StateMachine = %StateMachine

# Called when the state machine enters this state.
func _enter_state() -> void:
	sprite.play("SavePointIdle")


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	pass


# Called when the state machine exits this state.
func _exit_state() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		state_machine.set_current_state(state_machine.get_node("SitOff"))
