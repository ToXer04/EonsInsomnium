extends CharacterBody2D
class_name Slither

var damage: int = 1
var health: int = 3
var speed : int = 150
var dir = 1
var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')

func _physics_process(_delta: float) -> void:
	velocity.y = gravity
	velocity.x = speed * dir
	move_and_slide()

func _on_front_trigger_body_entered(_body: Node2D) -> void:
	dir *= -1
	scale.x *= -1

func _on_ledge_trigger_body_exited(_body: Node2D) -> void:
	dir *= -1
	scale.x *= -1

func onHit(damageTaken: int):
	takeDamage(damageTaken)
	if health <= 0:
		death()

func takeDamage(damageTaken: int):
	health -= damageTaken
	print(health)

func death():
	print("Killed!")
	queue_free()
