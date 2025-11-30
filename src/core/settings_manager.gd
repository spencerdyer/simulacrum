extends RefCounted

# Settings Manager - handles user preferences separate from game saves
# Stored in user://settings.json

const SETTINGS_PATH = "user://settings.json"

var _data = {}

# Default settings
const DEFAULTS = {
	"llm_provider": "xai",
	"llm_api_keys": {
		"xai": "",
		"openai": "",
		"gemini": "",
		"anthropic": ""
	},
	"llm_model": "",
	"npc_speculation_mode": "strict",  # "strict" or "speculative"
	"audio_volume": 1.0,
	"music_volume": 1.0
}

# Speculation mode descriptions for UI
const SPECULATION_MODES = {
	"strict": "Strict (NPCs refuse to speculate about unknowns)",
	"speculative": "Speculative (NPCs may guess with uncertainty markers)"
}

func _init():
	load_settings()

func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		_data = DEFAULTS.duplicate(true)
		save_settings()
		print("Settings: Created default settings file")
		return
	
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			_data = json.data
			# Merge with defaults to ensure new settings exist
			_merge_defaults()
			print("Settings: Loaded from ", SETTINGS_PATH)
		else:
			print("Settings: Failed to parse, using defaults")
			_data = DEFAULTS.duplicate(true)

func _merge_defaults():
	# Ensure all default keys exist
	for key in DEFAULTS.keys():
		if not _data.has(key):
			_data[key] = DEFAULTS[key]
	
	# Ensure all API key slots exist
	if _data.has("llm_api_keys"):
		for provider in DEFAULTS["llm_api_keys"].keys():
			if not _data["llm_api_keys"].has(provider):
				_data["llm_api_keys"][provider] = ""

func save_settings():
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_data, "\t"))
		file.close()
		print("Settings: Saved to ", SETTINGS_PATH)

func get_value(key: String, default = null):
	return _data.get(key, default)

func set_value(key: String, value):
	_data[key] = value
	save_settings()

# LLM-specific helpers
func get_current_provider() -> String:
	return _data.get("llm_provider", "xai")

func set_current_provider(provider: String):
	_data["llm_provider"] = provider
	save_settings()

func get_api_key(provider: String) -> String:
	var keys = _data.get("llm_api_keys", {})
	return keys.get(provider, "")

func set_api_key(provider: String, key: String):
	if not _data.has("llm_api_keys"):
		_data["llm_api_keys"] = {}
	_data["llm_api_keys"][provider] = key
	save_settings()

func get_current_api_key() -> String:
	return get_api_key(get_current_provider())

func get_current_model() -> String:
	return _data.get("llm_model", "")

func set_current_model(model: String):
	_data["llm_model"] = model
	save_settings()

# NPC Speculation Mode
func get_speculation_mode() -> String:
	return _data.get("npc_speculation_mode", "strict")

func set_speculation_mode(mode: String):
	_data["npc_speculation_mode"] = mode
	save_settings()

func is_strict_mode() -> bool:
	return get_speculation_mode() == "strict"

func get_speculation_modes() -> Dictionary:
	return SPECULATION_MODES
