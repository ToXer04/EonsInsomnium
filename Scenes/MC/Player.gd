extends CharacterBody2D

@onready var state_machine: StateMachine = %StateMachine
@onready var visuals: Node2D = %Visuals
@onready var camera: Camera2D = $Camera2D

const DEFAULT_STATE = "Idle"

# Variables
var health: int = 3
var damage: int  = 1

# Movement
const SPEED = 400.0
const ACCEL = .35
const DECEL = .35
const VELOCITY_DEADZONE = 10.0

# Jump
const JUMP_INITIAL = -750.0
const JUMP_HOLD_FORCE = -2000.0
const MAX_JUMP_HOLD_TIME = 0.4
var jump_holding: bool = false
var jump_time: float = 0.0

# Dash
const DASH_SPEED = 2000.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5
var dashing: bool = false
var dash_time: float = 0.0
var dash_direction: int = 0
var dash_cooldown_timer: float = 0.0
var can_dash: bool = true

# WallClimb
const WALL_SLIDE_SPEED = 100.0
const WALL_JUMP_FORCE = Vector2(4000, -1000) # forza wall jump (orizzontale, verticale)
var wall_climbing: bool = false
var wall_dir: int = 0

func _ready() -> void:
	Singleton.player = self
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
	else:
		camera.enabled = false
	var start_state = state_machine.get_node(DEFAULT_STATE)
	if start_state:
		state_machine.set_current_state(start_state)
		
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	# cooldown dash
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer < 0.0:
			dash_cooldown_timer = 0.0

	# reset dash quando tocchi terra
	if is_on_floor():
		can_dash = true

	# gestione dash
	if dashing:
		velocity.y = 0
		velocity.x = dash_direction * DASH_SPEED
		dash_time += delta

		if dash_time >= DASH_DURATION:
			dashing = false
			state_machine.set_current_state(state_machine.get_node("Idle"))
	else:
		# wall climb check
		var direction := Input.get_axis("Move_Left", "Move_Right")

		if not is_on_floor() and is_on_wall() and velocity.y > 0 and direction != 0:
			var wall_normal = get_wall_normal()
			wall_dir = -sign(wall_normal.x) # direzione del muro
			if direction == wall_dir:
				if not wall_climbing:
					state_machine.set_current_state(state_machine.get_node("WallClimb"))
					wall_climbing = true
					can_dash = true # rigenera dash
				# rallenta caduta
				velocity.y = WALL_SLIDE_SPEED
		else:
			wall_climbing = false

		# Gravità
		if not is_on_floor() and not wall_climbing:
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

		# Movimento orizzontale
		if direction:
			velocity.x = lerp(velocity.x, direction * SPEED, ACCEL)
			visuals.scale.x = direction
		else:
			velocity.x = lerp(velocity.x, 0.0, DECEL)

		if abs(velocity.x) < VELOCITY_DEADZONE:
			velocity.x = 0

	# caduta
	if velocity.y > 0 and not wall_climbing:
		state_machine.set_current_state(state_machine.get_node("JumpFall"))

	move_and_slide()


func _input(event):
	if not is_multiplayer_authority():
		return
	# Jump
	if event.is_action_pressed("Jump") and not dashing:
		if is_on_floor():
			# salto normale
			state_machine.set_current_state(state_machine.get_node("JumpStart"))
			velocity.y = JUMP_INITIAL
			jump_holding = true
			jump_time = 0.0
		elif wall_climbing:
			# wall jump
			state_machine.set_current_state(state_machine.get_node("JumpStart"))
			velocity = Vector2(-wall_dir * WALL_JUMP_FORCE.x, WALL_JUMP_FORCE.y)
			visuals.scale.x = -wall_dir # guarda dalla parte opposta al muro
			wall_climbing = false
			can_dash = true # rigenera dash
			jump_holding = false

	if event.is_action_released("Jump"):
		jump_holding = false
		if velocity.y < 0:
			velocity.y *= 0.4

	# Attack
	if event.is_action_pressed("Click") and not dashing:
		state_machine.set_current_state(state_machine.get_node("AttackFrontal"))

	# Dash (non in wall climb)
	if event.is_action_pressed("Dash") and not dashing and can_dash and dash_cooldown_timer <= 0.0 and not wall_climbing:
		dashing = true
		dash_time = 0.0
		dash_direction = sign(visuals.scale.x) if visuals.scale.x != 0 else 1
		state_machine.set_current_state(state_machine.get_node("Dash"))
		
		if not is_on_floor():
			can_dash = false
		dash_cooldown_timer = DASH_COOLDOWN

func _on_hurt_box_trigger_body_entered(body: Node2D) -> void:
	if body is Enemy:
		takeDamage(body.damage)
		if health <= 0:
			death()
		print(health)

func takeDamage(damageTaken: int):
	health -= damageTaken

func death():
	print("Dead!")
	get_tree().reload_current_scene()
