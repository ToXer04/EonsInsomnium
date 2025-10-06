extends CharacterBody2D
@onready var nav2d: NavigationAgent2D = $NavigationAgent2D
@onready var debug_label: Label = $"../DebugLabel"
var speed: float = 100.0

func  _physics_process(delta: float) -> void:
	manual_navigation()
	navigate(delta)

func  manual_navigation() -> void:
	nav2d.target_position = Singleton.player.position + Vector2(0, -150)
	
func navigate(_delta: float) -> void:
	if nav2d.is_navigation_finished():
		return
	var next_path_position: Vector2 = nav2d.get_next_path_position()
	var new_velocity: Vector2 = (
		global_position.direction_to(next_path_position) * speed
	)
	velocity = new_velocity
	move_and_slide()
