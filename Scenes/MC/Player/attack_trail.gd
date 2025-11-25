extends AnimatedSprite2D

@export var attack_type: String 
@export var player_ref: Player
@export var position_offset: Vector2

func _ready() -> void:
	match attack_type:
		"Frontal":
			play("AttackFrontal")
		"Up":
			play("AttackUp")
		"Down":
			play("AttackDown")

func _process(_delta: float) -> void:
	if multiplayer.is_server():
		global_position = player_ref.global_position + position_offset

func _on_animation_finished() -> void:
	queue_free()
