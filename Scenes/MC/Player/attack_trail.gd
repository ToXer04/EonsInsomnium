extends AnimatedSprite2D

@export var attack_type: String 
@export var player_id: int
@export var position_offset: Vector2

var player_ref: Player
func _ready() -> void:
	player_ref = Singleton.players.get(player_id)
	match attack_type:
		"Frontal":
			play("AttackFrontal")
		"Up":
			play("AttackUp")
		"Down":
			play("AttackDown")

func _process(_delta: float) -> void:
	if multiplayer.get_unique_id() == player_id:
		global_position = player_ref.global_position + position_offset

func _on_animation_finished() -> void:
	queue_free()
