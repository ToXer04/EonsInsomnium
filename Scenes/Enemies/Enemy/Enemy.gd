extends CharacterBody2D
class_name Enemy
@onready var state_machine: StateMachine = $StateMachine

@onready var spawner = preload("res://Scenes/Enemies/Spawner.tscn")

var DEFAULT_STATE = ""
var damage: int = 1
var health: int = 3
var speed : int = 150
var dir = 1
var gravity = ProjectSettings.get_setting('physics/2d/default_gravity')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func onHit(damageTaken: int):
	takeDamage(damageTaken)
	if health <= 0:
		
		velocity = Vector2(0, 0)
		death()

func takeDamage(damageTaken: int):
	health -= damageTaken
	print(health)

func death():
	state_machine.set_current_state(state_machine.get_node("Death"))
	spawner._on_mob_died()
	
	
