extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Control = $SectionsContainer
@onready var slots := [%File1Container, %File2Container, %File3Container]
@onready var delete_button: TextureRect = %DeleteFileButton
@onready var join_button: TextureRect = %JoinDreamButton
@onready var join_lobby_container: PanelContainer = %JoinLobbyContainer
@onready var menu_buttons := [%EnterDreamButton, %InviteDreamersButton, %SettingsButton, %ChallengesButton]

# nuovi nodi per lobby UI
@onready var players_container: Node = %PlayersFramesContainer
@onready var disband_node: TextureRect = %DisbandDream

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

# ---- navigation per lobby UI (section 3) ----
# lobby_nav_index: 0..2 -> Player2,3,4 ; 3 -> Disband
var lobby_nav_index := 0
const LOBBY_NAV_SLOTS := 3  # numero di slot selezionabili (2,3,4)
var lobby_nav_active := false

func _ready() -> void:
	SteamLobbyManager.lobby_code_label = %LobbyCode
	animation_player.play("FadeLogo")
	initial_update_selection_visual()
	# assicurati che disband_node sia visibile/aggiornato
	_update_lobby_nav_visual()

func _process(_delta):
	if SteamLobbyManager.lobby_id != 0:
		update_lobby_players_ui()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "FadeLogo":
		tween_active = false

# ---------------------------------------------------------
# INPUT
# ---------------------------------------------------------
func _input(event):
	if tween_active or slot_tween_active:
		return

	# Se siamo nella sezione multiplayer (3), gestiamo la navigazione dei player/disband
	if current_section == 3:
		_handle_lobby_navigation_input(event)
		return

	# ---------------------------------------------------------
	# INPUT: MOVE RIGHT / LEFT (sezioni normali)
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
			elif in_join_layer:
				in_join_layer = false
				in_delete_layer = true
				current_button = 0
		elif current_section == 2:
			if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
				current_menu_button = clamp(current_menu_button - 1, 0, menu_buttons.size()-1)
			else:
				current_menu_button = clamp(current_menu_button - 1, 1, menu_buttons.size()-2)
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
			if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
				current_menu_button = clamp(current_menu_button + 1, 0, menu_buttons.size()-1)
			else:
				current_menu_button = clamp(current_menu_button + 1, 1, menu_buttons.size()-2)
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
					get_tree().change_scene_to_file("res://Scenes/Levels/Game/Game.tscn")
				1:
					if SteamLobbyManager.lobby_id == 0:
						SteamLobbyManager.host_lobby(4)
					go_to_section(3)
		elif current_section == 3:
			# qui è gestito dal _handle_lobby_navigation_input, ma teniamo fallback
			_handle_lobby_click()
	# ---------------------------------------------------------
	# INPUT: CANCEL
	# ---------------------------------------------------------
	elif event.is_action_pressed("ui_cancel"):
		if current_section == 0 or (current_section == 2 and Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id)):
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
# HANDLERS LOBBY NAV
# ---------------------------------------------------------

var last_lobby_slot_index := 0

func _handle_lobby_navigation_input(event):
	# Movimento orizzontale tra i 3 slot (Player2..4)
	if event.is_action_pressed("Move_Right"):
		# se ero su Disband, torno a ultimo slot
		if lobby_nav_index == LOBBY_NAV_SLOTS:
			lobby_nav_index = LOBBY_NAV_SLOTS - 1
		else:
			lobby_nav_index = (lobby_nav_index + 1) % LOBBY_NAV_SLOTS
		_update_lobby_nav_visual()
		return
	elif event.is_action_pressed("Move_Left"):
		if lobby_nav_index == LOBBY_NAV_SLOTS:
			lobby_nav_index = 0
		else:
			lobby_nav_index = (lobby_nav_index - 1 + LOBBY_NAV_SLOTS) % LOBBY_NAV_SLOTS
		_update_lobby_nav_visual()
		return

	# Move Down -> vai su Disband
	if event.is_action_pressed("Move_Down"):
		if lobby_nav_index < LOBBY_NAV_SLOTS:
			last_lobby_slot_index = lobby_nav_index
		lobby_nav_index = LOBBY_NAV_SLOTS
		_update_lobby_nav_visual()
		return

	# Move Up -> se siamo su Disband, torniamo all'ultimo selezionato (default 0)
	if event.is_action_pressed("Move_Up"):
		if lobby_nav_index == LOBBY_NAV_SLOTS:
			lobby_nav_index = last_lobby_slot_index
			_update_lobby_nav_visual()
		return

	# Click / Accept
	if event.is_action_pressed("Click"):
		_handle_lobby_click()
		return
	
	if event.is_action_pressed("ui_cancel"):
		go_to_section(2)
	
# click handler per lobby UI
func _handle_lobby_click():
	# Se siamo su disband
	if lobby_nav_index == LOBBY_NAV_SLOTS:
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			SteamLobbyManager.disband_lobby()
		else:
			Steam.leaveLobby(SteamLobbyManager.lobby_id)
			SteamLobbyManager._on_lobby_left()
		_update_lobby_nav_visual()
		return

	# Altrimenti siamo su uno slot tra Player2..4
	var slot_idx = lobby_nav_index  # 0 => Player2, 1 => Player3, 2 => Player4
	var members = SteamLobbyManager.get_lobby_members_names()
	var target_member_index = slot_idx + 1  # members[0] è host
	if target_member_index < members.size():
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			var steam_id = Steam.getLobbyMemberByIndex(SteamLobbyManager.lobby_id, target_member_index)
			SteamLobbyManager.kick_player(steam_id)
	else:
		Steam.activateGameOverlayInviteDialog(SteamLobbyManager.lobby_id)

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
# SELEZIONE SLOT (save files)
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
# AGGIORNA SELEZIONE VISIVA (save files)
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
	if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
		current_menu_button = clamp(current_menu_button, 0, menu_buttons.size()-1)
	else:
		current_menu_button = clamp(current_menu_button, 1, menu_buttons.size()-2)
	for i in range(menu_buttons.size()):
		var btn = menu_buttons[i]
		var tween = create_tween()
		if i == current_menu_button:
			tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1.05, 1.05)
		else:
			if Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id) and (i == 0 or i == 3) and SteamLobbyManager.lobby_id != 0:
				tween.tween_property(btn, "modulate", Color(0.2, 0.2, 0.2, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1)
			else:
				tween.tween_property(btn, "modulate", Color(0.6, 0.6, 0.6, 1), 0.1)\
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
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			current_menu_button = clamp(current_menu_button, 0, menu_buttons.size()-1)
		else:
			current_menu_button = clamp(current_menu_button, 1, menu_buttons.size()-2)
		for i in range(menu_buttons.size()):
			var btn = menu_buttons[i]
			var tween = create_tween()
			if i == current_menu_button:
				tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1.01)
			else:
				if Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id) and (i == 0 or i == 3) and SteamLobbyManager.lobby_id != 0:
					tween.tween_property(btn, "modulate", Color(0.2, 0.2, 0.2, 1), 0.1)\
						.set_trans(Tween.TRANS_SINE)\
						.set_ease(Tween.EASE_IN_OUT)
					btn.scale = Vector2(1, 1)
				else:
					tween.tween_property(btn, "modulate", Color(0.6, 0.6, 0.6, 1), 0.1)\
						.set_trans(Tween.TRANS_SINE)\
						.set_ease(Tween.EASE_IN_OUT)
					btn.scale = Vector2(1, 1)

# ---------------------------------------------------------
# LOBBY PLAYERS UI
# ---------------------------------------------------------
func update_lobby_players_ui():
	var members = SteamLobbyManager.get_lobby_members_names()

	# Slot 1: il giocatore locale
	var frame1 = players_container.get_child(0)
	var player_container1 = frame1.get_node("PanelContainer/MarginContainer/PlayerContainer")
	if members.size() > 0:
		player_container1.visible = true
		player_container1.get_node("PlayerName").text = members[0]
	else:
		player_container1.visible = false
		player_container1.get_node("PlayerName").text = "Unknown"

	# Slot 2-4
	for i in range(1, 4):
		var frame = players_container.get_child(i)
		var player_container = frame.get_node("PanelContainer/MarginContainer/PlayerContainer")
		var invite_label = frame.get_node("InviteLabel")

		if i < members.size():
			player_container.visible = true
			player_container.get_node("PlayerName").text = members[i]
			invite_label.visible = false
		else:
			player_container.visible = false
			invite_label.visible = true

	# aggiorna visual selezione bordo
	disband_node.get_node("DisbandDreamLabel").visible = Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id)
	disband_node.get_node("LeaveDreamLabel").visible = Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id)
	_update_lobby_nav_visual()
	update_selection_visual()

# modifica il bordo (StyleBoxFlat) del PanelContainer del frame selezionato
func _set_panel_border(panel: PanelContainer, white: bool) -> void:
	# prova a prendere lo stylebox corrente
	var sb = null
	if panel.has_method("get_theme_stylebox"):
		sb = panel.get_theme_stylebox("panel")
	if sb == null:
		# fallback: prova a leggere "custom_styles/panel"
		if panel.has_meta("custom_styles"):
			sb = panel.get("custom_styles/panel")
	# se abbiamo un StyleBoxFlat, duplichiamolo e sovrascriviamo
	if sb and sb is StyleBoxFlat:
		var copy = sb.duplicate()
		copy.border_color = Color(1,1,1,1) if white else Color(0,0,0,1)
		panel.add_theme_stylebox_override("panel", copy)
	else:
		# fallback: usa self_modulate per dare un feedback visivo minimo
		panel.self_modulate = Color(1,1,1,1) if white else Color(1,1,1,1)

# aggiorna visuale della navigazione lobby (bordi e bottone Disband)
func _update_lobby_nav_visual():
	# Player frames
	for i in range(1, 4):
		var frame = players_container.get_child(i)
		var panel = frame.get_node("PanelContainer")
		if lobby_nav_index == i - 1 and current_section == 3:
			_set_panel_border(panel, true) # selected -> white
		else:
			_set_panel_border(panel, false) # not selected -> black

	# Disband button modulate
	if lobby_nav_index == LOBBY_NAV_SLOTS and current_section == 3:
		disband_node.modulate = Color(1,1,1,1)
	else:
		disband_node.modulate = Color(0.6,0.6,0.6,1)
