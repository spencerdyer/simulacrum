extends Control

@onready var inventory_list = $Panel/HBoxContainer/InventoryPanel/ScrollContainer/VBoxContainer
@onready var equipment_panel = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer

# Slot UI references
var slot_buttons = {}

func _ready():
	# Map UI slots
	slot_buttons["HEAD"] = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer/HeadSlot
	slot_buttons["CHEST"] = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer/ChestSlot
	slot_buttons["LEGS"] = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer/LegsSlot
	slot_buttons["RIGHT_HAND"] = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer/RightHandSlot
	slot_buttons["LEFT_HAND"] = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer/LeftHandSlot
	
	update_display()

func update_display():
	var player = DatabaseManager.get_player_character()
	if not player: return
	
	var player_id = player["id"]
	
	# 1. Clear Inventory List
	for child in inventory_list.get_children():
		child.queue_free()
		
	# 2. Populate Inventory List
	var inventory = DatabaseManager.get_player_inventory(player_id)
	for item in inventory:
		var btn = Button.new()
		btn.text = item["name"] + " (" + item["type"] + ")"
		btn.pressed.connect(_on_inventory_item_pressed.bind(item))
		inventory_list.add_child(btn)
		
	# 3. Update Equipment Slots
	var equipment = DatabaseManager.get_player_equipment(player_id)
	for slot in slot_buttons.keys():
		var btn = slot_buttons[slot]
		var item = equipment.get(slot)
		
		if item:
			btn.text = slot + ": " + item["name"]
		else:
			btn.text = slot + ": Empty"

func _on_inventory_item_pressed(item):
	var player = DatabaseManager.get_player_character()
	# Try to equip it
	if item["type"] in ["HEAD", "CHEST", "LEGS", "RIGHT_HAND", "LEFT_HAND"]:
		DatabaseManager.equip_item(player["id"], item["instance_id"], item["type"])
		update_display()
	else:
		print("Cannot equip item type: ", item["type"])

func _on_equipment_slot_pressed(slot):
	var player = DatabaseManager.get_player_character()
	# Try to unequip
	if player["equipment"].get(slot):
		DatabaseManager.unequip_item(player["id"], slot)
		update_display()

