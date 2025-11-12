extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."
@onready var sfx_walk: AudioStreamPlayer = $WalkSFX 
@onready var step_timer: Timer = $StepTimer 

# Costanti Pitch
const MIN_WALK_PITCH: float = 0.95  
const MAX_WALK_PITCH: float = 1.05  
const STEP_DELAY: float = 0.7 

# Called when the state machine enters this state.
func _enter_state() -> void:
	lower_sprite.play("WalkLower")
	
	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("WalkUpper"))
		
	step_timer.wait_time = STEP_DELAY
	if not step_timer.timeout.is_connected(_on_step_timer_timeout):
		step_timer.timeout.connect(_on_step_timer_timeout)
	
	step_timer.start() 
	_on_step_timer_timeout() 

# Called every frame when this state is active.
func _process(_delta: float) -> void:
	if player.velocity.x == 0:
		lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
		return
	
	if not player.is_on_floor():
		lower_state_machine.set_current_state(lower_state_machine.get_node("JumpFallLower"))
		return

# Called when the state machine exits this state.
func _exit_state() -> void:
	step_timer.stop()
	
	if step_timer.timeout.is_connected(_on_step_timer_timeout):
		step_timer.timeout.disconnect(_on_step_timer_timeout)

func _on_step_timer_timeout():
	return
	sfx_walk.pitch_scale = randf_range(MIN_WALK_PITCH, MAX_WALK_PITCH)
	sfx_walk.play()
