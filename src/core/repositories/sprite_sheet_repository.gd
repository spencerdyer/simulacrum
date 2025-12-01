extends RefCounted

# Sprite Sheet Repository - Loads and provides access to sprite sheet configurations
# Data is loaded from res://src/data/sprite_sheets.json

const DATA_PATH = "res://src/data/sprite_sheets.json"

var _sprite_sheets: Dictionary = {}  # id -> sprite_sheet_data
var _default_sprite: String = "homestead1"

func _init():
	_load_data()

func _load_data():
	if not FileAccess.file_exists(DATA_PATH):
		push_error("SpriteSheetRepository: Data file not found: " + DATA_PATH)
		return
	
	var file = FileAccess.open(DATA_PATH, FileAccess.READ)
	if not file:
		push_error("SpriteSheetRepository: Could not open data file")
		return
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK:
		push_error("SpriteSheetRepository: JSON parse error: " + json.get_error_message())
		return
	
	var data = json.data
	
	if data.has("default_sprite"):
		_default_sprite = data["default_sprite"]
	
	if data.has("sprite_sheets"):
		for sheet in data["sprite_sheets"]:
			if sheet.has("id"):
				_sprite_sheets[sheet["id"]] = sheet
	
	print("SpriteSheetRepository: Loaded ", _sprite_sheets.size(), " sprite sheets")

func get_all() -> Array:
	return _sprite_sheets.values()

func get_all_ids() -> Array:
	return _sprite_sheets.keys()

func get_by_id(id: String) -> Dictionary:
	if _sprite_sheets.has(id):
		return _sprite_sheets[id]
	return {}

func get_default() -> Dictionary:
	return get_by_id(_default_sprite)

func get_default_id() -> String:
	return _default_sprite

# Convenience method to check if a sprite sheet exists
func exists(id: String) -> bool:
	return _sprite_sheets.has(id)

# Get sprite sheet or default if not found
func get_or_default(id: String) -> Dictionary:
	if _sprite_sheets.has(id):
		return _sprite_sheets[id]
	return get_default()

