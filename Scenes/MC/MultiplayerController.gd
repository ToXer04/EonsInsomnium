extends CharacterBody2D
@onready var state_machine: StateMachine = %StateMachine
@onready var visuals: Node2D = %Visuals

const DEFAULT_STATE = "Idle"

@export var player_id := 1:
	set(id):
		player_id = id


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

func _apply_animation(delta):
	pass #ci va tutto cio per animazioni
	
func _apply_movement_from_input(delta):
	pass #ci va tutto cio per input
