extends Node2D
@onready var enemy = preload("res://Scenes/Enemies/Slither/Slither.tscn")

func _on_timer_timeout() -> void:
	var entity = enemy.instantiate()
	entity.position = position
	get_parent().add_child(entity)
