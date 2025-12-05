extends StaticBody2D
class_name Breakable
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var is_broken = false

func destroy():
	if is_broken:
		return
	is_broken = true
	
	anim.play("destroyed")   # ← ANIMAZIONE DI DISTRUZIONE
	
	# Quando finisce l’animazione puoi eliminare l’oggetto
	await anim.animation_finished
