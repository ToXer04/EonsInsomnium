extends CharacterBody2D

@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var visuals: Node2D = %Visuals
@onready var camera: Camera2D = $Camera2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var coin_counter: Label = $Camera2D/CoinCounter
@onready var health_ui_empty: TextureRect = $Camera2D/HealthUIEmpty
@onready var health_ui_full: TextureRect = $Camera2D/HealthUIFull


# Variabili Globali (Logica di movimento/audio rimossa)
const DEFAULT_STATE = "Idle"

# Variables
var health: int = 5
var max_health: int = 5
var damage: int  = 1
var coins: int = 0






# Interaction
var moving_to_target: bool = false
var target_position: Vector2
var target_reached_callback: Callable = Callable()
var target_speed: float = 300.0
var sit: bool = false

var dialogue_active: bool = false

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

# Attack
var is_attacking: bool = false

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
const WALL_JUMP_FORCE = Vector2(4000, -1000)
var wall_climbing: bool = false
var wall_dir: int = 0

var assigned_authority : int = -1

func _on_ready():
	set_multiplayer_authority(assigned_authority)

func _ready() -> void:
	self.ready.connect(_on_ready)
	if not is_multiplayer_authority():
		return
	var id_str = name
	
	coin_counter.text = str(coins)
	
	id_str = id_str.replace("Player", "").replace("Eon", "").replace("Lyra", "")
	#set_multiplayer_authority(id_str.to_int())
	Singleton.player = self
	
	
	change_healthUI()
	
	
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
	else:
		camera.enabled = false
	var start_state_lower = lower_state_machine.get_node(DEFAULT_STATE + "Lower")
	if start_state_lower:
		lower_state_machine.set_current_state(start_state_lower)
	var start_state_upper = upper_state_machine.get_node(DEFAULT_STATE + "Upper")
	if start_state_upper:
		upper_state_machine.set_current_state(start_state_upper)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if moving_to_target:
		move_toward_target(delta)
		return

	if sit:
		return
		
		
	if dialogue_active:
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
			lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
			upper_state_machine.set_current_state(upper_state_machine.get_node("IdleUpper"))
	else:
		# wall climb check
		var direction := Input.get_axis("Move_Left", "Move_Right")

		if not is_on_floor() and is_on_wall() and velocity.y > 0 and direction != 0:
			var wall_normal = get_wall_normal()
			wall_dir = -sign(wall_normal.x)
			if direction == wall_dir:
				if not wall_climbing:
					lower_state_machine.set_current_state(lower_state_machine.get_node("WallClimbLower"))
					upper_state_machine.set_current_state(upper_state_machine.get_node("WallClimbUpper"))
					wall_climbing = true
					can_dash = true
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
		if direction != 0:
			velocity.x = lerp(velocity.x, direction * SPEED, ACCEL)
			visuals.scale.x = direction
		else:
			velocity.x = lerp(velocity.x, 0.0, DECEL)
		
		# Deadzone Check
		if abs(velocity.x) < VELOCITY_DEADZONE:
			velocity.x = 0
			
		if is_on_floor() and abs(velocity.x) > VELOCITY_DEADZONE and lower_state_machine.get_current_state().name != "WalkLower":
			lower_state_machine.set_current_state(lower_state_machine.get_node("WalkLower"))
		elif is_on_floor() and abs(velocity.x) < VELOCITY_DEADZONE and lower_state_machine.get_current_state().name == "WalkLower":
			lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
		# -----------------------------------------------------


	move_and_slide()


func _input(event):
	if not is_multiplayer_authority():
		return

	# Jump
	if event.is_action_pressed("Jump") and not dashing and not sit:
		if is_on_floor():
			lower_state_machine.set_current_state(lower_state_machine.get_node("JumpStartLower"))
			# sfx_jump_start.play() <--- Rimosso
			velocity.y = JUMP_INITIAL
			jump_holding = true
			jump_time = 0.0
			# sfx_walk.stop() rimosso (gestito dalla State Machine uscendo dallo stato Walk)
		elif wall_climbing:
			lower_state_machine.set_current_state(lower_state_machine.get_node("JumpStartLower"))
			# sfx_jump_start.play() <--- Rimosso
			velocity = Vector2(-wall_dir * WALL_JUMP_FORCE.x, WALL_JUMP_FORCE.y)
			visuals.scale.x = -wall_dir
			wall_climbing = false
			can_dash = true
			jump_holding = false

	if event.is_action_released("Jump"):
		jump_holding = false
		if velocity.y < 0:
			velocity.y *= 0.4

	# Attack
	if event.is_action_pressed("Click") and not dashing and not sit and not is_attacking:
		upper_state_machine.set_current_state(upper_state_machine.get_node("AttackFrontalUpper"))

	# Dash
	if event.is_action_pressed("Dash") and not dashing and can_dash and dash_cooldown_timer <= 0.0 and not wall_climbing and not sit:
		dashing = true
		dash_time = 0.0
		dash_direction = sign(visuals.scale.x) if visuals.scale.x != 0 else 1
		lower_state_machine.set_current_state(lower_state_machine.get_node("DashLower"))
		# sfx_dash.play() <--- Rimosso
		# step_timer.stop() rimosso (gestito dalla State Machine uscendo dallo stato Walk)

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
	change_healthUI()



func death():
	print("Dead!")
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()


func move_toward_target(delta: float) -> void:
	if navigation_agent_2d.is_navigation_finished():
		lower_state_machine.set_current_state(lower_state_machine.get_node("SitDownLower"))
		moving_to_target = false
		velocity = Vector2.ZERO
		if target_reached_callback.is_valid():
			target_reached_callback.call()
		return
	var next_path_point = navigation_agent_2d.get_next_path_position()
	var dir = (next_path_point - global_position).normalized()
	velocity = dir * target_speed
	move_and_slide()


func move_to_target(pos: Vector2, callback: Callable = Callable()):
	if not is_on_floor():
		await get_tree().create_timer(0.05).timeout
		while not is_on_floor():
			await get_tree().process_frame
	dashing = false
	moving_to_target = true
	target_position = pos
	target_reached_callback = callback
	navigation_agent_2d.target_position = pos
	var dir = target_position.x - global_position.x
	if dir != 0: visuals.scale.x = sign(dir)

@onready var sfx_walk: AudioStreamPlayer = %WalkSFX 


func _on_lower_sprite_frame_changed() -> void:
	match (%LowerSprite.animation):
		"IdleLower": 
			return
		"WalkLower":
			match (%LowerSprite.frame):
				1: 
					sfx_walk.play()
				10: 
					sfx_walk.play()




func change_healthUI():
	health_ui_empty.size.x = max_health * 61
	if health <= max_health:
		health_ui_full.size.x = health * 61
