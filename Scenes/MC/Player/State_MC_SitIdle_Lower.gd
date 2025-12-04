extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."

# Called when the state machine enters this state.
func _enter_state() -> void:
	lower_sprite.play("SitIdleLower")
	SoundManager.play_sitidle_sfx()
	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("SitIdleUpper"))

# Called every frame when this state is active.
func _process(_delta: float) -> void:
	pass

# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
	SoundManager.stop_sitidle_sfx()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		lower_state_machine.set_current_state(lower_state_machine.get_node("SitOffLower"))
