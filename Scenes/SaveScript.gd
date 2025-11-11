extends Node
const save_location = "user://SaveFile.json"

var contents_to_save: Dictionary = {
	"jumpCount": 0
}

func _ready() -> void:
	_load()

func _save():
	var file = FileAccess.open_encrypted_with_pass(save_location, FileAccess.WRITE, "19191919")
	file.store_var(contents_to_save.duplicate())
	file.close()
	
func _load():
	if FileAccess.file_exists(save_location):
		var file = FileAccess.open_encrypted_with_pass(save_location, FileAccess.READ, "19191919")
		var data = file.get_var()
		file.close()
		
		var save_data = data.duplicate()
		contents_to_save.jumpCount = save_data.jumpCount
