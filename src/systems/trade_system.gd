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
			
	print("Trade Executed: ", player_items.size(), " items for ", npc_items.size(), " items.")

