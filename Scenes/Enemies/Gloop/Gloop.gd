extends GroundEnemy
class_name Gloop
@onready var raycastfront: RayCast2D = $RayCast2DFront
@onready var raycastunder: RayCast2D = $RayCast2DDown
var velocity_dir = Vector2.RIGHT
var found = false
var initialized = false
var surface
var turned = false
var wall

func _ready() -> void:
	speed = 100
	gravity = 0
	DEFAULT_STATE = "Idle"
	await get_tree().process_frame
	var start_state = state_machine.get_node(DEFAULT_STATE)
	if start_state:
		state_machine.set_current_state(start_state)
	


func _physics_process(_delta: float) -> void:
	velocity = velocity_dir * speed
	move_and_slide()
	raycastunder.force_raycast_update()
	raycastfront.force_raycast_update()
	if not initialized:
		initialized = true
		return
	if raycastfront.is_colliding():
		print("a")
		await get_tree().process_frame
		raycastunder.force_raycast_update()
		wall = raycastfront.get_collision_normal()
		var tangent = Vector2(-wall.y, wall.x).normalized()
		velocity_dir = tangent
		rotation = velocity_dir.angle()
		position += wall * -raycastfront.get_collision_point().distance_to(global_position) * 1
	
	if raycastunder.is_colliding():
		wall = raycastunder.get_collision_normal()
		turned = false
	else:
		if not turned:
			print("c")
			await get_tree().process_frame
			raycastunder.force_raycast_update()
			var tangent = Vector2(-wall.y, wall.x).normalized()
			velocity_dir = velocity_dir.rotated(deg_to_rad(90))
			rotation = velocity_dir.angle()
			position += tangent * 35
			turned = true


func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
