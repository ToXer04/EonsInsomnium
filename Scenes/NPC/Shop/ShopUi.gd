extends CanvasLayer

var items = [
	{"name": "Spada", "desc": "Una solida spada d'acciaio.", "cost": 50, "purchased": false},
	{"name": "Pozione", "desc": "Cura 50 HP.", "cost": 20, "purchased": false},
	{"name": "Arco", "desc": "Arco da caccia.", "cost": 80, "purchased": false},
	{"name": "Scudo", "desc": "Uno scudo resistente.", "cost": 100, "purchased": false}
]

var selected_index := 0

@onready var left_panel: VBoxContainer = $Control/ScrollContainer/VBoxContainer
@onready var name_label: Label = $Control/ItemLabel
@onready var desc_label: Label = $Control/DescLabel
@onready var cost_label: Label = $Control/CostLabel
@onready var scroll_container: ScrollContainer = $Control/ScrollContainer


func _ready():
	_crea_lista()
	assicurati_item_selezionabile()
	aggiorna_dettagli()
	aggiorna_evidenziazione()


# -------------------------------------------------
# CONTROLLA SE TUTTI GLI ITEM SONO COMPRATI
# -------------------------------------------------
func tutti_acquistati() -> bool:
	for item in items:
		if not item["purchased"]:
			return false
	return true


# -------------------------------------------------
# MOSTRA MESSAGGIO "TUTTO ACQUISTATO"
# -------------------------------------------------
func mostra_tutto_acquistato():
	scroll_container.visible = false
	desc_label.visible = false
	cost_label.visible = false

	name_label.visible = true
	name_label.text = "Tutti gli oggetti sono stati acquistati"


# -------------------------------------------------
# MOSTRA UN MESSAGGIO (es: “non hai abbastanza soldi”)
# -------------------------------------------------
func mostra_messaggio(messaggio: String):
	scroll_container.visible = true
	desc_label.visible = false
	cost_label.visible = false

	name_label.visible = true
	name_label.text = messaggio


# -------------------------------------------------
# CREAZIONE LISTA A SINISTRA
# -------------------------------------------------
func _crea_lista():
	for item in items:
		var b = Button.new()
		b.text = item["name"]
		b.focus_mode = Control.FOCUS_NONE
		left_panel.add_child(b)


# -------------------------------------------------
# FUNZIONE PER SALTARE ITEMS COMPRATI
# -------------------------------------------------
func trova_prossimo_indice(direzione: int) -> int:
	var new_index = selected_index

	while true:
		new_index += direzione

		if new_index < 0 or new_index >= items.size():
			break

		if not items[new_index]["purchased"]:
			return new_index

	return selected_index


func assicurati_item_selezionabile():
	if items[selected_index]["purchased"]:
		selected_index = trova_prossimo_indice(1)


# -------------------------------------------------
# INPUT DI NAVIGAZIONE
# -------------------------------------------------
func _input(event):
	if event.is_action_pressed("Move_Up"):
		selected_index = trova_prossimo_indice(-1)
		aggiorna_dettagli()
		aggiorna_evidenziazione()

	if event.is_action_pressed("Move_Down"):
		selected_index = trova_prossimo_indice(1)
		aggiorna_dettagli()
		aggiorna_evidenziazione()

	if event.is_action_pressed("Click"):
		compra_item()


# -------------------------------------------------
# DETTAGLI A DESTRA
# -------------------------------------------------
func aggiorna_dettagli():
	# Se tutto è comprato → mostra messaggio
	if tutti_acquistati():
		mostra_tutto_acquistato()
		return

	var item = items[selected_index]

	name_label.text = item["name"]
	desc_label.text = item["desc"]
	desc_label.visible = true
	cost_label.visible = true

	if item["purchased"]:
		cost_label.text = "Acquistato"
	else:
		cost_label.text = "Costo: %d" % item["cost"]


# -------------------------------------------------
# EVIDENZIAZIONE LISTA
# -------------------------------------------------
func aggiorna_evidenziazione():
	for i in range(left_panel.get_child_count()):
		var b = left_panel.get_child(i)
		var item = items[i]

		if item["purchased"]:
			b.text = "%s (Acquistato)" % item["name"]
			b.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			continue

		b.text = item["name"]

		if i == selected_index:
			b.add_theme_color_override("font_color", Color.YELLOW)
		else:
			b.add_theme_color_override("font_color", Color.WHITE)


# -------------------------------------------------
# ACQUISTO ITEM
# -------------------------------------------------
func compra_item():
	var player_money = Singleton.player.coins
	var item = items[selected_index]

	if item["purchased"]:
		return

	# SOLDI NON SUFFICIENTI → MESSAGGIO NELLA SEZIONE DESTRA
	if player_money < item["cost"]:
		mostra_messaggio("Non hai abbastanza soldi!")
		return

	# Scala i soldi e segna l'item come comprato
	player_money -= item["cost"]
	item["purchased"] = true
	print("Hai comprato: ", item["name"], " | Soldi rimasti: ", player_money)

	# Se tutto è comprato → schermata finale
	if tutti_acquistati():
		mostra_tutto_acquistato()
		return

	assicurati_item_selezionabile()
	aggiorna_dettagli()
	aggiorna_evidenziazione()
