extends Node

@onready var CoinSpawner = preload("res://Scenes/Coins/Coin.tscn")

func spawn_coins(total_value: int, position: Vector2):
	var remaining = total_value
	
	while remaining > 0:
		var coin_value = 0
		
		if remaining > 250:
			coin_value = 50
		elif remaining > 100:
			coin_value = 10
		elif remaining > 50:
			coin_value = 5
		elif remaining > 10:
			coin_value = 3
		else:
			coin_value = 1
		
		remaining -= coin_value
		
		var coin = CoinSpawner.instantiate()
		coin.value = coin_value
		
		# spawn casuale con effetto "explosion"
		var offset = Vector2(randf_range(-25, 25), randf_range(-50, -80))
		coin.global_position = position + offset
		get_tree().current_scene.add_child(coin)
		
		var direction = Vector2(randf_range(-1.0, 1.0), randf_range(-2.5, -4.0)).normalized()
		var force = randf_range(800, 1600)
		coin.linear_velocity = direction * force * 0.8
