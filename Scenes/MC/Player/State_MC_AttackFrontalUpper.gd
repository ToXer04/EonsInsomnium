extends StateMachineState

@onready var upper_sprite: AnimatedSprite2D = %UpperSprite

@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var player: CharacterBody2D = $"../../.."


@onready var sfx_attack: AudioStreamPlayer = $AttackSFX 


# Called when the state machine enters this state.
func _enter_state() -> void:
	player.is_attacking = true
	upper_sprite.play("AttackNormalUpper")
	sfx_attack.play()

	var hitbox = %HitboxTriggerFrontal
	var overlapping_bodies = hitbox.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body is Enemy:
			body.onHit(owner.damage)


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	if not upper_sprite.is_playing():
		var path = lower_state_machine.get_current_state().name.replace("Lower", "Upper")
		upper_state_machine.set_current_state(upper_state_machine.get_node(path))


# Called when the state machine exits this state.
func _exit_state() -> void:
	player.is_attacking = false
