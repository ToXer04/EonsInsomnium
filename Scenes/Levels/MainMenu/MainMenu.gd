extends CanvasLayer

# Minimal, English comments only
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Control = $SectionsContainer
@onready var section1_slots := [%File1Container, %File2Container, %File3Container]
@onready var section1_delete_button: TextureRect = %DeleteFileButton
@onready var section1_join_button: TextureRect = %JoinDreamButton
@onready var join_lobby_container: PanelContainer = %JoinLobbyContainer
@onready var section2_buttons := [%EnterDreamButton, %InviteDreamersButton, %ChallengesButton]

# lobby UI nodes
@onready var players_container: Node = %PlayersFramesContainer
@onready var disband_node: TextureRect = %DisbandDream

# section indices
var current_section := 0
var total_sections := 4

var section1_slot_index := 0
var section1_previous_slot_index := 0
var section1_button_index := 0
var in_delete_layer := false
var in_join_layer := false
var popup_active_ind := 0

var section2_button_index := 0

const SECTION_WIDTH := 1920
var tween_active := true
var slot_tween_active := false

# Section 3 (lobby) navigation
var section3_nav_index := 0
const LOBBY_NAV_SLOTS := 3
var lobby_nav_active := false

func _ready() -> void:
	SteamLobbyManager.lobby_code_label = %LobbyCode
	animation_player.play("FadeLogo")
	initial_update_selection_visual()
	_update_lobby_nav_visual()

func _process(_delta):
	if SteamLobbyManager.lobby_id != 0:
		update_lobby_players_ui()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "FadeLogo":
		tween_active = false

# Input dispatcher using match on current_section
func _input(event):
	if tween_active or slot_tween_active:
		return

	match current_section:
		0:
			_handle_section0_input(event)
		1:
			_handle_section1_input(event)
		2:
			_handle_section2_input(event)
		3:
			_handle_section3_input(event)

# -------------------------
# Section handlers
# -------------------------
func _handle_section0_input(event):
	# Section 0 has no inputs for navigation
	if event.is_action_pressed("Click"):
		go_to_section(1)

func _handle_section1_input(event):
	# File slots navigation
	if event.is_action_pressed("Move_Right"):
		if not in_delete_layer and not in_join_layer:
			select_slot(section1_slot_index + 1)
		return
	
	if event.is_action_pressed("Move_Left"):
		if not in_delete_layer and not in_join_layer:
			select_slot(section1_slot_index - 1)
		return

	if event.is_action_pressed("Move_Up"):
		if popup_active_ind == 0:
			if in_delete_layer:
				in_delete_layer = false
			elif in_join_layer:
				in_join_layer = false
				in_delete_layer = true
				section1_button_index = 0
			update_selection_visual()
		return

	if event.is_action_pressed("Move_Down"):
		if popup_active_ind == 0:
			if not in_delete_layer and not in_join_layer:
				in_delete_layer = true
				section1_button_index = 0
				section1_previous_slot_index = section1_slot_index
				update_selection_visual()
			elif in_delete_layer:
				in_delete_layer = false
				in_join_layer = true
				update_selection_visual()
		return

	if event.is_action_pressed("Click"):
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
			tween.finished.connect(func(): %JoinCode.grab_focus())
		elif in_delete_layer:
			print("Delete File selected for slot ", section1_slot_index + 1)
		else:
			go_to_section(2)
		return

	if event.is_action_pressed("ui_cancel"):
		if current_section == 0:
			return
		else:
			if popup_active_ind == 0:
				go_to_section(current_section - 1)
			elif popup_active_ind == 1:
				var tween = create_tween()
				tween.tween_property(join_lobby_container, "scale", Vector2(0, 0), 0.25) \
					.set_trans(Tween.TRANS_SINE) \
					.set_ease(Tween.EASE_IN)
				tween.finished.connect(func():
					popup_active_ind = 0
					join_lobby_container.visible = false
				)
		return

func _handle_section2_input(event):
	if event.is_action_pressed("Move_Up"):
		section2_button_index = clamp(section2_button_index - 1, 0, section2_buttons.size() - 1)
		update_selection_visual()
		return

	if event.is_action_pressed("Move_Down"):
		section2_button_index = clamp(section2_button_index + 1, 0, section2_buttons.size() - 1)
		update_selection_visual()
		return

	if event.is_action_pressed("Click"):
		match section2_button_index:
			0:
				SteamLobbyManager.start_hosting_game()
			1:
				if SteamLobbyManager.lobby_id == 0:
					SteamLobbyManager.host_lobby()
				go_to_section(3)
			2:
				# Challenges action
				print("Challenges pressed")
		update_selection_visual()
		return

	if event.is_action_pressed("ui_cancel"):
		# Allow cancel normally except when in section 3 (handled elsewhere)
		go_to_section(current_section - 1)
		return

func _handle_section3_input(event):
	# Block ui_cancel in section 3 if not host
	if event.is_action_pressed("ui_cancel"):
		if Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			return
		else:
			go_to_section(2)
		return

	# Horizontal navigation and click handled in dedicated function
	if event.is_action_pressed("Move_Right") or event.is_action_pressed("Move_Left") or event.is_action_pressed("Move_Down") or event.is_action_pressed("Move_Up"):
		_handle_lobby_navigation_input(event)
		return

	if event.is_action_pressed("Click"):
		_handle_lobby_click()
		return

# -------------------------
# Lobby navigation helpers
# -------------------------
var last_lobby_slot_index := 0

func _handle_lobby_navigation_input(event):
	if event.is_action_pressed("Move_Right"):
		if section3_nav_index == LOBBY_NAV_SLOTS:
			section3_nav_index = LOBBY_NAV_SLOTS - 1
		else:
			section3_nav_index = (section3_nav_index + 1) % LOBBY_NAV_SLOTS
		_update_lobby_nav_visual()
		return
	
	if event.is_action_pressed("Move_Left"):
		if section3_nav_index == LOBBY_NAV_SLOTS:
			section3_nav_index = 0
		else:
			section3_nav_index = (section3_nav_index - 1 + LOBBY_NAV_SLOTS) % LOBBY_NAV_SLOTS
		_update_lobby_nav_visual()
		return

	if event.is_action_pressed("Move_Down"):
		if section3_nav_index < LOBBY_NAV_SLOTS:
			last_lobby_slot_index = section3_nav_index
		section3_nav_index = LOBBY_NAV_SLOTS
		_update_lobby_nav_visual()
		return

	if event.is_action_pressed("Move_Up"):
		if section3_nav_index == LOBBY_NAV_SLOTS:
			section3_nav_index = last_lobby_slot_index
			_update_lobby_nav_visual()
		return

	if event.is_action_pressed("Click"):
		_handle_lobby_click()
		return

	if event.is_action_pressed("ui_cancel"):
		go_to_section(2)

func _handle_lobby_click():
	if section3_nav_index == LOBBY_NAV_SLOTS:
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			SteamLobbyManager.disband_lobby()
		else:
			Steam.leaveLobby(SteamLobbyManager.lobby_id)
			SteamLobbyManager._on_lobby_left()
		_update_lobby_nav_visual()
		return

	var slot_idx = section3_nav_index
	var members = SteamLobbyManager.get_lobby_members_names()
	var target_member_index = slot_idx + 1
	if target_member_index < members.size():
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			var steam_id = Steam.getLobbyMemberByIndex(SteamLobbyManager.lobby_id, target_member_index)
			SteamLobbyManager.kick_player(steam_id)
	else:
		Steam.activateGameOverlayInviteDialog(SteamLobbyManager.lobby_id)

# -------------------------
# Section transitions and slot selection
# -------------------------
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

func select_slot(index: int):
	if tween_active or slot_tween_active or popup_active_ind != 0:
		return

	var prev_slot := section1_slot_index
	section1_slot_index = wrapi(index, 0, section1_slots.size())

	if prev_slot == section1_slot_index:
		return

	slot_tween_active = true
	var tween = create_tween()
	var duration := 0.1

	for i in range(section1_slots.size()):
		var slot_content = section1_slots[i]
		var target_scale: Vector2
		var target_color: Color

		if i == section1_slot_index:
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

# -------------------------
# Visual selection updates
# -------------------------
func initial_update_selection_visual():
	for i in range(section1_slots.size()):
		var slot = section1_slots[i]

		if i == section1_slot_index and not in_delete_layer and not in_join_layer:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(1,1,1,1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01, 1.01)

		elif in_delete_layer and i == section1_previous_slot_index:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.749, 0.0, 0.0, 0.75), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01,1.01)

		elif in_join_layer and i == section1_previous_slot_index:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.75,0.75,0.75,1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01,1.01)

		else:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.5,0.5,0.5,1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1,1)

	section1_delete_button.modulate = Color(1, 1, 1, 1) if in_delete_layer else Color(0.6, 0.6, 0.6, 1)
	section1_join_button.modulate = Color(1, 1, 1, 1) if in_join_layer else Color(0.6, 0.6, 0.6, 1)
	section2_button_index = clamp(section2_button_index, 0, section2_buttons.size()-1)

	for i in range(section2_buttons.size()):
		var btn = section2_buttons[i]
		var tween = create_tween()
		if i == section2_button_index:
			tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1, 1.01)
		else:
			tween.tween_property(btn, "modulate", Color(0.6, 0.6, 0.6, 1), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1, 1)

func update_selection_visual():
	if current_section == 1:
		for i in range(section1_slots.size()):
			var slot = section1_slots[i]

			if i == section1_slot_index and not in_delete_layer and not in_join_layer:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(1,1,1,1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1.01, 1.01)

			elif in_delete_layer and i == section1_previous_slot_index:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(0.749, 0.0, 0.0, 0.75), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1.01, 1.01)

			elif in_join_layer and i == section1_previous_slot_index:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(0.75,0.75,0.75,1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1.01, 1.01)

			else:
				var tween = create_tween()
				tween.tween_property(slot, "modulate", Color(0.5,0.5,0.5,1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				slot.scale = Vector2(1, 1)

		section1_delete_button.modulate = Color(1, 1, 1, 1) if in_delete_layer else Color(0.6, 0.6, 0.6, 1)
		section1_join_button.modulate = Color(1, 1, 1, 1) if in_join_layer else Color(0.6, 0.6, 0.6, 1)

	elif current_section == 2:
		print("Test")
		section2_button_index = clamp(section2_button_index, 0, section2_buttons.size()-1)
		for i in range(section2_buttons.size()):
			var btn = section2_buttons[i]
			var tween = create_tween()
			if i == section2_button_index:
				tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1.01)
			else:
				tween.tween_property(btn, "modulate", Color(0.6, 0.6, 0.6, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1)

# -------------------------
# Lobby players UI
# -------------------------
func update_lobby_players_ui():
	var members = SteamLobbyManager.get_lobby_members_names()

	var frame1 = players_container.get_child(0)
	var player_container1 = frame1.get_node("PanelContainer/MarginContainer/PlayerContainer")
	if members.size() > 0:
		player_container1.visible = true
		player_container1.get_node("PlayerName").text = members[0]
	else:
		player_container1.visible = false
		player_container1.get_node("PlayerName").text = "Unknown"

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

	disband_node.get_node("DisbandDreamLabel").visible = Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id)
	disband_node.get_node("LeaveDreamLabel").visible = Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id)
	_update_lobby_nav_visual()
	initial_update_selection_visual()

func _set_panel_border(panel: PanelContainer, white: bool) -> void:
	# Try to override panel stylebox if possible
	var sb = null
	if panel.has_method("get_theme_stylebox"):
		sb = panel.get_theme_stylebox("panel")
	if sb == null:
		if panel.has_meta("custom_styles"):
			sb = panel.get("custom_styles/panel")
	if sb and sb is StyleBoxFlat:
		var copy = sb.duplicate()
		copy.border_color = Color(1,1,1,1) if white else Color(0,0,0,1)
		panel.add_theme_stylebox_override("panel", copy)
	else:
		panel.self_modulate = Color(1,1,1,1) if white else Color(1,1,1,1)

func _update_lobby_nav_visual():
	for i in range(1, 4):
		var frame = players_container.get_child(i)
		var panel = frame.get_node("PanelContainer")
		if section3_nav_index == i - 1 and current_section == 3:
			_set_panel_border(panel, true)
		else:
			_set_panel_border(panel, false)

	if section3_nav_index == LOBBY_NAV_SLOTS and current_section == 3:
		disband_node.modulate = Color(1,1,1,1)
	else:
		disband_node.modulate = Color(0.6,0.6,0.6,1)
