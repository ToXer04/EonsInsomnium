extends CharacterBody2D
var speed : int = 150
var dir = 1
var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')

func _physics_process(_delta: float) -> void:
	velocity.y = gravity
	velocity.x = speed * dir
	move_and_slide()



func _on_front_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group('Map'):
		dir *= -1
		scale.x *= -1






func _on_ledge_trigger_body_exited(body: Node2D) -> void:
	if body == self:
		return
	if body.is_in_group('Map'):
		dir *= -1
		scale.x *= -1
