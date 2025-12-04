extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."

# Called when the state machine enters this state.
func _enter_state() -> void:
	lower_sprite.play("SitOnLower")
	player.stop = true
	SoundManager.play_sfx_pitch(SoundManager.SFX_SITON, 0.9, 1.1)
	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("SitOnUpper"))

# Called every frame when this state is active.
func _process(_delta: float) -> void:
	if not lower_sprite.is_playing():
		lower_state_machine.set_current_state(lower_state_machine.get_node("SitIdleLower"))

# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
