extends StateMachineState
@onready var state_machine: StateMachine = $".."
@onready var sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"


# Called when the state machine enters this state.
func _enter_state() -> void:
	sprite.play("Death")


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	pass


# Called when the state machine exits this state.
func _exit_state() -> void:
	pass


func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.
