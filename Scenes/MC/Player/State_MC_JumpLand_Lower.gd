extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."

func _enter_state() -> void:
	lower_sprite.play("JumpLandLower")
	SoundManager.play_sfx(SoundManager.SFX_JUMPLAND)

	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("JumpLandUpper"))

func _process(_delta: float) -> void:
	if not lower_sprite.is_playing():
		if player.velocity.x == 0:
			lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
		else:
			lower_state_machine.set_current_state(lower_state_machine.get_node("WalkLower"))

func _exit_state() -> void:
	pass
