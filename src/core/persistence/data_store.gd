extends RefCounted

const SAVE_PATH = "user://simulacrum_db.json"

var _data = {
	"characters": [],
	"items": [],
	"inventory": [],
	"world_locations": [],
	"npc_known_facts": [],
	"npc_memories": [],
	"conversation_history": [],
	"relationships": []
}

func _get_timestamp() -> float:
	return Time.get_unix_time_from_system()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH): 
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			var loaded_data = json.data
			# Merge all known tables
			for table_name in _data.keys():
				if table_name in loaded_data:
					_data[table_name] = loaded_data[table_name]
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

# For save/load system
func get_all_data() -> Dictionary:
	return _data.duplicate(true)  # Deep copy

func set_all_data(new_data: Dictionary):
	_data = new_data.duplicate(true)  # Deep copy
	save_data()  # Persist to working file

# Note: Arrays in Godot are passed by reference, so modifying the array returned
# by get_table will modify _data. But adding items needs append.
