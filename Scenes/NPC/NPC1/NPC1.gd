extends Area2D
var player_in_range = false
var player_ref: CharacterBody2D = null
var shop_ui = preload("res://Scenes/NPC/Shop/ShopUI.tscn")
var shop_ui_instance = shop_ui.instantiate()
func _on_body_entered(body: Node2D) -> void:
	player_ref = body
	player_in_range = true
	shop_ui_instance.visible = true
	print(shop_ui_instance.visible)
	if shop_ui_instance.get_parent() == null:
			get_tree().root.add_child(shop_ui_instance)


func _on_body_exited(body: Node2D) -> void:
	player_ref = null
	player_in_range = false
	shop_ui_instance.visible = false
	
