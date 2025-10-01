extends CharacterBody2D
var speed : int = 150
var dir = 1
var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')
@onready var ray_cast_2d_right: RayCast2D = $RayCast2DRight
@onready var ray_cast_2d_left: RayCast2D = $RayCast2DLeft
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	move_and_slide()
	velocity.y = gravity
	velocity.x = speed * dir
	if ray_cast_2d_left.is_colliding():
		dir = dir * -1
		animated_sprite_2d.scale.x = -1 
	if ray_cast_2d_right.is_colliding():
		dir = dir * -1
		animated_sprite_2d.scale.x = -1 
