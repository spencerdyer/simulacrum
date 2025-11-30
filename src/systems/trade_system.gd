extends RefCounted

var _inv_repo

func _init(inv_repo):
	_inv_repo = inv_repo

func execute_trade(player_items: Array, npc_id: String, npc_items: Array, player_id: String):
	# Move Player Items to NPC
	for item in player_items:
		if item.get("instance_id"):
			_inv_repo.update_owner(item["instance_id"], npc_id)
			
	# Move NPC Items to Player
	for item in npc_items:
		if item.get("instance_id"):
			_inv_repo.update_owner(item["instance_id"], player_id)
	
	# Create memories for both parties
	_create_trade_memories(player_items, npc_id, npc_items, player_id)
	
	# Initialize/update relationships
	DatabaseManager.relationships.get_or_create(npc_id, player_id)
	DatabaseManager.relationships.get_or_create(player_id, npc_id)
	
	print("Trade Executed: ", player_items.size(), " items for ", npc_items.size(), " items.")

func _create_trade_memories(player_items: Array, npc_id: String, npc_items: Array, player_id: String):
	var player_data = DatabaseManager.characters.get_by_id(player_id)
	var npc_data = DatabaseManager.characters.get_by_id(npc_id)
	
	var player_name = player_data.get("name", "the adventurer") if player_data else "the adventurer"
	var npc_name = npc_data.get("name", "the merchant") if npc_data else "the merchant"
	
	# NPC memory of the trade
	DatabaseManager.npc_memories.create_trade_memory(npc_id, player_name, npc_items, player_items)
	
	# Could also create player memory here if we track player memories
	# For now, just NPC memories
