extends Node2D
@export var enemy = preload("res://Scenes/Enemies/Enemy/Enemy.tscn")
@export var max_mobs: int
var entered: bool = false
var spawned_mobs: Array = []
var kills : int = 0
@onready var timer: Timer = $Timer


func _on_timer_timeout() -> void:
	var entity = enemy.instantiate()
	if entered == true and spawned_mobs.size() < max_mobs - kills:
		entity.position = position
		get_parent().add_child(entity)
		spawned_mobs.append(entity)
		var body = entity.get_node("CharacterBody2D")
		body.spawner = self
	else:
		return

func _on_mob_died():
	kills += 1
	
	
func _despawn_mobs() -> void:
	for mob in spawned_mobs:
		if is_instance_valid(mob):
			mob.queue_free()
		
	spawned_mobs.clear()




func _on_area_2d_body_entered(body: Node2D) -> void:
	entered = true
	timer.start(1)


func _on_area_2d_body_exited(body: Node2D) -> void:
	entered = false
	_despawn_mobs()
