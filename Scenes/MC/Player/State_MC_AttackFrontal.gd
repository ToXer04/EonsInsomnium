extends StateMachineState

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var state_machine: StateMachine = %StateMachine

# 🔊 Riferimento al nodo audio (deve essere figlio di questo stato)
@onready var sfx_attack: AudioStreamPlayer = $AttackSFX 


# Called when the state machine enters this state.
func _enter_state() -> void:
	# 1. Avvia l'audio
	sfx_attack.play()
	
	# 2. Avvia l'animazione
	sprite.play("AttackFrontal")

	var hitbox = %HitboxTriggerFrontal
	var overlapping_bodies = hitbox.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body is Enemy:
			# Assumiamo che 'owner' sia il Player per accedere al danno
			body.onHit(owner.damage)


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	# La condizione "not sprite.is_playing()" è buona, ma a volte l'animazione finisce
	# prima che tu voglia uscire. Assicurati che non ci siano cicli vuoti.
	if not sprite.is_playing():
		state_machine.set_current_state(state_machine.get_node("Idle"))


# Called when the state machine exits this state.
func _exit_state() -> void:
	pass
