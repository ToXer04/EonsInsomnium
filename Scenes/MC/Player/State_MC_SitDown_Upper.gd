extends StateMachineState

@onready var upper_sprite: AnimatedSprite2D = %UpperSprite

# Called when the state machine enters this state.
func _enter_state() -> void:
	upper_sprite.play("SavePointSitUpper")

# Called every frame when this state is active.
func _process(_delta: float) -> void:
	pass

# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
