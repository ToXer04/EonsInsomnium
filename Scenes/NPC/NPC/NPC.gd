extends Area2D

const DIALOGUE_1 = preload("res://Scenes/Dialogue/Dialogue1.dialogue")

var player_in_range = false
var player_ref: CharacterBody2D = null
var choice_tag
var is_dialogue_open = false   # 🔥 blocca il doppio avvio del dialogo

@onready var label: Label = $"../Label"


func _ready() -> void:
	DialogueManager.got_dialogue.connect(_on_got_dialogue)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


# ---------------------------------------------------------
# ENTRA NELL’AREA
# ---------------------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	player_ref = body
	player_in_range = true
	label.show()


# ---------------------------------------------------------
# ESCI DALL’AREA
# ---------------------------------------------------------
func _on_body_exited(_body: Node2D) -> void:
	player_in_range = false
	label.hide()


# ---------------------------------------------------------
# PROCESS: INTERACT → APRI DIALOGO
# ---------------------------------------------------------
func _process(_delta: float) -> void:

	# 🔒 se il player non c’è più, non fare nulla
	if player_ref == null:
		return

	# 🔥 SE DIALOGO GIÀ APERTO → BLOCCA INTERAZIONE
	if is_dialogue_open:
		return

	# Quando premi Interact
	if player_in_range and Input.is_action_just_pressed("Interact"):

		# 🔒 Segna che un dialogo sta per partire
		is_dialogue_open = true

		label.hide()
		
		player_ref.dashing = false
		player_ref.velocity = Vector2.ZERO
		player_ref.stop = true
		# Aspetta che il player tocchi il terreno
		if not player_ref.is_on_floor():
			await get_tree().create_timer(0.05).timeout
			while player_ref != null and not player_ref.is_on_floor():
				await get_tree().process_frame
		
		

		# Avvia dialogo
		DialogueManager.show_dialogue_balloon(DIALOGUE_1, "start")


# ---------------------------------------------------------
# OGNI LINEA: RILEVA TAG "choice"
# ---------------------------------------------------------
func _on_got_dialogue(line: DialogueLine) -> void:
	if line.has_tag("choice"):
		choice_tag = line.get_tag_value("choice")


# ---------------------------------------------------------
# DIALOGO FINITO
# ---------------------------------------------------------
func _on_dialogue_ended(_resource) -> void:

	if player_ref == null:
		return

	# 🔓 Sblocca dialogo
	is_dialogue_open = false

	# Sblocca movimento player
	player_ref.stop = false
	player_ref.dialogue_active = false

	# Logica scelte
	if choice_tag == "A":
		if not AbilityManager.is_unlocked("dash"):
			AbilityManager.unlock_ability("dash")
