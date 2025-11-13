extends GroundEnemy
class_name Gloop
@onready var raycastfront: RayCast2D = $RayCast2DFront
@onready var raycastunder: RayCast2D = $RayCast2DDown
var velocity_dir = Vector2.RIGHT
var found = false
var initialized = false
var surface
var turningDown = false
var turningFront = false
var wall
var is_tweening
var is_flying = true

func _ready() -> void:
	speed = 200
	gravity = 0
	coins = 125
	DEFAULT_STATE = "Idle"
	await get_tree().process_frame
	var start_state = state_machine.get_node(DEFAULT_STATE)
	if start_state:
		state_machine.set_current_state(start_state)


func _physics_process(_delta: float) -> void:
	if health > 0:
		if not raycastunder.is_colliding() and is_flying:
			position.y = position.y + 10
			move_and_slide()
			return
		if turningDown:
			return
		velocity = velocity_dir * speed
		move_and_slide()
		raycastunder.force_raycast_update()
		raycastfront.force_raycast_update()
		if not initialized:
			initialized = true
			return
		if raycastfront.is_colliding() and not turningFront and not turningDown:
			turningFront = true
			await get_tree().process_frame
			raycastfront.force_raycast_update()

			wall = raycastfront.get_collision_normal()
			var tangent1 = Vector2(-wall.y, wall.x).normalized()
			var tangent2 = Vector2(wall.y, -wall.x).normalized()
	
# Scegli la tangente più vicina alla direzione corrente
			var tangent: Vector2
			if velocity_dir == Vector2.ZERO:
				tangent = tangent1 if tangent2.x > tangent1.x else tangent2
			else:
	# Scegli tangente più coerente con velocity_dir
				tangent = tangent2 if tangent1.dot(velocity_dir) > tangent2.dot(velocity_dir) else tangent1


# Calcola target vicino alla superficie
			var collision_point = raycastfront.get_collision_point()
			var offset_distance = 1.0
			var target_pos = collision_point + wall * offset_distance

# Rotazione verso la nuova tangente
			var desired_angle = tangent.angle()
			var angle_diff = wrapf(desired_angle - rotation, -PI, PI)
			var target_angle = rotation + angle_diff

# Tween morbido
			var tween = create_tween()
			tween.tween_property(self, "rotation", target_angle, 50/float(speed)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(self, "global_position", target_pos, 50/float(speed)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			await tween.finished
			velocity_dir = tangent
			turningFront = false
	
		if not raycastunder.is_colliding() and not turningDown and not turningFront:
			turningDown = true
			var old_speed = speed
			await get_tree().process_frame
		
			var tangent_down = velocity_dir.rotated(deg_to_rad(90)).normalized()
		

	# Calcola la nuova rotazione
			var desired_angle = tangent_down.angle()
			var angle_diff = wrapf(desired_angle - rotation, -PI, PI)
			var target_angle = rotation + angle_diff

	# Tween morbido per rotazione
			var tween = create_tween()
			tween.tween_property(self, "rotation", target_angle, 50/float(old_speed)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			await tween.finished

	# Aggiorna direzione e resetta stato
			velocity_dir = tangent_down
			speed = old_speed
			turningDown = false
		elif is_flying and raycastunder.is_colliding():
			is_flying = false
			return
