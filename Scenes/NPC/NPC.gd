extends Area2D

const DIALOGUE_1 = preload("res://Scenes/Dialogue/Dialogue1.dialogue")
var player_in_range = false
var player_ref: CharacterBody2D = null

@onready var label: Label = $"../Label"



func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_dialogue_ended)


func _on_body_entered(body: Node2D) -> void:
	player_ref = body
	player_in_range = true
	label.show()
	
	
	
	


func _on_body_exited(body: Node2D) -> void:
	player_ref = null
	player_in_range = false
	label.hide()



func _process(delta: float) -> void:
	
	if player_in_range and Input.is_action_just_pressed("Interact"):
		label.hide()
		player_ref.dialogue_active = true
		print(player_ref.dialogue_active)
		DialogueManager.show_dialogue_balloon(DIALOGUE_1, "start")
		
func _dialogue_ended(resource):
	player_ref.dialogue_active = false
	print(player_ref.dialogue_active)
