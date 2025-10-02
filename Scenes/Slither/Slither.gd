extends CharacterBody2D
var speed : int = 150
var dir = 1
var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	velocity.y = gravity
	velocity.x = speed * dir
	move_and_slide()



func _on_front_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group('Map'):
		dir *= -1
		animated_sprite_2d.flip_h = not animated_sprite_2d.flip_h




func _on_ledge_trigger_body_exited(body: Node2D) -> void:
	if body == self:
		return
	if body.is_in_group('Map'):
		dir *= -1
		animated_sprite_2d.flip_h = not animated_sprite_2d.flip_h
		
