extends Node

# Simulating a Database structure
# In the future, this can be replaced with actual SQLite calls.
# Structure: { "table_name": [ { row_data } ] }
var _db = {
	"characters": [],
	"items": [],
	"inventory": []
}

const SAVE_PATH = "user://simulacrum_db.json"

enum Gender { MALE, FEMALE }

func _ready():
	_load_database()
	_ensure_schema()

func _ensure_schema():
	# Ensure we have our tables
	if not "characters" in _db: _db["characters"] = []
	if not "items" in _db: _db["items"] = []
	if not "inventory" in _db: _db["inventory"] = []
	
	# --- ITEM DEFINITIONS (Static Data for now) ---
	# Clear items to ensure fresh definitions on restart/update
	_db["items"] = [] 
	_add_item_definition("1", "Iron Helmet", "HEAD", 2, "A sturdy iron helmet.")
	_add_item_definition("2", "Leather Chest", "CHEST", 3, "Basic protection.")
	_add_item_definition("3", "Steel Sword", "RIGHT_HAND", 5, "Sharp and reliable.")
	_add_item_definition("4", "Wooden Shield", "LEFT_HAND", 2, "Better than nothing.")
	_add_item_definition("5", "Running Shoes", "LEGS", 1, "Good for sprinting.")
	_add_item_definition("6", "Health Potion", "CONSUMABLE", 0, "Restores health.")
	
	# New Items
	_add_item_definition("7", "Wizard Hat", "HEAD", 5, "A pointy hat for smart people.")
	_add_item_definition("8", "Chainmail", "CHEST", 6, "Heavy but safe.")
	_add_item_definition("9", "Plate Greaves", "LEGS", 4, "Protects the shins.")
	_add_item_definition("10", "Battle Axe", "RIGHT_HAND", 8, "Double-edged destruction.")
	_add_item_definition("11", "Magic Staff", "RIGHT_HAND", 7, "Channels arcane power.")
	_add_item_definition("12", "Dagger", "LEFT_HAND", 3, "For off-hand attacks.")
	_add_item_definition("13", "Travel Cloak", "CHEST", 1, "Keeps the rain off.")
		
	# --- PLAYER CHARACTER ---
	var player = get_character_by_name("Hero")
	
	# Migration/Correction logic
	if player:
		var dirty = false
		
		# Fix Gender
		if player.get("gender") not in ["Male", "Female"]:
			print("Migrating old character data (Gender)...")
			player["gender"] = "Male"
			dirty = true
			
		# Fix missing ID (important for inventory system)
		if not player.has("id"):
			print("Migrating old character data (ID)...")
			player["id"] = "player_1"
			dirty = true
			
		# Fix missing Equipment schema
		if not player.has("equipment"):
			print("Migrating old character data (Equipment)...")
			player["equipment"] = {
				"HEAD": null, "CHEST": null, "LEGS": null, 
				"RIGHT_HAND": null, "LEFT_HAND": null
			}
			dirty = true
			
		if dirty:
			_save_database()
			
		# Force add new items for testing if they don't exist in inventory
		_ensure_player_has_item(player["id"], "7")  # Wizard Hat
		_ensure_player_has_item(player["id"], "8")  # Chainmail
		_ensure_player_has_item(player["id"], "10") # Battle Axe
		_ensure_player_has_item(player["id"], "12") # Dagger
			
	if not player:
		var new_player = {
			"id": "player_1", # Unique ID
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
			"charisma": 14,
			# Equipment Slots (storing item_instance_ids)
			"equipment": {
				"HEAD": null,
				"CHEST": null,
				"LEGS": null,
				"RIGHT_HAND": null,
				"LEFT_HAND": null
			}
		}
		create_character(new_player)
		
		# Give initial items
		add_item_to_inventory("player_1", "1") # Helmet
		add_item_to_inventory("player_1", "3") # Sword
		add_item_to_inventory("player_1", "6") # Potion
		
		# Give new items
		add_item_to_inventory("player_1", "7")
		add_item_to_inventory("player_1", "8")
		add_item_to_inventory("player_1", "10")
		add_item_to_inventory("player_1", "12")

func _add_item_definition(id, name, type, value, desc):
	_db["items"].append({
		"id": id,
		"name": name,
		"type": type, # HEAD, CHEST, LEGS, RIGHT_HAND, LEFT_HAND, CONSUMABLE
		"value": value,
		"description": desc
	})
	
func _ensure_player_has_item(player_id, item_def_id):
	# Check if player already has an instance of this item type
	# Note: This is a simple check; in a real game you might want multiple potions,
	# but for equipment testing we just want to make sure they get one of each new thing.
	var has_it = false
	
	# Check inventory
	for item in _db["inventory"]:
		if item["owner_id"] == player_id and item["item_def_id"] == item_def_id:
			has_it = true
			break
			
	if not has_it:
		print("Debug: Giving player missing item ", item_def_id)
		add_item_to_inventory(player_id, item_def_id)

func create_character(data: Dictionary):
	if "gender" in data:
		var g = data["gender"]
		if g != "Male" and g != "Female":
			data["gender"] = "Male"
	else:
		data["gender"] = "Male"
		
	_db["characters"].append(data)
	_save_database()

# --- INVENTORY MANAGEMENT ---

func add_item_to_inventory(owner_id: String, item_def_id: String):
	var instance_id = str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)
	_db["inventory"].append({
		"instance_id": instance_id,
		"owner_id": owner_id,
		"item_def_id": item_def_id,
		"equipped": false
	})
	_save_database()

func get_player_inventory(player_id: String):
	var inventory = []
	for item in _db["inventory"]:
		if item["owner_id"] == player_id and not item["equipped"]:
			var def = get_item_definition(item["item_def_id"])
			if def:
				var full_item = item.duplicate()
				full_item.merge(def)
				inventory.append(full_item)
	return inventory

func get_player_equipment(player_id: String):
	# We look at the character record for slots
	var player = get_character_by_id(player_id)
	if not player: return {}
	
	var equipment = player.get("equipment", {})
	var result = {}
	
	for slot in equipment.keys():
		var instance_id = equipment[slot]
		if instance_id:
			var instance = get_inventory_item_by_instance_id(instance_id)
			if instance:
				var def = get_item_definition(instance["item_def_id"])
				if def:
					var full_item = instance.duplicate()
					full_item.merge(def)
					result[slot] = full_item
		else:
			result[slot] = null
			
	return result

func equip_item(player_id: String, instance_id: String, slot: String):
	var player = get_character_by_id(player_id)
	var item_instance = get_inventory_item_by_instance_id(instance_id)
	var item_def = get_item_definition(item_instance["item_def_id"])
	
	if not player or not item_instance or not item_def: return
	
	# Verify slot match
	if item_def["type"] != slot:
		print("Cannot equip ", item_def["name"], " to ", slot)
		return
		
	# Unequip current item in slot if any
	if player["equipment"][slot] != null:
		unequip_item(player_id, slot)
		
	# Equip new item
	player["equipment"][slot] = instance_id
	item_instance["equipped"] = true
	_save_database()
	print("Equipped ", item_def["name"], " to ", slot)

func unequip_item(player_id: String, slot: String):
	var player = get_character_by_id(player_id)
	var instance_id = player["equipment"].get(slot)
	
	if instance_id:
		var item_instance = get_inventory_item_by_instance_id(instance_id)
		if item_instance:
			item_instance["equipped"] = false
		
		player["equipment"][slot] = null
		_save_database()
		print("Unequipped from ", slot)

# --- HELPERS ---

func get_item_definition(def_id: String):
	for item in _db["items"]:
		if item["id"] == def_id: return item
	return null

func get_inventory_item_by_instance_id(instance_id: String):
	for item in _db["inventory"]:
		if item["instance_id"] == instance_id: return item
	return null

func get_character_by_id(id: String):
	for char_data in _db["characters"]:
		if char_data.get("id") == id: return char_data
	return null
	
func get_player_character():
	for char_data in _db["characters"]:
		if char_data.get("is_player", false): return char_data
	return null

func get_character_by_name(name: String):
	for char_data in _db["characters"]:
		if char_data.get("name") == name: return char_data
	return null

# Persistence
func _save_database():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_db))
		file.close()

func _load_database():
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			_db = json.data
			print("Database loaded.")
