extends Area2D

const DIALOGUE_1 = preload("res://Scenes/Dialogue/Dialogue1.dialogue")
var player_in_range = false
var player_ref: CharacterBody2D = null
var choice_tag

@onready var label: Label = $"../Label"

func _ready() -> void:
	# Connetti il segnale per intercettare ogni linea del dialogo
	DialogueManager.got_dialogue.connect(_on_got_dialogue)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

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
		DialogueManager.show_dialogue_balloon(DIALOGUE_1, "start")

# Questo viene chiamato ogni volta che una linea viene mostrata
func _on_got_dialogue(line: DialogueLine) -> void:
	if line.has_tag("choice"):
		choice_tag = line.get_tag_value("choice")
		# qui puoi fare logica tipo salvare la scelta nel player
		# player_ref.last_choice = choice_tag

func _on_dialogue_ended(resource) -> void:
	# Logica finale, ad esempio sbloccare un'abilità
	player_ref.dialogue_active = false
	if choice_tag == "A":
		if !AbilityManager.is_unlocked("dash"):
			AbilityManager.unlock_ability("dash")
	
