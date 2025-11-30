extends RefCounted

# Save Manager - handles game save/load operations
# Each save is a complete JSON snapshot stored in user://saves/

const SAVES_DIR = "user://saves/"
const METADATA_FILE = "user://saves_metadata.json"

var _metadata = {}  # { "filename": { name, timestamp, playtime, last_loaded } }

func _init():
	_ensure_saves_dir()
	_load_metadata()

func _ensure_saves_dir():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("SaveManager: Created saves directory")

func _load_metadata():
	if not FileAccess.file_exists(METADATA_FILE):
		_metadata = {}
		return
	
	var file = FileAccess.open(METADATA_FILE, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(content) == OK:
			_metadata = json.data
			print("SaveManager: Loaded metadata for ", _metadata.size(), " saves")

func _save_metadata():
	var file = FileAccess.open(METADATA_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_metadata, "\t"))
		file.close()

func get_save_list() -> Array:
	# Returns array of save info, sorted by last_loaded (most recent first), then by timestamp
	var saves = []
	
	for filename in _metadata.keys():
		var info = _metadata[filename].duplicate()
		info["filename"] = filename
		saves.append(info)
	
	# Sort: last_loaded file first, then by timestamp descending
	saves.sort_custom(func(a, b):
		# If one was last loaded, it goes first
		if a.get("last_loaded", false) and not b.get("last_loaded", false):
			return true
		if b.get("last_loaded", false) and not a.get("last_loaded", false):
			return false
		# Otherwise sort by timestamp descending
		return a.get("timestamp", 0) > b.get("timestamp", 0)
	)
	
	return saves

func save_game(filename: String, game_data: Dictionary, playtime_seconds: float) -> bool:
	var save_path = SAVES_DIR + filename + ".json"
	
	# Build save data with metadata embedded
	var save_data = {
		"metadata": {
			"name": filename,
			"timestamp": Time.get_unix_time_from_system(),
			"playtime": playtime_seconds,
			"version": "1.0"
		},
		"game_data": game_data
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		
		# Update metadata
		_metadata[filename] = {
			"name": filename,
			"timestamp": save_data["metadata"]["timestamp"],
			"playtime": playtime_seconds,
			"last_loaded": true
		}
		
		# Clear last_loaded from other saves
		for other_file in _metadata.keys():
			if other_file != filename:
				_metadata[other_file]["last_loaded"] = false
		
		_save_metadata()
		print("SaveManager: Saved game to ", save_path)
		return true
	
	print("SaveManager: Failed to save game to ", save_path)
	return false

func load_game(filename: String) -> Dictionary:
	var save_path = SAVES_DIR + filename + ".json"
	
	if not FileAccess.file_exists(save_path):
		print("SaveManager: Save file not found: ", save_path)
		return {}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(content) == OK:
			var save_data = json.data
			
			# Mark as last loaded
			if _metadata.has(filename):
				for other_file in _metadata.keys():
					_metadata[other_file]["last_loaded"] = false
				_metadata[filename]["last_loaded"] = true
				_save_metadata()
			
			print("SaveManager: Loaded game from ", save_path)
			return save_data
	
	print("SaveManager: Failed to load game from ", save_path)
	return {}

func delete_save(filename: String) -> bool:
	var save_path = SAVES_DIR + filename + ".json"
	
	var dir = DirAccess.open(SAVES_DIR)
	if dir and dir.file_exists(filename + ".json"):
		dir.remove(filename + ".json")
		_metadata.erase(filename)
		_save_metadata()
		print("SaveManager: Deleted save ", filename)
		return true
	
	return false

func save_exists(filename: String) -> bool:
	return FileAccess.file_exists(SAVES_DIR + filename + ".json")

func get_current_save_name() -> String:
	for filename in _metadata.keys():
		if _metadata[filename].get("last_loaded", false):
			return filename
	return "autosave"

func format_playtime(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%d:%02d" % [minutes, secs]

func format_timestamp(unix_time: float) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%04d-%02d-%02d %02d:%02d" % [
		datetime["year"], datetime["month"], datetime["day"],
		datetime["hour"], datetime["minute"]
	]

