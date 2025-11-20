extends Area2D

var player_in_range = false
var player_ref: CharacterBody2D = null
var shop_ui = preload("res://Scenes/NPC/Shop/ShopUI.tscn")
var shop_ui_instance = shop_ui.instantiate()

@onready var label: Label = $"../Label"


func _on_body_entered(body: Node2D) -> void:
	player_ref = body
	player_in_range = true
	label.show()


func _on_body_exited(body: Node2D) -> void:
	player_in_range = false
	label.hide()

	# Se esce dall'area → chiudi shop
	if shop_ui_instance.visible:
		chiudi_shop()


func _process(delta: float) -> void:

	# Se non c'è il player → esci
	if player_ref == null:
		return

	# --------------------------------------------------
	# APRI LO SHOP (premi Interact quando sei nel range)
	# --------------------------------------------------
	if player_in_range and Input.is_action_just_pressed("Interact") and not shop_ui_instance.visible:
		# Blocca movimento player
		player_ref.stop = true
		player_ref.dashing = false

		# 🔥 ASPETTA CHE IL PLAYER TOCCHI IL TERRENO
		if not player_ref.is_on_floor():
			await get_tree().create_timer(0.05).timeout
			while player_ref != null and not player_ref.is_on_floor():
				await get_tree().process_frame

		# Ora apri lo shop
		if shop_ui_instance.get_parent() == null:
			get_tree().root.add_child(shop_ui_instance)

		# Mostra shop
		shop_ui_instance.visible = true
		label.hide()

		


	# --------------------------------------------------
	# CHIUDI LO SHOP CON SPAZIO
	# --------------------------------------------------
	if shop_ui_instance.visible and Input.is_action_just_pressed("Jump"):
		chiudi_shop()
		

func chiudi_shop():
	shop_ui_instance.visible = false
	if player_ref:
		player_ref.stop = false
	label.show()  # torna il popup "premi E"
