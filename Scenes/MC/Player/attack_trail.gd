extends AnimatedSprite2D

@export var attack_type: String 

func _ready() -> void:
	match attack_type:
		"Frontal":
			play("AttackFrontal")
		"Up":
			play("AttackUp")
		"Down":
			play("AttackDown")

func _on_animation_finished() -> void:
	queue_free()
