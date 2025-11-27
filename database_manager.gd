extends Node

# Simulating a Database structure
# In the future, this can be replaced with actual SQLite calls.
# Structure: { "table_name": [ { row_data } ] }
var _db = {
	"characters": []
}

const SAVE_PATH = "user://simulacrum_db.json"

enum Gender { MALE, FEMALE }

func _ready():
	_load_database()
	_ensure_schema()

func _ensure_schema():
	# Ensure we have our tables
	if not "characters" in _db:
		_db["characters"] = []
		
	# Check if player exists
	var player = get_character_by_name("Hero")
	
	# If player exists but has invalid gender (from old save), fix it or recreate
	if player:
		if player.get("gender") not in ["Male", "Female"]:
			print("Migrating old character data...")
			player["gender"] = "Male" # Defaulting to Male as requested
			_save_database()
			
	if not player:
		create_character({
			"name": "Hero",
			"is_player": true,
			"gender": "Male",
			"description": "A brave adventurer seeking the truth of the Simulacrum.",
			"backstory": "Born in the void, raised by pixels.",
			"sprite_path": "res://icon.svg",
			# Stats
			"health": 100,
			"max_health": 100,
			"stamina": 50,
			"strength": 10,
			"dexterity": 12,
			"intelligence": 8,
			"charisma": 14
		})

func create_character(data: Dictionary):
	# Enforce gender enum constraints
	if "gender" in data:
		var g = data["gender"]
		if g != "Male" and g != "Female":
			push_error("Invalid gender provided: " + str(g) + ". Must be 'Male' or 'Female'. Defaulting to 'Male'.")
			data["gender"] = "Male"
	else:
		data["gender"] = "Male" # Default
		
	_db["characters"].append(data)
	_save_database()

func get_player_character():
	for char_data in _db["characters"]:
		if char_data.get("is_player", false):
			return char_data
	return null

func get_character_by_name(name: String):
	for char_data in _db["characters"]:
		if char_data.get("name") == name:
			return char_data
	return null

# Persistence
func _save_database():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_db))
		file.close()
		print("Database saved to ", SAVE_PATH)

func _load_database():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			_db = json.data
			print("Database loaded.")
		else:
			print("Failed to parse database file.")
