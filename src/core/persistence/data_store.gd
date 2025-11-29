extends RefCounted

const SAVE_PATH = "user://simulacrum_db.json"

var _data = {
	"characters": [],
	"items": [],
	"inventory": []
}

func load_data():
	if not FileAccess.file_exists(SAVE_PATH): 
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			var loaded_data = json.data
			# Merge checks to ensure tables exist if file is old
			if "characters" in loaded_data: _data["characters"] = loaded_data["characters"]
			if "items" in loaded_data: _data["items"] = loaded_data["items"]
			if "inventory" in loaded_data: _data["inventory"] = loaded_data["inventory"]
			print("Database loaded.")

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_data))
		file.close()

func get_table(table_name: String) -> Array:
	if not table_name in _data:
		_data[table_name] = []
	return _data[table_name]

# Note: Arrays in Godot are passed by reference, so modifying the array returned
# by get_table will modify _data. But adding items needs append.

