extends AnimatedSprite2D

@export var attack_type: String 
@export var player_id: int
@export var position_offset: Vector2

var player_ref: Player
func _ready() -> void:
	var player_path = Singleton.replicated_players_path + str(player_id)
	player_ref = get_node(player_path)
	match attack_type:
		"Frontal":
			play("AttackFrontal")
		"Up":
			play("AttackUp")
		"Down":
			play("AttackDown")

func _process(_delta: float) -> void:
	if player_ref != null:
		global_position = player_ref.global_position + position_offset
		
func _on_animation_finished() -> void:
	await get_tree().create_timer(1).timeout
	queue_free()
