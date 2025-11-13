extends Area2D
@export var enemy = preload("res://Scenes/Enemies/Enemy/Enemy.tscn")
@export var max_mobs: int
var entered: bool = false
var spawned_mobs: Array = []
var kills : int = 0
var current_zone: String = ""
var current_zone_node: Area2D = null
@onready var timer: Timer = $Timer



func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	detect_zone()


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

func _on_zone_body_entered(_body: Node2D) -> void:
	entered = true
	timer.start(1)


func _on_zone_body_exited(_body: Node2D) -> void:
	entered = false
	_despawn_mobs()


func detect_zone():
	# Controlla tutte le aree in overlapping
	var areas = get_overlapping_areas()
	for a in areas:
			current_zone = a.zone_name
			current_zone_node = a
			_connect_zone_signals(current_zone_node)
			return
	# se non trova nessuna zona
	current_zone = ""


func _connect_zone_signals(zone: Area2D) -> void:
	zone.connect("body_entered", Callable(self, "_on_zone_body_entered"))
	zone.connect("body_exited", Callable(self, "_on_zone_body_exited"))
