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
	# Configura e Avvia il Timer per i passi
	step_timer.wait_time = STEP_DELAY
	
	# Connetti il segnale solo se non è già connesso
	if not step_timer.timeout.is_connected(_on_step_timer_timeout):
		step_timer.timeout.connect(_on_step_timer_timeout)
	
	step_timer.start() 
	# Primo passo immediato
	_on_step_timer_timeout() 


# Called every frame when this state is active.
func _process(_delta: float) -> void:
	# Transizione a Idle se la velocità è zero
	if player.velocity.x == 0:
		lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
		return
	
	# Transizione a JumpFall se non si è più a terra
	if not player.is_on_floor():
		lower_state_machine.set_current_state(lower_state_machine.get_node("JumpFallLower"))
		return


# Called when the state machine exits this state.
func _exit_state() -> void:
	# Ferma il timer e il suono quando si esce dallo stato Walk
	step_timer.stop()
	sfx_walk.stop()
	
	# Rimuovi la connessione al segnale (è buona norma)
	if step_timer.timeout.is_connected(_on_step_timer_timeout):
		step_timer.timeout.disconnect(_on_step_timer_timeout)

# -------------------- GESTIONE PITCH RANDOMICO AD OGNI PASSO --------------------
func _on_step_timer_timeout():
	# 🔊 Riproduce il suono di passo con Pitch Randomico
	sfx_walk.pitch_scale = randf_range(MIN_WALK_PITCH, MAX_WALK_PITCH)
	sfx_walk.play()
# ---------------------------------------------------------------------------------
