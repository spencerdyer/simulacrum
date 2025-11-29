extends Control

@onready var inventory_list = $Panel/HBoxContainer/InventoryPanel/ScrollContainer/VBoxContainer
@onready var equipment_panel = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer

# Drag Data Structure:
# { "type": "inventory_item", "item": dictionary_data }

func _ready():
	update_display()

func update_display():
	var player = DatabaseManager.characters.get_player()
	if not player: return
	
	var player_id = player["id"]
	
	# 1. Clear Inventory List
	for child in inventory_list.get_children():
		child.queue_free()
		
	# 2. Populate Inventory List
	var inventory = DatabaseManager.inventory.get_by_owner(player_id)
	for item in inventory:
		# Create a custom button script or attach logic dynamically
		var btn = Button.new()
		btn.text = item["name"] + " (" + item["type"] + ")"
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Attach a script to handle drag data locally for this button
		btn.set_script(preload("res://src/ui/draggable_item.gd")) 
		btn.item_data = item
		
		inventory_list.add_child(btn)
		
	# 3. Update Equipment Slots
	var equipment = DatabaseManager.get_player_equipment(player_id)
	
	# We iterate through known UI slots by name
	var slots = ["HEAD", "CHEST", "LEGS", "RIGHT_HAND", "LEFT_HAND"]
	
	# We need to map the generic VBox children to these slots
	# Assuming VBox children order matches: Head, Chest, Legs, Right, Left
	var ui_slots = equipment_panel.get_children()
	
	for i in range(slots.size()):
		var slot_name = slots[i]
		if i < ui_slots.size():
			var slot_btn = ui_slots[i]
			var item = equipment.get(slot_name)
			
			# Set visual text
			if item:
				slot_btn.text = slot_name + ": " + item["name"]
			else:
				slot_btn.text = slot_name + ": Empty"
				
			# Attach drop logic script
			if not slot_btn.get_script():
				slot_btn.set_script(preload("res://src/ui/equipment_slot.gd"))
			
			slot_btn.slot_type = slot_name
			slot_btn.equipped_item = item # Store for logic if needed
			
			# Disconnect old signals to avoid duplicates if re-running
			if slot_btn.pressed.is_connected(_on_slot_pressed):
				slot_btn.pressed.disconnect(_on_slot_pressed)
			slot_btn.pressed.connect(_on_slot_pressed.bind(slot_name))

func _on_slot_pressed(slot_name):
	var player = DatabaseManager.characters.get_player()
	if player["equipment"].get(slot_name):
		DatabaseManager.equipment.unequip_item(player["id"], slot_name)
		update_display()

func _on_close_pressed():
	visible = false

# Global drag and drop handling is delegated to individual controls (scripts below)
