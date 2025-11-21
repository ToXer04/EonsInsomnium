extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."
@onready var step_timer: Timer = $StepTimer

const STEP_DELAY: float = 0.5  # Adjust based on walk animation speed

func _enter_state() -> void:
	lower_sprite.play("WalkLower")
	
	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("WalkUpper"))

	# Start step timer only if moving and on floor
	if player.velocity.x != 0 and player.is_on_floor():
		step_timer.start(STEP_DELAY)

func _process(_delta: float) -> void:
	if player.velocity.x == 0:
		lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
		step_timer.stop()
		return
	
	if not player.is_on_floor():
		lower_state_machine.set_current_state(lower_state_machine.get_node("JumpFallLower"))
		step_timer.stop()
		return

# Called when the step timer times out
func _on_step_timer_timeout() -> void:
	if player.velocity.x != 0 and player.is_on_floor():
		SoundManager.play_sfx(SoundManager.SFX_STEP)
		step_timer.start(STEP_DELAY)

func _exit_state() -> void:
	step_timer.stop()
