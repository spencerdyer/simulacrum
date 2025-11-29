extends Button

var slot_type = ""
var equipped_item = null

func _can_drop_data(_at_position, data):
	if data.has("source") and data["source"] == "inventory":
		var item = data["item"]
		# Check compatibility
		if item["type"] == slot_type: return true
		if item["type"] == "HAND" and (slot_type == "RIGHT_HAND" or slot_type == "LEFT_HAND"): return true
	return false

func _drop_data(_at_position, data):
	if data.has("item"):
		var item = data["item"]
		var player = DatabaseManager.characters.get_player()
		
		# Equip Logic (Using new Equipment System via Facade)
		DatabaseManager.equipment.equip_item(player["id"], item["instance_id"], slot_type)
		
		# Refresh UI (Parent needs to handle this)
		# We find the InventoryScreen root to call update
		var p = get_parent()
		while p:
			if p.has_method("update_display"):
				p.update_display()
				break
			p = p.get_parent()
