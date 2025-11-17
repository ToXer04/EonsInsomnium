extends RigidBody2D

@export var value: int = 1

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var coin_sprites: Dictionary = {
	1: preload("uid://bj6mtyoxckf1q"),
	3: preload("uid://bd4oiwmpdy02t"),
	5: preload("uid://bk6ernwgawkfr"),
	10: preload("uid://hactyoipldba"),
	50: preload("uid://mux3sdqfe08s")
}



func _ready() -> void:
	if value in coin_sprites:
		sprite_2d.texture = coin_sprites[value]
	else:
		sprite_2d.texture = coin_sprites[1]


func _on_area_2d_body_entered(body: Node2D) -> void:
	body.coins += value
	body.WriteCoins()
	queue_free()
