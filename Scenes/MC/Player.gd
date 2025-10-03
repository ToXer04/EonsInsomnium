extends CharacterBody2D

@onready var state_machine: StateMachine = %StateMachine
@onready var visuals: Node2D = %Visuals

const DEFAULT_STATE = "Idle"

const SPEED = 400.0
const ACCEL = 0.15
const DECEL = 0.1
const VELOCITY_DEADZONE = 5.0   # soglia di tolleranza


# Jump const
const JUMP_INITIAL = -750.0
const JUMP_HOLD_FORCE = -2000.0
const MAX_JUMP_HOLD_TIME = 0.4

# Jump var
var jump_holding: bool = false
var jump_time: float = 0.0

# Dash const
const DASH_SPEED = 2000.0
const DASH_DURATION = 0.2  # in secondi

# Dash var
var dashing: bool = false
var dash_time: float = 0.0
var dash_direction: int = 0

func _ready() -> void:
	var start_state = state_machine.get_node(DEFAULT_STATE)
	if start_state:
		state_machine.set_current_state(start_state)

func _physics_process(delta: float) -> void:
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
			# accelerazione verso la direzione scelta
			velocity.x = lerp(velocity.x, direction * SPEED, ACCEL)
			visuals.scale.x = direction
		else:
			# decelerazione graduale verso 0
			velocity.x = lerp(velocity.x, 0.0, DECEL)

		# correzione: se la velocità è minuscola, forziamo a zero
		if abs(velocity.x) < VELOCITY_DEADZONE:
			velocity.x = 0
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
	if event.is_action_pressed("Dash") and not dashing:
		dashing = true
		dash_time = 0.0
		dash_direction = sign(visuals.scale.x) if visuals.scale.x != 0 else 1
		state_machine.set_current_state(state_machine.get_node("Dash"))
