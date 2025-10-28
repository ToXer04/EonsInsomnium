extends StateMachineState

@onready var sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var state_machine: StateMachine = $".."


func _enter_state() -> void:
	sprite.play("Idle")


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	if $"../..".velocity != Vector2(0, 0):
		state_machine.set_current_state(state_machine.get_node("Walk"))


# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
