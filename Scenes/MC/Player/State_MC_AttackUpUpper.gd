extends StateMachineState

@onready var upper_sprite: AnimatedSprite2D = %UpperSprite
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var player: CharacterBody2D = $"../../.."

func _enter_state() -> void:
	player.is_attacking = true
	upper_sprite.play("AttackUpUpper")
	SoundManager.play_sfx(SoundManager.SFX_ATTACK)

	# Do not stop walk timer → steps continue during attack

	var hitbox = %HitboxTriggerUp
	var overlapping_bodies = hitbox.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body is Enemy:
			body.onHit(owner.damage)

func _process(_delta: float) -> void:
	if not upper_sprite.is_playing():
		var path = lower_state_machine.get_current_state().name.replace("Lower", "Upper")
		upper_state_machine.set_current_state(upper_state_machine.get_node(path))

func _exit_state() -> void:
	player.is_attacking = false
