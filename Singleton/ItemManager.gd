extends Node

var items: Dictionary = {
	"map": {
		"name": "Map",
		"description": "Puoi vedere dove sei sulla mappa.",
		#"icon": preload(),
		"unlocked": false
	}
}

var popup = preload("res://Scenes/NPC/PopUp/ItemPopUp.tscn")


func is_unlocked(key: String) -> bool:
	return items.has(key) and items[key]["unlocked"]
	
func get_info(key: String) -> Dictionary:
	return items.get(key, {})
	
func unlock_ability(key: String) -> void:
	if items.has(key):
		items[key]["unlocked"] = true
		var popup_instance = popup.instantiate()
		get_tree().root.add_child(popup_instance)
		popup_instance.show_ability(key)
