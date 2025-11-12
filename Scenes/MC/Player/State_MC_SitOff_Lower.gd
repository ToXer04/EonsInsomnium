extends StateMachineState

@onready var lower_sprite: AnimatedSprite2D = %LowerSprite
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var player: CharacterBody2D = $"../../.."

# Called when the state machine enters this state.
func _enter_state() -> void:
	lower_sprite.play("SavePointOffLower")
	if not player.is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("SitOffUpper"))

# Called every frame when this state is active.
func _process(_delta: float) -> void:
	if not lower_sprite.is_playing(): # animazione finita
		lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))

# Called when the state machine exits this state.
func _exit_state() -> void:
	player.sit = false
