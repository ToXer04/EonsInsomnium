extends CharacterBody2D

@onready var state_machine: StateMachine = %StateMachine
@onready var visuals: Node2D = %Visuals

const DEFAULT_STATE = "Idle"

# Move const
const SPEED = 400.0
const ACCEL = .35
const DECEL = .35
const VELOCITY_DEADZONE = 10.0

# Jump const
const JUMP_INITIAL = -750.0
const JUMP_HOLD_FORCE = -2000.0
const MAX_JUMP_HOLD_TIME = 0.4

# Jump var
var jump_holding: bool = false
var jump_time: float = 0.0

# Dash const
const DASH_SPEED = 2000.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5

# Dash var
var dashing: bool = false
var dash_time: float = 0.0
var dash_direction: int = 0
var dash_cooldown_timer: float = 0.0
var can_dash: bool = true

func _ready() -> void:
	var start_state = state_machine.get_node(DEFAULT_STATE)
	if start_state:
		state_machine.set_current_state(start_state)

func _physics_process(delta: float) -> void:
	# gestiamo cooldown dash
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer < 0.0:
			dash_cooldown_timer = 0.0

	# reset dash quando tocchi il terreno
	if is_on_floor():
		can_dash = true

	if dashing:
		# Durante la dash niente gravità, niente verticale
		velocity.y = 0
		velocity.x = dash_direction * DASH_SPEED
		dash_time += delta

		if dash_time >= DASH_DURATION:
			dashing = false
			state_machine.set_current_state(state_machine.get_node("Idle"))
	else:
		# Gravità
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Hold jump
		if jump_holding and jump_time < MAX_JUMP_HOLD_TIME:
			var t = jump_time / MAX_JUMP_HOLD_TIME
			var extra_force = (JUMP_HOLD_FORCE * (1.0 - t)) * delta
			velocity.y += extra_force
			jump_time += delta
			if jump_time >= MAX_JUMP_HOLD_TIME:
				jump_holding = false
				if velocity.y < 0:
					velocity.y *= 0.4

		# Movimento orizzontale (solo se non in dash)
		var direction := Input.get_axis("Move_Left", "Move_Right")
		if direction:
			velocity.x = lerp(velocity.x, direction * SPEED, ACCEL)
			visuals.scale.x = direction
		else:
			velocity.x = lerp(velocity.x, 0.0, DECEL)

		# correzione: se la velocità è minuscola, forziamo a zero
		if abs(velocity.x) < VELOCITY_DEADZONE:
			velocity.x = 0

	# Cambia stato in caduta se stai scendendo
	if velocity.y > 0:
		state_machine.set_current_state(state_machine.get_node("JumpFall"))

	move_and_slide()


func _input(event):
	# Jump
	if event.is_action_pressed("Jump") and is_on_floor() and not dashing:
		state_machine.set_current_state(state_machine.get_node("JumpStart"))
		velocity.y = JUMP_INITIAL
		jump_holding = true
		jump_time = 0.0

	if event.is_action_released("Jump"):
		jump_holding = false
		if velocity.y < 0:
			velocity.y *= 0.4

	# Attack
	if event.is_action_pressed("Click") and not dashing:
		state_machine.set_current_state(state_machine.get_node("AttackFrontal"))

	# Dash
	if event.is_action_pressed("Dash") and not dashing and can_dash and dash_cooldown_timer <= 0.0:
		dashing = true
		dash_time = 0.0
		dash_direction = sign(visuals.scale.x) if visuals.scale.x != 0 else 1
		state_machine.set_current_state(state_machine.get_node("Dash"))
		
		# consumo dash se in aria
		if not is_on_floor():
			can_dash = false
		
		# parte il cooldown
		dash_cooldown_timer = DASH_COOLDOWN
