extends CharacterBody2D
class_name Player

@onready var black_screen: CanvasLayer = $BlackScreen

@onready var lower_state_machine: StateMachine = %LowerStateMachine
@onready var upper_state_machine: StateMachine = %UpperStateMachine
@onready var visuals: Node2D = %Visuals
@onready var camera: Camera2D = $Camera2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

@onready var health_ui_empty: Texture2D = preload("uid://cwmtd77hrm1np")
@onready var health_ui_full: Texture2D = preload("uid://bhrel2w1cvq3o")

@onready var hud: CanvasLayer = $Hud

# --- CAMERA LIMIT SYSTEM ---
var base_limits := {}          
var limit_left_stack: Array = []
var limit_right_stack: Array = []
var limit_top_stack: Array = []
var limit_bottom_stack: Array = []

var can_change := true

var camera_lerp_timer := 0.0 
var camera_lerp_duration := 0.6


var start_limit_left: float
var start_limit_right: float
var start_limit_top: float
var start_limit_bottom: float


var current_limit_left: float
var current_limit_right: float
var current_limit_top: float
var current_limit_bottom: float

var target_limit_left: float
var target_limit_right: float
var target_limit_top: float
var target_limit_bottom: float

const CAMERA_LERP_SPEED: float = 100.0  
const offset := 120   


# ----------------------------

# Variables
var health: int = 5
var max_health: int = 5
var damage: int  = 1
var flasks: int = 0

var moving_to_target: bool = false
var target_position: Vector2
var target_reached_callback: Callable = Callable()
var target_speed: float = 300.0
var stop: bool = false

var dialogue_active: bool = false

#Management
var spawning := false

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
var AttackTrailScene: PackedScene = preload("res://Scenes/MC/Player/AttackTrail.tscn")
var is_attacking: bool = false

# Dash
var DashTrailScene: PackedScene = preload("res://Scenes/MC/Player/DashTrail.tscn")
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


func _ready() -> void:
	set_multiplayer_authority(name.to_int())
	Singleton.player = self
	SoundManager.play_gameplay_music()
	if is_multiplayer_authority():
		print("Last save point: " + str(SaveManager.last_spawn_point))
		flasks = SaveManager.flasks
		WriteFlasks()
		if SaveManager.last_spawn_point != 0:
			var gm = $"../.."
			var pos = gm.get_spawn_position(SaveManager.last_spawn_point)
			global_position = pos
			sit()
		else:
			var start_state_lower = lower_state_machine.get_node("IdleLower")
			lower_state_machine.set_current_state(start_state_lower)
			var start_state_upper = upper_state_machine.get_node("IdleUpper")
			upper_state_machine.set_current_state(start_state_upper)
		camera.enabled = true
		camera.make_current() 
	else:
		camera.enabled = false
	Health_ui()


# ------ CAMERA LIMIT SYSTEM ------

func apply_camera_limits():
	camera_lerp_timer = 0.0
	
	
	start_limit_left = camera.limit_left
	start_limit_right = camera.limit_right
	start_limit_top = camera.limit_top
	start_limit_bottom = camera.limit_bottom

	target_limit_left   = limit_left_stack.back()   if limit_left_stack.size() > 0 else base_limits.left
	target_limit_right  = limit_right_stack.back()  if limit_right_stack.size() > 0 else base_limits.right
	target_limit_top    = limit_top_stack.back()    if limit_top_stack.size() > 0 else base_limits.top
	target_limit_bottom = limit_bottom_stack.back() if limit_bottom_stack.size() > 0 else base_limits.bottom


func _on_hurtbox_trigger_area_entered(area: Area2D) -> void:

	# --------- ROOM ---------
	if area.name.begins_with("Room"):
		print("enter")
		print(area)
		black_screen.transition()
		var poly: CollisionPolygon2D = area.get_node("CollisionPolygon2D")
		var points = poly.polygon
		

		
		var global_points : Array = []
		for p in points:
			global_points.append(poly.to_global(p))

		# Bounding box
		var min_x = global_points[0].x
		var max_x = global_points[0].x
		var min_y = global_points[0].y
		var max_y = global_points[0].y

		for p in global_points:
			min_x = min(min_x, p.x)
			max_x = max(max_x, p.x)
			min_y = min(min_y, p.y)
			max_y = max(max_y, p.y)

		
		base_limits = {
			"left": min_x - offset,
			"right": max_x + offset,
			"top": min_y - offset,
			"bottom": max_y + offset
		}

		apply_camera_limits()



	# --------- CAMERA LIMITER ---------
	if area.name.begins_with("CameraLimiter"):
		var col = area.get_node("CollisionShape2D")
		var shape = col.shape as RectangleShape2D

		var ext = shape.extents * col.global_scale
		var center = col.to_global(Vector2.ZERO)

		var left   = center.x - ext.x - offset
		var right  = center.x + ext.x + offset
		var top    = center.y - ext.y - offset
		var bottom = center.y + ext.y + offset

		if "Left" in area.name:
			limit_left_stack.append(left)

		if "Right" in area.name:
			limit_right_stack.append(right)

		if "Top" in area.name:
			limit_top_stack.append(top)

		if "Bottom" in area.name:
			limit_bottom_stack.append(bottom)

		apply_camera_limits()





func _on_hurtbox_trigger_area_exited(area: Area2D) -> void:
	print("exit")
	print(area)
	if area.name.begins_with("CameraLimiter"):
		if "Left" in area.name and limit_left_stack.size() > 0:
			limit_left_stack.pop_back()

		if "Right" in area.name and limit_right_stack.size() > 0:
			limit_right_stack.pop_back()

		if "Top" in area.name and limit_top_stack.size() > 0:
			limit_top_stack.pop_back()

		if "Bottom" in area.name and limit_bottom_stack.size() > 0:
			limit_bottom_stack.pop_back()

		apply_camera_limits()
		return

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if moving_to_target:
		move_toward_target(delta)
		return
	if not is_on_floor() and not wall_climbing:
		velocity += get_gravity() * delta

	if stop:
		velocity.x = 0
		if is_on_floor() and not lower_state_machine.get_current_state().name.begins_with("Sit"):
			lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
		move_and_slide()
		return
		
	# cooldown dash
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer < 0.0:
			dash_cooldown_timer = 0.0

	if is_on_floor():
		can_dash = true

	if dashing:
		velocity.y = 0
		velocity.x = dash_direction * DASH_SPEED
		dash_time += delta

		if dash_time >= DASH_DURATION:
			dashing = false
			lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))
			upper_state_machine.set_current_state(upper_state_machine.get_node("IdleUpper"))
	else:
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

		if jump_holding and jump_time < MAX_JUMP_HOLD_TIME:
			var jump_t = jump_time / MAX_JUMP_HOLD_TIME
			var extra_force = (JUMP_HOLD_FORCE * (1.0 - jump_t)) * delta
			velocity.y += extra_force
			jump_time += delta
			if jump_time >= MAX_JUMP_HOLD_TIME:
				jump_holding = false
				if velocity.y < 0:
					velocity.y *= 0.4

		if direction != 0:
			velocity.x = lerp(velocity.x, direction * SPEED, ACCEL)
			visuals.scale.x = direction
		else:
			velocity.x = lerp(velocity.x, 0.0, DECEL)

		if abs(velocity.x) < VELOCITY_DEADZONE:
			velocity.x = 0

		if is_on_floor() and abs(velocity.x) > VELOCITY_DEADZONE and lower_state_machine.get_current_state().name != "WalkLower":
			lower_state_machine.set_current_state(lower_state_machine.get_node("WalkLower"))
		elif is_on_floor() and abs(velocity.x) < VELOCITY_DEADZONE and lower_state_machine.get_current_state().name == "WalkLower":
			lower_state_machine.set_current_state(lower_state_machine.get_node("IdleLower"))

	move_and_slide()
	
	# --- camera smooth lerp ---
	if camera_lerp_timer < 1.0:
		camera_lerp_timer += delta / camera_lerp_duration
	if camera_lerp_timer > 1.0:
		camera_lerp_timer = 1.0

	var t = cubic_ease_in_out(camera_lerp_timer)

	camera.limit_left   = lerp(start_limit_left, target_limit_left, t)
	camera.limit_right  = lerp(start_limit_right, target_limit_right, t)
	camera.limit_top    = lerp(start_limit_top, target_limit_top, t)
	camera.limit_bottom = lerp(start_limit_bottom, target_limit_bottom, t)



func _input(event):
	if not is_multiplayer_authority():
		return

	if event.is_action_pressed("Jump") and not dashing and not stop:
		if is_on_floor():
			lower_state_machine.set_current_state(lower_state_machine.get_node("JumpStartLower"))
			velocity.y = JUMP_INITIAL
			jump_holding = true
			jump_time = 0.0
		elif wall_climbing:
			lower_state_machine.set_current_state(lower_state_machine.get_node("JumpStartLower"))
			velocity = Vector2(-wall_dir * WALL_JUMP_FORCE.x, WALL_JUMP_FORCE.y)
			visuals.scale.x = -wall_dir
			wall_climbing = false
			can_dash = true
			jump_holding = false

	if event.is_action_released("Jump"):
		jump_holding = false
		if velocity.y < 0:
			velocity.y *= 0.4
	if event.is_action_pressed("Click") and not dashing and not stop and not is_attacking:
		var offset_position := Vector2(0,0)
		var attack_type : String
		if Input.is_action_pressed("Move_Up"):
			upper_state_machine.set_current_state(upper_state_machine.get_node("AttackUpUpper"))
			attack_type = "Up"
			offset_position.y = -30
		elif Input.is_action_pressed("Move_Down"):
			upper_state_machine.set_current_state(upper_state_machine.get_node("AttackDownUpper"))
			attack_type = "Down"
			offset_position.y = 75
		else:
			upper_state_machine.set_current_state(upper_state_machine.get_node("AttackFrontalUpper"))
			attack_type = "Frontal"
			offset_position.x = 50
			offset_position.y = 20
		offset_position.x *= %Visuals.scale.x
		rpc("spawn_attack_trail_rpc", offset_position, attack_type, %Visuals.scale.x, multiplayer.get_unique_id())
	if event.is_action_pressed("Dash") and not dashing and can_dash and dash_cooldown_timer <= 0.0 and not wall_climbing and not stop:
		if not AbilityManager.is_unlocked("dash"):
			rpc("spawn_dash_trail_rpc", global_position)
			dashing = true
			dash_time = 0.0
			dash_direction = sign(visuals.scale.x) if visuals.scale.x != 0 else 1
			lower_state_machine.set_current_state(lower_state_machine.get_node("DashLower"))

			if not is_on_floor():
				can_dash = false
			dash_cooldown_timer = DASH_COOLDOWN

@rpc("any_peer", "call_local")
func spawn_attack_trail_rpc(position_offset: Vector2, type: String, scale_x: float, peer_id):
	if multiplayer.is_server():
		var trail = AttackTrailScene.instantiate()
		trail.scale.x = scale_x
		trail.attack_type = type
		trail.position_offset = position_offset
		trail.player_id = peer_id
		get_node(Singleton.replicated_effects_path).add_child(trail, true)


@rpc("any_peer", "call_local")
func spawn_dash_trail_rpc(pos: Vector2):
	if multiplayer.is_server():
		var trail = DashTrailScene.instantiate()
		get_node(Singleton.replicated_effects_path).add_child(trail, true)
		trail.global_position = pos

func takeDamage(damageTaken: int):
	SoundManager.play_sfx(SoundManager.SFX_DAMAGE)
	health -= damageTaken
	Change_Health_UI()

func death():
	print("Dead!")
	SoundManager.play_sfx(SoundManager.SFX_DEATH)
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()

func sit():
	lower_state_machine.set_current_state(lower_state_machine.get_node("SitOnLower"))
	moving_to_target = false
	velocity = Vector2.ZERO
	if target_reached_callback.is_valid():
		target_reached_callback.call()
	return

func move_toward_target(_delta: float) -> void:
	if navigation_agent_2d.is_navigation_finished():
		sit()
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

func _on_lower_sprite_frame_changed() -> void:
	match (%LowerSprite.animation):
		"WalkLower":
			match (%LowerSprite.frame):
				1: SoundManager.play_mc_step_sfx()
				10: SoundManager.play_mc_step_sfx()

func Health_ui():
	var Emptycontainer = hud.get_node("Control/HealthUIEmptyContainer")
	var Fullcontainer = hud.get_node("Control/HealthUIFullContainer")
	
	var existing_Empty_hearts = Emptycontainer.get_child_count()
	var existing_Full_hearts = Fullcontainer.get_child_count()
	
	var Fullhearts_to_add = health - existing_Full_hearts
	var Emptyhearts_to_add = health - existing_Empty_hearts
	
	if Fullhearts_to_add <= 0:
		return
		
	for i in range(Fullhearts_to_add):
		var heart = TextureRect.new()
		heart.texture = health_ui_full
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Fullcontainer.add_child(heart)
		
	for i in range(Emptyhearts_to_add):
		var heart = TextureRect.new()
		heart.texture = health_ui_empty
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		Emptycontainer.add_child(heart)

func Change_Health_UI():
	var Fullcontainer = hud.get_node("Control/HealthUIFullContainer")
	var existing_Full_hearts = Fullcontainer.get_child_count()
	var target_full = health
	while existing_Full_hearts > target_full:
		var last_heart = Fullcontainer.get_child(existing_Full_hearts - 1)
		last_heart.queue_free()
		existing_Full_hearts -= 1

func WriteFlasks():
	var flasks_counter = hud.get_node("Control/CoinCounter")
	flasks_counter.text = str(flasks)

func _on_hurtbox_trigger_body_entered(body: Node2D) -> void:
	if body is Enemy:
		takeDamage(body.damage)
		if health <= 0:
			death()
		print(health)


func cubic_ease_in_out(t: float) -> float:
	if t < 0.5:
		return 4 * t * t * t
	else:
		var f = (2 * t) - 2
		return 0.5 * f * f * f + 1
