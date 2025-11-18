extends Node

var abilities: Dictionary = {
	"double_jump": {
		"name": "Doppio Salto",
		"description": "Permette un secondo salto in aria.",
		#"icon": preload(),
		"unlocked": false
	},
	"dash": {
		"name": "Dash",
		"description": "Scatto rapido in avanti.",
		"icon": preload("res://Sprites/Assets/Dash/Ability_Dash.png"),
		"unlocked": false
	},
	"wall_jump": {
		"name": "Wall Jump",
		"description": "Permette di saltare quando si è aggrappati a un muro.",
		#"icon": preload(),
		"unlocked": false
	}
}

var popup = preload("res://Scenes/NPC/PopUp/AbilityPopUp.tscn")


func is_unlocked(key: String) -> bool:
	return abilities.has(key) and abilities[key]["unlocked"]
	
func get_info(key: String) -> Dictionary:
	return abilities.get(key, {})
	
func unlock_ability(key: String) -> void:
	if abilities.has(key):
		abilities[key]["unlocked"] = true
		var popup_instance = popup.instantiate()
		get_tree().root.add_child(popup_instance)
		popup_instance.show_ability(key)
