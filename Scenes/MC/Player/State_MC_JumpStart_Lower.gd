extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."

func _enter_state() -> void:
	lower_sprite.play("JumpStartLower")
	SoundManager.play_sfx(SoundManager.SFX_JUMPSTART)

	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("JumpStartUpper"))

func _process(_delta: float) -> void:
	if not lower_sprite.is_playing():
		lower_state_machine.set_current_state(lower_state_machine.get_node("JumpRiseLower"))

func _exit_state() -> void:
	pass
