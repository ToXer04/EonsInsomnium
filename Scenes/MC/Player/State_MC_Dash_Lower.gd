extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."

func _enter_state() -> void:
	lower_sprite.play("DashLower")
	SoundManager.play_sfx(SoundManager.SFX_DASH)

	# Stop walk timer to prevent step sound in air
	var walk_state = player.get_node("WalkLowerState") 
	if walk_state:
		walk_state.step_timer.stop()

	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("DashUpper"))

func _process(_delta: float) -> void:
	pass

func _exit_state() -> void:
	pass
