extends RefCounted

var _item_repo
var _char_repo
var _inv_repo
var _world_loc_repo
var _npc_facts_repo

func _init(item_repo, char_repo, inv_repo, world_loc_repo = null, npc_facts_repo = null):
	_item_repo = item_repo
	_char_repo = char_repo
	_inv_repo = inv_repo
	_world_loc_repo = world_loc_repo
	_npc_facts_repo = npc_facts_repo

func run():
	_load_item_definitions()
	_ensure_player()
	_load_world_locations()
	_load_town_npcs()
	_distribute_world_knowledge()

# ============================================================================
# ITEM DEFINITIONS
# ============================================================================
func _load_item_definitions():
	_item_repo.clear_definitions()
	
	# === WEAPONS ===
	_item_repo.add_definition("weapon_iron_sword", "Iron Sword", "HAND", 5, "A reliable iron blade, standard issue for town guards.")
	_item_repo.add_definition("weapon_steel_sword", "Steel Sword", "HAND", 8, "Finely crafted steel, holds a sharp edge.")
	_item_repo.add_definition("weapon_dagger", "Dagger", "HAND", 3, "Small but deadly in close quarters.")
	_item_repo.add_definition("weapon_battle_axe", "Battle Axe", "HAND", 10, "Heavy two-handed axe for cleaving foes.")
	_item_repo.add_definition("weapon_mace", "Iron Mace", "HAND", 6, "Blunt force trauma, effective against armor.")
	_item_repo.add_definition("weapon_spear", "Iron Spear", "HAND", 7, "Long reach keeps enemies at bay.")
	_item_repo.add_definition("weapon_staff", "Wooden Staff", "HAND", 2, "A simple walking staff, can be used defensively.")
	
	# === ARMOR - HEAD ===
	_item_repo.add_definition("armor_iron_helm", "Iron Helmet", "HEAD", 4, "Sturdy protection for the head.")
	_item_repo.add_definition("armor_leather_cap", "Leather Cap", "HEAD", 2, "Light head protection, doesn't restrict vision.")
	_item_repo.add_definition("armor_steel_helm", "Steel Helmet", "HEAD", 6, "Superior craftsmanship, full face protection.")
	
	# === ARMOR - CHEST ===
	_item_repo.add_definition("armor_leather_vest", "Leather Vest", "CHEST", 3, "Basic torso protection, allows free movement.")
	_item_repo.add_definition("armor_chainmail", "Chainmail", "CHEST", 6, "Interlocking rings deflect slashing attacks.")
	_item_repo.add_definition("armor_steel_plate", "Steel Breastplate", "CHEST", 9, "Heavy plate armor for serious combat.")
	_item_repo.add_definition("armor_cloth_robe", "Cloth Robe", "CHEST", 1, "Simple garment, no real protection.")
	
	# === ARMOR - LEGS ===
	_item_repo.add_definition("armor_leather_pants", "Leather Pants", "LEGS", 2, "Durable leg protection.")
	_item_repo.add_definition("armor_chain_leggings", "Chain Leggings", "LEGS", 4, "Metal rings protect the legs.")
	_item_repo.add_definition("armor_plate_greaves", "Plate Greaves", "LEGS", 6, "Heavy leg armor.")
	
	# === SHIELDS ===
	_item_repo.add_definition("shield_wooden", "Wooden Shield", "HAND", 3, "Basic wooden shield, splinters easily.")
	_item_repo.add_definition("shield_iron", "Iron Shield", "HAND", 5, "Solid iron shield, heavy but reliable.")
	_item_repo.add_definition("shield_steel", "Steel Kite Shield", "HAND", 7, "Large shield covering most of the body.")
	
	# === CONSUMABLES ===
	_item_repo.add_definition("potion_health_small", "Minor Health Potion", "CONSUMABLE", 0, "Restores a small amount of health.")
	_item_repo.add_definition("potion_health_medium", "Health Potion", "CONSUMABLE", 0, "Restores a moderate amount of health.")
	_item_repo.add_definition("potion_stamina", "Stamina Potion", "CONSUMABLE", 0, "Restores stamina for continued exertion.")
	
	# === FOOD & DRINK (Tavern goods) ===
	_item_repo.add_definition("food_bread", "Loaf of Bread", "CONSUMABLE", 0, "Fresh baked bread from the local baker.")
	_item_repo.add_definition("food_cheese", "Wheel of Cheese", "CONSUMABLE", 0, "Aged cheese with a sharp flavor.")
	_item_repo.add_definition("food_meat_cooked", "Cooked Meat", "CONSUMABLE", 0, "Roasted meat, still warm.")
	_item_repo.add_definition("food_stew", "Hearty Stew", "CONSUMABLE", 0, "A bowl of thick vegetable and meat stew.")
	_item_repo.add_definition("drink_ale", "Mug of Ale", "CONSUMABLE", 0, "Local brew, strong and bitter.")
	_item_repo.add_definition("drink_wine", "Bottle of Wine", "CONSUMABLE", 0, "Red wine from the southern vineyards.")
	_item_repo.add_definition("drink_mead", "Honey Mead", "CONSUMABLE", 0, "Sweet alcoholic drink made with honey.")
	_item_repo.add_definition("drink_water", "Flask of Water", "CONSUMABLE", 0, "Clean drinking water.")
	
	# === GENERAL GOODS ===
	_item_repo.add_definition("misc_rope", "Coil of Rope", "MISC", 0, "50 feet of sturdy hemp rope.")
	_item_repo.add_definition("misc_torch", "Torch", "MISC", 0, "Provides light in dark places.")
	_item_repo.add_definition("misc_lantern", "Oil Lantern", "MISC", 0, "Longer lasting light source.")
	_item_repo.add_definition("misc_lockpick", "Lockpick Set", "MISC", 0, "Tools for opening locks... quietly.")
	_item_repo.add_definition("misc_bandage", "Bandages", "MISC", 0, "Clean cloth for binding wounds.")
	_item_repo.add_definition("misc_flint", "Flint and Steel", "MISC", 0, "For starting fires.")
	_item_repo.add_definition("misc_map", "Local Map", "MISC", 0, "A hand-drawn map of the surrounding area.")

# ============================================================================
# PLAYER CHARACTER
# ============================================================================
func _ensure_player():
	var player = _char_repo.get_player()
	
	if player:
		# Migration: ensure all fields exist
		var dirty = false
		if not player.has("id"):
			player["id"] = "player_1"
			dirty = true
		if not player.has("equipment"):
			player["equipment"] = { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null }
			dirty = true
		if dirty: _char_repo.update(player)
	else:
		var new_player = {
			"id": "player_1",
			"name": "Adventurer",
			"is_player": true,
			"gender": "Male",
			"description": "A wandering traveler who recently arrived in Willowbrook.",
		"backstory": "You came to this village seeking answers about strange dreams that have plagued you since childhood. The dreams speak of a 'Simulacrum' - a word that echoes in your mind but whose meaning eludes you.",
		"sprite": "male1",
			"height": "5'10\"",
			"weight": "165 lbs",
			"age": 25,
			"eye_color": "Green",
			"hair_color": "Brown",
			"health": 100, "max_health": 100, "stamina": 50,
			"strength": 12, "dexterity": 14, "intelligence": 10, "charisma": 11,
			"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null }
		}
		_char_repo.create(new_player)
		
		# Give player starting gear
		_inv_repo.add_item("player_1", "weapon_iron_sword")
		_inv_repo.add_item("player_1", "armor_leather_vest")
		_inv_repo.add_item("player_1", "potion_health_small")
		_inv_repo.add_item("player_1", "potion_health_small")
		_inv_repo.add_item("player_1", "food_bread")
		_inv_repo.add_item("player_1", "misc_torch")

# ============================================================================
# WORLD LOCATIONS
# ============================================================================
func _load_world_locations():
	if not _world_loc_repo: return
	
	# Check if already loaded
	if _world_loc_repo.get_all().size() > 0: return
	
	# THE VILLAGE OF WILLOWBROOK
	_world_loc_repo.create({
		"id": "loc_willowbrook",
		"name": "Willowbrook Village",
		"type": "settlement",
		"parent_id": "",
		"description": "A small, peaceful village nestled in a valley surrounded by gentle hills and ancient willow trees. The village has about 50 residents who make their living through farming, crafting, and trade. A cobblestone path runs through the center of town, connecting the various buildings.",
		"features": ["cobblestone_path", "willow_trees", "central_well", "notice_board"]
	})
	
	# THE RUSTY TANKARD (Tavern)
	_world_loc_repo.create({
		"id": "loc_tavern",
		"name": "The Rusty Tankard",
		"type": "tavern",
		"parent_id": "loc_willowbrook",
		"description": "The village's only tavern, a two-story wooden building with a creaky sign depicting a dented tankard. The interior is warm and smoky, with a large fireplace, several wooden tables, and a long bar. Upstairs are a few rooms for travelers.",
		"features": ["fireplace", "bar_counter", "wooden_tables", "guest_rooms_upstairs"]
	})
	
	# CHURCH OF THE DAWN
	_world_loc_repo.create({
		"id": "loc_church",
		"name": "Church of the Dawn",
		"type": "church",
		"parent_id": "loc_willowbrook",
		"description": "A modest stone chapel with a small bell tower. Stained glass windows depict scenes of sunrise and hope. The interior has wooden pews and a simple altar adorned with candles and dried flowers.",
		"features": ["bell_tower", "stained_glass", "altar", "pews", "cemetery_behind"]
	})
	
	# IRON & STEEL (Blacksmith)
	_world_loc_repo.create({
		"id": "loc_blacksmith",
		"name": "Iron & Steel",
		"type": "shop",
		"parent_id": "loc_willowbrook",
		"description": "The village blacksmith shop, easily identified by the constant ring of hammer on anvil and the smoke rising from the forge. Weapons and armor hang on display racks, and the heat from the forge keeps the shop warm even in winter.",
		"features": ["forge", "anvil", "weapon_racks", "armor_stands", "tool_storage"]
	})
	
	# ODDS & ENDS (General Store)
	_world_loc_repo.create({
		"id": "loc_general_store",
		"name": "Odds & Ends",
		"type": "shop",
		"parent_id": "loc_willowbrook",
		"description": "A cluttered but organized general store selling everything from rope to rations. Shelves line every wall, packed with goods. The shopkeeper knows exactly where everything is despite the apparent chaos.",
		"features": ["shelves", "counter", "storage_room", "variety_of_goods"]
	})
	
	# VILLAGE HOUSES (locked)
	_world_loc_repo.create({
		"id": "loc_house_mayor",
		"name": "Mayor's House",
		"type": "house",
		"parent_id": "loc_willowbrook",
		"description": "The largest house in the village, belonging to Mayor Aldric. It has a well-maintained garden and a small study.",
		"features": ["garden", "study", "guest_room"]
	})
	
	_world_loc_repo.create({
		"id": "loc_house_blacksmith",
		"name": "Blacksmith's Cottage",
		"type": "house",
		"parent_id": "loc_willowbrook",
		"description": "A small cottage behind the blacksmith shop where Greta and her apprentice live.",
		"features": ["simple_furnishings", "tool_shed"]
	})
	
	_world_loc_repo.create({
		"id": "loc_house_herbalist",
		"name": "Herbalist's Hut",
		"type": "house",
		"parent_id": "loc_willowbrook",
		"description": "A small hut on the edge of the village, surrounded by herb gardens. Strange smells often waft from within.",
		"features": ["herb_garden", "drying_racks", "potion_supplies"]
	})

# ============================================================================
# TOWN NPCs - 10 Total
# ============================================================================
func _load_town_npcs():
	_create_npc_tavern_keeper()
	_create_npc_tavern_patron_1()
	_create_npc_tavern_patron_2()
	_create_npc_tavern_patron_3()
	_create_npc_priest()
	_create_npc_blacksmith()
	_create_npc_general_store()
	_create_npc_mayor()
	_create_npc_guard()
	_create_npc_herbalist()

func _create_npc_tavern_keeper():
	var npc_id = "npc_tavern_keeper"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Bram Thornwood",
		"is_player": false,
		"gender": "Male",
		"description": "A burly man in his late 40s with a thick brown beard streaked with gray. He has kind eyes that crinkle when he laughs, which is often. His arms are covered in old burn scars from years of working near the kitchen fires.",
		"backstory": "Bram was once a soldier in the King's army, serving for fifteen years before a leg injury ended his military career. He used his savings to buy The Rusty Tankard twenty years ago and has run it ever since. He knows everyone in town and hears all the gossip. His wife passed away five years ago, and he now runs the tavern alone with occasional help from village youngsters.",
		"daily_routine": "Wakes at dawn to prepare breakfast for any guests. Spends mornings cleaning and restocking. Opens the tavern at noon and works until late evening, serving drinks and food while chatting with patrons.",
		"occupation": "Tavern Keeper",
		"location_id": "loc_tavern",
		"interesting_fact": "Bram once saved a noble's life during a bandit attack, and was offered a knighthood, but turned it down because he 'couldn't stand all that bowing and scraping.'",
		"sprite": "male2",
		"height": "6'1\"",
		"weight": "220 lbs",
		"age": 48,
		"eye_color": "Brown",
		"hair_color": "Brown with gray streaks",
		"health": 100, "max_health": 100, "stamina": 40,
		"strength": 14, "dexterity": 8, "intelligence": 10, "charisma": 15,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": true
	})
	
	# Stock tavern inventory
	_inv_repo.add_item(npc_id, "drink_ale")
	_inv_repo.add_item(npc_id, "drink_ale")
	_inv_repo.add_item(npc_id, "drink_ale")
	_inv_repo.add_item(npc_id, "drink_wine")
	_inv_repo.add_item(npc_id, "drink_mead")
	_inv_repo.add_item(npc_id, "food_stew")
	_inv_repo.add_item(npc_id, "food_stew")
	_inv_repo.add_item(npc_id, "food_bread")
	_inv_repo.add_item(npc_id, "food_bread")
	_inv_repo.add_item(npc_id, "food_cheese")
	_inv_repo.add_item(npc_id, "food_meat_cooked")

func _create_npc_tavern_patron_1():
	var npc_id = "npc_patron_farmer"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Old Henrick",
		"is_player": false,
		"gender": "Male",
		"description": "A weathered old farmer with sun-darkened skin and calloused hands. He walks with a slight limp and always wears the same patched overalls. His wispy white hair barely covers his spotted scalp.",
		"backstory": "Henrick has farmed the eastern fields for over sixty years, just as his father and grandfather did before him. He's seen three kings come and go, and claims to have once met a real wizard who passed through town decades ago. His wife died in childbirth along with the baby, and he never remarried. He spends most evenings at the tavern, nursing a single ale and telling stories.",
		"daily_routine": "Works his small vegetable plot in the morning, naps in the afternoon, then walks to the tavern at sunset where he stays until closing time.",
		"occupation": "Retired Farmer",
		"location_id": "loc_tavern",
		"interesting_fact": "Henrick claims he once found a golden coin in his field that was so old the face on it had worn completely smooth. He kept it for years before trading it to a passing merchant for medicine when he fell ill.",
		"sprite": "homestead1",
		"height": "5'6\"",
		"weight": "140 lbs",
		"age": 78,
		"eye_color": "Pale Blue",
		"hair_color": "White",
		"health": 60, "max_health": 60, "stamina": 20,
		"strength": 6, "dexterity": 5, "intelligence": 11, "charisma": 12,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": false
	})

func _create_npc_tavern_patron_2():
	var npc_id = "npc_patron_hunter"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Sera Nightbow",
		"is_player": false,
		"gender": "Female",
		"description": "A lean woman in her early 30s with sharp features and observant green eyes. She wears practical hunting leathers and keeps her black hair tied back in a tight braid. A long scar runs across her left cheek.",
		"backstory": "Sera arrived in Willowbrook eight years ago and never explained where she came from. She makes her living hunting game in the surrounding forests and selling pelts and meat. She's quiet and keeps to herself, but is known to be reliable and honest in her dealings. Some whisper she's running from something in her past.",
		"daily_routine": "Leaves before dawn to check her traps and hunt. Returns in the late afternoon to sell her catch. Visits the tavern in the evening for a quiet meal, always sitting with her back to the wall.",
		"occupation": "Hunter",
		"location_id": "loc_tavern",
		"interesting_fact": "Sera once tracked a wounded wolf for three days straight without rest, finally finding it had led her to its den where its pups were starving. She killed the wolf mercifully and raised the pups, though they've since returned to the wild.",
		"sprite": "female2",
		"height": "5'8\"",
		"weight": "135 lbs",
		"age": 32,
		"eye_color": "Green",
		"hair_color": "Black",
		"health": 90, "max_health": 90, "stamina": 60,
		"strength": 11, "dexterity": 16, "intelligence": 12, "charisma": 8,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": false
	})

func _create_npc_tavern_patron_3():
	var npc_id = "npc_patron_bard"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Pip Merryweather",
		"is_player": false,
		"gender": "Male",
		"description": "A cheerful young halfling with curly auburn hair and bright hazel eyes that sparkle with mischief. He's barely four feet tall but makes up for it with an enormous personality. He always carries a well-worn lute.",
		"backstory": "Pip is a traveling bard who arrived in Willowbrook two months ago and decided to stay 'just for the winter.' He performs at the tavern most nights in exchange for room and board. He claims to have traveled to dozens of cities and performed for minor nobility, though his stories tend to grow more elaborate with each telling.",
		"daily_routine": "Sleeps until noon, spends afternoons composing songs or practicing, then performs at the tavern from evening until the last patron leaves.",
		"occupation": "Bard",
		"location_id": "loc_tavern",
		"interesting_fact": "Pip's lute once belonged to a famous bard named Melodia Silverstrike. He won it in a card game, though he insists the previous owner 'wanted him to have it' after hearing him play.",
		"sprite": "male3",
		"height": "3'10\"",
		"weight": "65 lbs",
		"age": 28,
		"eye_color": "Hazel",
		"hair_color": "Auburn",
		"health": 70, "max_health": 70, "stamina": 45,
		"strength": 6, "dexterity": 14, "intelligence": 13, "charisma": 17,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": false
	})

func _create_npc_priest():
	var npc_id = "npc_priest"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Father Aldous",
		"is_player": false,
		"gender": "Male",
		"description": "A thin, elderly man with a kind face and gentle demeanor. He wears simple gray robes and a wooden sun pendant. His hands shake slightly with age, and his voice is soft but carries well in the church's acoustics.",
		"backstory": "Father Aldous has served the Church of the Dawn in Willowbrook for over thirty years. He came here as a young priest seeking a quiet life of service after witnessing too much suffering in the city temples. He tends to the spiritual needs of the village, performs marriages and funerals, and maintains the small cemetery behind the church.",
		"daily_routine": "Rises at dawn for morning prayers, tends the church and cemetery during the day, holds evening services at sunset, and spends nights in quiet contemplation or reading ancient texts.",
		"occupation": "Priest",
		"location_id": "loc_church",
		"interesting_fact": "Father Aldous once performed an exorcism on a possessed child when he was younger. He never speaks of it, but sometimes wakes from nightmares calling out in a language no one in the village understands.",
		"sprite": "homestead3",
		"height": "5'7\"",
		"weight": "130 lbs",
		"age": 67,
		"eye_color": "Gray",
		"hair_color": "White",
		"health": 50, "max_health": 50, "stamina": 25,
		"strength": 5, "dexterity": 6, "intelligence": 15, "charisma": 14,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": false
	})

func _create_npc_blacksmith():
	var npc_id = "npc_blacksmith"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Greta Ironhand",
		"is_player": false,
		"gender": "Female",
		"description": "A powerfully built woman in her late 30s with short-cropped red hair and arms like tree trunks. Her face is marked by small burn scars, and her hands are rough as leather. She speaks bluntly and has no patience for fools.",
		"backstory": "Greta learned smithing from her father, who learned from his father. When her father died, she took over the forge despite some villagers' initial skepticism about a woman blacksmith. She silenced the doubters by producing the finest weapons and tools the village had ever seen. She's never married, claiming the forge is her only true love.",
		"daily_routine": "Starts the forge at dawn and works until midday. Takes a break for lunch, then works again until dusk. Spends evenings maintaining her tools or occasionally visiting the tavern for a single drink.",
		"occupation": "Blacksmith",
		"location_id": "loc_blacksmith",
		"interesting_fact": "Greta once forged a sword for a knight who later became famous for slaying a dragon. She keeps a dragon scale the knight sent her as thanks, mounted above her forge.",
		"sprite": "female1",
		"height": "5'9\"",
		"weight": "175 lbs",
		"age": 38,
		"eye_color": "Brown",
		"hair_color": "Red",
		"health": 110, "max_health": 110, "stamina": 55,
		"strength": 16, "dexterity": 12, "intelligence": 11, "charisma": 9,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": true
	})
	
	# Stock blacksmith inventory
	_inv_repo.add_item(npc_id, "weapon_iron_sword")
	_inv_repo.add_item(npc_id, "weapon_steel_sword")
	_inv_repo.add_item(npc_id, "weapon_dagger")
	_inv_repo.add_item(npc_id, "weapon_mace")
	_inv_repo.add_item(npc_id, "weapon_spear")
	_inv_repo.add_item(npc_id, "armor_iron_helm")
	_inv_repo.add_item(npc_id, "armor_steel_helm")
	_inv_repo.add_item(npc_id, "armor_chainmail")
	_inv_repo.add_item(npc_id, "armor_steel_plate")
	_inv_repo.add_item(npc_id, "armor_chain_leggings")
	_inv_repo.add_item(npc_id, "armor_plate_greaves")
	_inv_repo.add_item(npc_id, "shield_iron")
	_inv_repo.add_item(npc_id, "shield_steel")

func _create_npc_general_store():
	var npc_id = "npc_merchant_1"  # Keep original ID for compatibility
	var existing = _char_repo.get_by_id(npc_id)
	
	if existing:
		# Update existing merchant with new data
		existing["name"] = "Milo Copperworth"
		existing["description"] = "A portly middle-aged man with thinning hair and spectacles perched on his nose. He's always smiling and rubbing his hands together. His clothes are neat but worn, and he wears an apron with many pockets."
		existing["backstory"] = "Milo inherited Odds & Ends from his uncle ten years ago. Before that, he was an accountant in the capital city, but found the work soul-crushing. He loves haggling and takes genuine pleasure in finding exactly what a customer needs, even if it's buried under a pile of other goods."
		existing["daily_routine"] = "Opens shop at sunrise, organizes inventory obsessively throughout the day, closes at sunset, then spends evenings doing bookkeeping by candlelight."
		existing["occupation"] = "Shopkeeper"
		existing["location_id"] = "loc_general_store"
		existing["interesting_fact"] = "Milo can identify the origin of almost any trade good by smell alone. He claims this skill saved him from buying a shipment of poisoned grain once."
		existing["height"] = "5'5\""
		existing["weight"] = "190 lbs"
		existing["age"] = 45
		existing["eye_color"] = "Brown"
		existing["hair_color"] = "Brown, thinning"
		existing["sprite"] = "homestead2"
		existing["can_trade"] = true
		_char_repo.update(existing)
	else:
		_char_repo.create({
			"id": npc_id,
			"name": "Milo Copperworth",
			"is_player": false,
			"gender": "Male",
			"description": "A portly middle-aged man with thinning hair and spectacles perched on his nose. He's always smiling and rubbing his hands together. His clothes are neat but worn, and he wears an apron with many pockets.",
			"backstory": "Milo inherited Odds & Ends from his uncle ten years ago. Before that, he was an accountant in the capital city, but found the work soul-crushing. He loves haggling and takes genuine pleasure in finding exactly what a customer needs, even if it's buried under a pile of other goods.",
			"daily_routine": "Opens shop at sunrise, organizes inventory obsessively throughout the day, closes at sunset, then spends evenings doing bookkeeping by candlelight.",
			"occupation": "Shopkeeper",
			"location_id": "loc_general_store",
			"interesting_fact": "Milo can identify the origin of almost any trade good by smell alone. He claims this skill saved him from buying a shipment of poisoned grain once.",
			"sprite": "homestead2",
			"height": "5'5\"",
			"weight": "190 lbs",
			"age": 45,
			"eye_color": "Brown",
			"hair_color": "Brown, thinning",
			"health": 80, "max_health": 80, "stamina": 35,
			"strength": 8, "dexterity": 10, "intelligence": 14, "charisma": 13,
			"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
			"can_trade": true
		})
	
	# Clear and restock inventory
	_inv_repo.clear_owner_inventory(npc_id)
	
	# Stock general store
	_inv_repo.add_item(npc_id, "misc_rope")
	_inv_repo.add_item(npc_id, "misc_rope")
	_inv_repo.add_item(npc_id, "misc_torch")
	_inv_repo.add_item(npc_id, "misc_torch")
	_inv_repo.add_item(npc_id, "misc_torch")
	_inv_repo.add_item(npc_id, "misc_lantern")
	_inv_repo.add_item(npc_id, "misc_lockpick")
	_inv_repo.add_item(npc_id, "misc_bandage")
	_inv_repo.add_item(npc_id, "misc_bandage")
	_inv_repo.add_item(npc_id, "misc_flint")
	_inv_repo.add_item(npc_id, "misc_map")
	_inv_repo.add_item(npc_id, "drink_water")
	_inv_repo.add_item(npc_id, "drink_water")
	_inv_repo.add_item(npc_id, "food_bread")
	_inv_repo.add_item(npc_id, "food_cheese")
	_inv_repo.add_item(npc_id, "armor_leather_vest")
	_inv_repo.add_item(npc_id, "armor_leather_cap")
	_inv_repo.add_item(npc_id, "armor_leather_pants")
	_inv_repo.add_item(npc_id, "potion_health_small")
	_inv_repo.add_item(npc_id, "potion_health_small")
	_inv_repo.add_item(npc_id, "potion_health_medium")

func _create_npc_mayor():
	var npc_id = "npc_mayor"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Mayor Aldric Bramwell",
		"is_player": false,
		"gender": "Male",
		"description": "A distinguished man in his early 50s with silver-streaked dark hair and a neatly trimmed beard. He dresses well but not ostentatiously, favoring practical clothing in dark colors. His posture is straight and his gaze is direct.",
		"backstory": "Aldric's family has lived in Willowbrook for generations. He became mayor fifteen years ago after the previous mayor died without an heir. He takes his responsibilities seriously, perhaps too seriously - he's known for working late into the night on village matters. His wife lives in the capital with their grown children, visiting only occasionally.",
		"daily_routine": "Holds morning meetings with villagers who have concerns, handles administrative work during the day, makes rounds through the village in the afternoon, and works on correspondence in the evening.",
		"occupation": "Mayor",
		"location_id": "loc_house_mayor",
		"interesting_fact": "Aldric once turned down an offer to become a minor noble in the capital, choosing to remain in Willowbrook. He's never explained why, but some say it had to do with a promise he made to his dying father.",
		"sprite": "homestead4",
		"height": "5'11\"",
		"weight": "170 lbs",
		"age": 52,
		"eye_color": "Blue",
		"hair_color": "Dark with silver streaks",
		"health": 85, "max_health": 85, "stamina": 40,
		"strength": 9, "dexterity": 9, "intelligence": 15, "charisma": 16,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": false
	})

func _create_npc_guard():
	var npc_id = "npc_guard"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Thomas 'Tom' Oakheart",
		"is_player": false,
		"gender": "Male",
		"description": "A young man in his mid-20s with an earnest face and broad shoulders. He wears a simple guard's uniform - leather armor with the village crest - and carries a spear. His blonde hair is always slightly disheveled despite his best efforts.",
		"backstory": "Tom is the only official guard in Willowbrook, a position he takes very seriously despite the village's peaceful nature. He grew up here, the son of a carpenter, and volunteered for the guard position three years ago. He dreams of one day becoming a knight, though he's never left the village.",
		"daily_routine": "Patrols the village perimeter at dawn and dusk, checks on the various buildings during the day, and often stands watch near the village entrance. Eats dinner at the tavern most nights.",
		"occupation": "Village Guard",
		"location_id": "loc_willowbrook",
		"interesting_fact": "Tom once single-handedly chased off a group of bandits who were scouting the village. In reality, there were only two of them and they ran the moment they saw him, but the story has grown with each retelling.",
		"sprite": "male1",
		"height": "6'0\"",
		"weight": "185 lbs",
		"age": 24,
		"eye_color": "Blue",
		"hair_color": "Blonde",
		"health": 100, "max_health": 100, "stamina": 50,
		"strength": 14, "dexterity": 12, "intelligence": 9, "charisma": 11,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": false
	})

func _create_npc_herbalist():
	var npc_id = "npc_herbalist"
	if _char_repo.get_by_id(npc_id): return
	
	_char_repo.create({
		"id": npc_id,
		"name": "Esme Willowmere",
		"is_player": false,
		"gender": "Female",
		"description": "An eccentric woman of indeterminate age - she could be 40 or 70. Wild gray-streaked hair frames a face with sharp, knowing eyes. She wears layers of colorful shawls and always smells faintly of herbs and something else... something harder to identify.",
		"backstory": "Esme appeared in Willowbrook about twenty years ago and simply... stayed. No one knows where she came from. She lives on the edge of the village in a small hut surrounded by herb gardens. Some villagers are wary of her, whispering about witchcraft, but most appreciate her healing remedies and potions.",
		"daily_routine": "Tends her herb garden at dawn, forages in the nearby woods during the day, brews potions and remedies in the evening, and is said to walk the village at night, though no one can confirm this.",
		"occupation": "Herbalist",
		"location_id": "loc_house_herbalist",
		"interesting_fact": "Esme sometimes speaks to people by name before being introduced to them. When asked how she knows, she just smiles mysteriously and says 'the willows whisper.'",
		"sprite": "female3",
		"height": "5'4\"",
		"weight": "115 lbs",
		"age": 55,
		"eye_color": "Green with gold flecks",
		"hair_color": "Gray with dark streaks",
		"health": 65, "max_health": 65, "stamina": 35,
		"strength": 6, "dexterity": 10, "intelligence": 17, "charisma": 12,
		"equipment": { "HEAD": null, "CHEST": null, "LEGS": null, "RIGHT_HAND": null, "LEFT_HAND": null },
		"can_trade": true
	})
	
	# Stock herbalist inventory
	_inv_repo.add_item(npc_id, "potion_health_small")
	_inv_repo.add_item(npc_id, "potion_health_small")
	_inv_repo.add_item(npc_id, "potion_health_small")
	_inv_repo.add_item(npc_id, "potion_health_medium")
	_inv_repo.add_item(npc_id, "potion_health_medium")
	_inv_repo.add_item(npc_id, "potion_stamina")
	_inv_repo.add_item(npc_id, "potion_stamina")
	_inv_repo.add_item(npc_id, "misc_bandage")
	_inv_repo.add_item(npc_id, "misc_bandage")

# ============================================================================
# DISTRIBUTE WORLD KNOWLEDGE TO NPCs
# ============================================================================
func _distribute_world_knowledge():
	if not _npc_facts_repo: return
	
	# Check if facts already exist
	if _npc_facts_repo.get_all().size() > 0: return
	
	# All NPCs should know basic village info
	var all_npcs = ["npc_tavern_keeper", "npc_patron_farmer", "npc_patron_hunter", "npc_patron_bard", 
					"npc_priest", "npc_blacksmith", "npc_merchant_1", "npc_mayor", "npc_guard", "npc_herbalist"]
	
	var common_facts = [
		{"type": "location", "content": "Willowbrook is a small village of about 50 people, nestled in a valley surrounded by hills and willow trees."},
		{"type": "location", "content": "The Rusty Tankard is the village tavern, run by Bram Thornwood. It's the social center of the village."},
		{"type": "location", "content": "The Church of the Dawn is the village chapel, tended by Father Aldous."},
		{"type": "location", "content": "Iron & Steel is the blacksmith shop, run by Greta Ironhand."},
		{"type": "location", "content": "Odds & Ends is the general store, run by Milo Copperworth."},
		{"type": "npc", "content": "Mayor Aldric Bramwell has led the village for fifteen years."},
		{"type": "npc", "content": "Tom Oakheart is the village's only guard."},
		{"type": "npc", "content": "Esme Willowmere is the village herbalist who lives on the edge of town."}
	]
	
	for npc_id in all_npcs:
		for fact in common_facts:
			_npc_facts_repo.create(npc_id, fact["type"], fact["content"], "common_knowledge")
	
	# NPCs know about each other based on their locations/interactions
	# Tavern regulars know each other well
	var tavern_regulars = ["npc_tavern_keeper", "npc_patron_farmer", "npc_patron_hunter", "npc_patron_bard"]
	for npc_id in tavern_regulars:
		_npc_facts_repo.create(npc_id, "npc", "Old Henrick is a retired farmer who spends most evenings at the tavern telling stories.", "personal_observation")
		_npc_facts_repo.create(npc_id, "npc", "Sera Nightbow is a hunter who keeps to herself. She arrived about eight years ago.", "personal_observation")
		_npc_facts_repo.create(npc_id, "npc", "Pip Merryweather is a halfling bard who's been staying at the tavern for a couple months.", "personal_observation")
	
	# Bram knows everyone's business
	_npc_facts_repo.create("npc_tavern_keeper", "gossip", "Sera Nightbow always sits with her back to the wall. Some say she's running from something.", "overheard")
	_npc_facts_repo.create("npc_tavern_keeper", "gossip", "The mayor's wife rarely visits anymore. People whisper about why.", "overheard")
	_npc_facts_repo.create("npc_tavern_keeper", "history", "I was once offered a knighthood for saving a noble's life, but I turned it down.", "personal_history")
	
	# Old Henrick knows old history
	_npc_facts_repo.create("npc_patron_farmer", "history", "I once met a real wizard who passed through town. He could make fire dance in his palm.", "personal_history")
	_npc_facts_repo.create("npc_patron_farmer", "history", "I've farmed these lands for sixty years. My family has been here for generations.", "personal_history")
	
	# Greta knows about weapons and armor
	_npc_facts_repo.create("npc_blacksmith", "craft", "Steel from the northern mines makes the strongest blades.", "professional_knowledge")
	_npc_facts_repo.create("npc_blacksmith", "history", "I once forged a sword for a knight who slew a dragon. He sent me a scale as thanks.", "personal_history")
	
	# Father Aldous knows spiritual matters
	_npc_facts_repo.create("npc_priest", "religion", "The Church of the Dawn teaches that light will always triumph over darkness.", "religious_knowledge")
	_npc_facts_repo.create("npc_priest", "history", "I came to Willowbrook seeking peace after witnessing too much suffering in the city temples.", "personal_history")
	
	# Esme knows mysterious things
	_npc_facts_repo.create("npc_herbalist", "craft", "The willow trees here have healing properties if you know how to prepare them.", "professional_knowledge")
	_npc_facts_repo.create("npc_herbalist", "mysterious", "The willows whisper secrets to those who listen.", "personal_belief")
	_npc_facts_repo.create("npc_herbalist", "observation", "Strange dreams have been troubling some villagers lately. The winds are changing.", "personal_observation")
	
	# Tom knows about security
	_npc_facts_repo.create("npc_guard", "duty", "I patrol the village perimeter at dawn and dusk to keep everyone safe.", "professional_knowledge")
	_npc_facts_repo.create("npc_guard", "history", "I once chased off a group of bandits who were scouting the village.", "personal_history")
	
	# Mayor knows administrative matters
	_npc_facts_repo.create("npc_mayor", "politics", "The village pays a small tax to the regional lord in exchange for protection.", "administrative_knowledge")
	_npc_facts_repo.create("npc_mayor", "history", "My family has lived in Willowbrook for generations. I chose to stay rather than seek fortune elsewhere.", "personal_history")

func _ensure_item(owner_id, def_id):
	var items = _inv_repo.get_by_owner(owner_id, true)
	for item in items:
		if item.get("item_def_id") == def_id: return
	_inv_repo.add_item(owner_id, def_id)
