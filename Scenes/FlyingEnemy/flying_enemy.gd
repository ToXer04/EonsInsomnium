extends CharacterBody2D


const speed = 150.0
var dir : Vector2
var is_chase: bool = true
var player: CharacterBody2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


func _process(delta: float) -> void:
	move(delta)

func move(delta):
	if is_chase:
		dir = to_local(nav_agent.get_next_path_position()).normalized()
		player = Singleton.player
		velocity = dir * speed
	elif !is_chase:
		velocity+= dir * speed * delta
	move_and_slide()

func makepath():
	nav_agent.target_position = player.global_position

func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([0.5, 0.8])
	if !is_chase:
		dir = choose([Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN])
	else:
		makepath()


func choose(array):
	array.shuffle()
	return array.front()
