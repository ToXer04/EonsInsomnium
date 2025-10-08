extends Enemy
class_name GroundEnemy



func _physics_process(_delta: float) -> void:
	if health > 0:
		velocity.y = gravity
		velocity.x = speed * dir
		move_and_slide()
	


func _on_front_trigger_body_entered(_body: Node2D) -> void:
	dir *= -1
	scale.x *= -1

func _on_ledge_trigger_body_exited(_body: Node2D) -> void:
	dir *= -1
	scale.x *= -1
