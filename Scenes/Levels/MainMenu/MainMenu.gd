extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Control = $SectionsContainer
@onready var slots := [%File1Container, %File2Container, %File3Container]
@onready var delete_button: TextureRect = %DeleteFileButton
@onready var join_button: TextureRect = %JoinDreamButton
@onready var join_lobby_container: PanelContainer = %JoinLobbyContainer
@onready var menu_buttons := [%EnterDreamButton, %InviteDreamersButton, %SettingsButton, %ChallengesButton]

var current_section := 0
var total_sections := 4

var current_slot := 0
var current_button := 0 # 0 = Delete, 1 = Join
var in_delete_layer := false
var in_join_layer := false
var previous_slot := 0  # salva il file selezionato quando si scende nei bottoni

var current_menu_button := 0

const SECTION_WIDTH := 1920
var tween_active := true
var slot_tween_active := false
var popup_active_ind := 0

func _ready() -> void:
	SteamLobbyManager.lobby_code_label = %LobbyCode
	animation_player.play("FadeLogo")
	initial_update_selection_visual()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "FadeLogo":
		tween_active = false

# ---------------------------------------------------------
# INPUT
# ---------------------------------------------------------
func _input(event):
	if tween_active or slot_tween_active:
		return
	# ---------------------------------------------------------
	# INPUT: MOVE RIGHT / LEFT
	# ---------------------------------------------------------
	if event.is_action_pressed("Move_Right"):
		if current_section == 0:
			return
		elif current_section == 1:
			if not in_delete_layer and not in_join_layer:
				select_slot(current_slot + 1)

	elif event.is_action_pressed("Move_Left"):
		if current_section == 0:
			return
		elif current_section == 1:
			if not in_delete_layer and not in_join_layer:
				select_slot(current_slot - 1)

	# ---------------------------------------------------------
	# INPUT: MOVE UP
	# ---------------------------------------------------------
	elif event.is_action_pressed("Move_Up"):
		if current_section == 0:
			return
		elif current_section == 1 and popup_active_ind == 0:
			if in_delete_layer:
				in_delete_layer = false
				update_selection_visual()
			elif in_join_layer:
				in_join_layer = false
				in_delete_layer = true
				current_button = 0
				update_selection_visual()
		elif current_section == 2:
			current_menu_button = clamp(current_menu_button - 1, 0, menu_buttons.size()-1)
			update_selection_visual()

	# ---------------------------------------------------------
	# INPUT: MOVE DOWN
	# ---------------------------------------------------------
	elif event.is_action_pressed("Move_Down"):
		if current_section == 0:
			return
		elif current_section == 1 and popup_active_ind == 0:
			if not in_delete_layer and not in_join_layer:
				in_delete_layer = true
				current_button = 0 # delete
				previous_slot = current_slot
				update_selection_visual()
			elif in_delete_layer:
				in_delete_layer = false
				in_join_layer = true
				update_selection_visual()
		elif current_section == 2:
			current_menu_button = clamp(current_menu_button + 1, 0, menu_buttons.size()-1)
			update_selection_visual()

	# ---------------------------------------------------------
	# INPUT: CLICK / ACCEPT
	# ---------------------------------------------------------
	elif event.is_action_pressed("Click"):
		if current_section == 0:
			go_to_section(1)
		elif current_section == 1:
			if popup_active_ind == 1:
				SteamLobbyManager.join_by_code(%JoinCode.text)
			elif in_join_layer:
				join_lobby_container.scale = Vector2(0, 0)
				join_lobby_container.visible = true
				popup_active_ind = 1
				var tween = create_tween()
				tween.tween_property(join_lobby_container, "scale", Vector2(1, 1), 0.35) \
				.set_trans(Tween.TRANS_SINE) \
				.set_ease(Tween.EASE_OUT)
				tween.finished.connect(func():
					%JoinCode.grab_focus()
				)
			elif in_delete_layer:
				print("Delete File selected for slot ", current_slot + 1)
			else:
				go_to_section(2)
		elif current_section == 2:
			match current_menu_button:
				0:
					get_tree().change_scene_to_file("res://scenes/Levels/Game/Game.tscn")
				1:
					SteamLobbyManager.host_lobby(4)
					SteamLobbyManager.on_invite_button_pressed()
					go_to_section(3)
		elif current_section == 3:
			SteamLobbyManager.on_invite_button_pressed()
	# ---------------------------------------------------------
	# INPUT: CANCEL
	# ---------------------------------------------------------
	elif event.is_action_pressed("ui_cancel"):
		if current_section == 0:
			return
		else:
			match popup_active_ind:
				0:
					go_to_section(current_section - 1)
				1:
					var tween = create_tween()
					tween.tween_property(join_lobby_container, "scale", Vector2(0, 0), 0.25) \
						.set_trans(Tween.TRANS_SINE) \
						.set_ease(Tween.EASE_IN)
					tween.finished.connect(func():
						popup_active_ind = 0
						join_lobby_container.visible = false
					)

# ---------------------------------------------------------
# TRANSIZIONE SEZIONE
# ---------------------------------------------------------
func go_to_section(index: int) -> void:
	if tween_active:
		return
	
	current_section = clamp(index, 0, total_sections)
	var target_x = -current_section * SECTION_WIDTH
	var tween = create_tween()
	tween_active = true
	
	tween.tween_property(container, "position:x", target_x, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): tween_active = false)

# ---------------------------------------------------------
# SELEZIONE SLOT
# ---------------------------------------------------------
func select_slot(index: int):
	if tween_active or slot_tween_active or popup_active_ind != 0:
		return

	var prev_slot := current_slot
	current_slot = wrapi(index, 0, slots.size())

	if prev_slot == current_slot:
		return

	slot_tween_active = true
	var tween = create_tween()
	var duration := 0.1

	for i in range(slots.size()):
		var slot_content = slots[i]
		var target_scale: Vector2
		var target_color: Color

		if i == current_slot:
			target_scale = Vector2(1.01, 1.01)
			target_color = Color(1, 1, 1, 1)
		else:
			target_scale = Vector2(1, 1)
			target_color = Color(0.5, 0.5, 0.5, 1)

		tween.parallel().tween_property(slot_content, "scale", target_scale, duration)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot_content, "modulate", target_color, duration)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

	tween.finished.connect(func():
		slot_tween_active = false
		update_selection_visual()
	)

# ---------------------------------------------------------
# AGGIORNA SELEZIONE VISIVA
# ---------------------------------------------------------

func initial_update_selection_visual():
	for i in range(slots.size()):
		var slot = slots[i]

		# Slot attivo
		if i == current_slot and not in_delete_layer and not in_join_layer:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(1,1,1,1), 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01, 1.01)

		# Slot evidenziato mentre sei in Delete
		elif in_delete_layer and i == previous_slot:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.749, 0.0, 0.0, 0.75), 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01,1.01)

		# Slot evidenziato mentre sei in Join
		elif in_join_layer and i == previous_slot:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.75,0.75,0.75,1), 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01,1.01)

		# Altri slot scuri
		else:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.5,0.5,0.5,1), 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1,1)
	delete_button.modulate = Color(1, 1, 1, 1) if in_delete_layer else Color(0.6, 0.6, 0.6, 1)
	join_button.modulate = Color(1, 1, 1, 1) if in_join_layer else Color(0.6, 0.6, 0.6, 1)
	for i in range(menu_buttons.size()):
		var btn = menu_buttons[i]
		var tween = create_tween()
		if i == current_menu_button:
			tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1.05, 1.05)
		else:
			tween.tween_property(btn, "modulate", Color(0.6, 0.6, 0.6, 1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1, 1)

func update_selection_visual():
	if current_section == 1:
		for i in range(slots.size()):
			var slot = slots[i]

			# Slot attivo
			if i == current_slot and not in_delete_layer and not in_join_layer:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(1,1,1,1), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1.01, 1.01)

			# Slot evidenziato mentre sei in Delete
			elif in_delete_layer and i == previous_slot:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(0.749, 0.0, 0.0, 0.75), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1.01,1.01)

			# Slot evidenziato mentre sei in Join
			elif in_join_layer and i == previous_slot:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(0.75,0.75,0.75,1), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1.01,1.01)

			# Altri slot scuri
			else:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(0.5,0.5,0.5,1), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1,1)
		delete_button.modulate = Color(1, 1, 1, 1) if in_delete_layer else Color(0.6, 0.6, 0.6, 1)
		join_button.modulate = Color(1, 1, 1, 1) if in_join_layer else Color(0.6, 0.6, 0.6, 1)
	elif current_section == 2:
		for i in range(menu_buttons.size()):
			var btn = menu_buttons[i]
			var tween = create_tween()
			if i == current_menu_button:
				tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1.01)
			else:
				tween.tween_property(btn, "modulate", Color(0.6, 0.6, 0.6, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1)
