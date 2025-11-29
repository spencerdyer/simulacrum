extends RefCounted

var _item_repo
var _char_repo
var _inv_repo

func _init(item_repo, char_repo, inv_repo):
	_item_repo = item_repo
	_char_repo = char_repo
	_inv_repo = inv_repo

func run():
	_load_item_definitions()
	_ensure_player()
	_ensure_merchant()

func _load_item_definitions():
	_item_repo.clear_definitions()
	# In a real app, this might load from a JSON file or CSV resource
	_item_repo.add_definition("1", "Iron Helmet", "HEAD", 2, "A sturdy iron helmet.")
	_item_repo.add_definition("2", "Leather Chest", "CHEST", 3, "Basic protection.")
	_item_repo.add_definition("3", "Steel Sword", "HAND", 5, "Sharp and reliable.")
	_item_repo.add_definition("4", "Wooden Shield", "HAND", 2, "Better than nothing.")
	_item_repo.add_definition("5", "Running Shoes", "LEGS", 1, "Good for sprinting.")
	_item_repo.add_definition("6", "Health Potion", "CONSUMABLE", 0, "Restores health.")
	_item_repo.add_definition("7", "Wizard Hat", "HEAD", 5, "A pointy hat for smart people.")
	_item_repo.add_definition("8", "Chainmail", "CHEST", 6, "Heavy but safe.")
	_item_repo.add_definition("9", "Plate Greaves", "LEGS", 4, "Protects the shins.")
	_item_repo.add_definition("10", "Battle Axe", "HAND", 8, "Double-edged destruction.")
	_item_repo.add_definition("11", "Magic Staff", "HAND", 7, "Channels arcane power.")
	_item_repo.add_definition("12", "Dagger", "HAND", 3, "For off-hand attacks.")
	_item_repo.add_definition("13", "Travel Cloak", "CHEST", 1, "Keeps the rain off.")
	_item_repo.add_definition("14", "Leather Hood", "HEAD", 2, "Sneaky and quiet.")
	_item_repo.add_definition("15", "Golden Crown", "HEAD", 10, "Fit for a king.")
	_item_repo.add_definition("16", "Silk Robe", "CHEST", 2, "Light and breathable.")
	_item_repo.add_definition("17", "Steel Plate", "CHEST", 8, "Maximum protection.")
	_item_repo.add_definition("18", "Iron Spear", "HAND", 6, "Long reach.")

func _ensure_player():
	var player = _char_repo.get_player()
	
	if player:
		# Migration logic
		var dirty = false
		if player.get("gender") not in ["Male", "Female"]:
			player["gender"] = "Male"
			dirty = true
		if not player.has("id"):
			player["id"] = "player_1"
			dirty = true
		if not player.has("equipment"):
			player["equipment"] = { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null }
			dirty = true
			
		if dirty: _char_repo.update(player)
		
		# Add all items for testing
		var all_defs = _item_repo.get_all()
		for def in all_defs:
			_ensure_item(player["id"], def["id"])
			
	else:
		# Create new
		var new_player = {
			"id": "player_1",
			"name": "Hero",
			"is_player": true,
			"gender": "Male",
			"description": "A brave adventurer seeking the truth of the Simulacrum.",
			"backstory": "Born in the void, raised by pixels.",
			"sprite_path": "res://src/assets/sprites/icon.svg",
			"health": 100, "max_health": 100, "stamina": 50,
			"strength": 10, "dexterity": 12, "intelligence": 8, "charisma": 14,
			"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null }
		}
		_char_repo.create(new_player)
		
		var all_defs = _item_repo.get_all()
		for def in all_defs:
			_inv_repo.add_item("player_1", def["id"])

func _ensure_merchant():
	var merchant = _char_repo.get_by_id("npc_merchant_1")
	if not merchant:
		var new_npc = {
			"id": "npc_merchant_1",
			"name": "Merchant",
			"is_player": false,
			"gender": "Male",
			"description": "A friendly trader.",
			"backstory": "Has wares if you have coin.",
			"sprite_path": "res://src/assets/sprites/icon.svg",
			"health": 100, "max_health": 100, "stamina": 50,
			"strength": 10, "dexterity": 10, "intelligence": 10, "charisma": 10,
			"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null }
		}
		_char_repo.create(new_npc)
		
		# Stock the merchant
		_inv_repo.add_item("npc_merchant_1", "6") # Potion
		_inv_repo.add_item("npc_merchant_1", "6") # Potion
		_inv_repo.add_item("npc_merchant_1", "6") # Potion
		_inv_repo.add_item("npc_merchant_1", "1") # Helmet
		_inv_repo.add_item("npc_merchant_1", "3") # Sword

func _ensure_item(owner_id, def_id):
	var items = _inv_repo.get_by_owner(owner_id, true) # include equipped
	for item in items:
		# Check item_def_id, not id
		if item.get("item_def_id") == def_id: return
	_inv_repo.add_item(owner_id, def_id)
