extends Control

signal back_requested
signal closed

@onready var inventory_list = $Panel/HBoxContainer/InventoryPanel/ScrollContainer/VBoxContainer
@onready var equipment_panel = $Panel/HBoxContainer/EquipmentPanel/VBoxContainer
@onready var panel = $Panel
@onready var back_button = $Panel/BackButton

var opener_window_id = ""

# Dragging state
var dragging = false
var drag_offset = Vector2.ZERO
const TITLE_BAR_HEIGHT = 40

func _ready():
	back_button.visible = false

func open(opener_id: String = ""):
	opener_window_id = opener_id
	
	if DatabaseManager.windows.is_window_open("inventory", "player"):
		print("Inventory screen already open")
		return false
	
	DatabaseManager.windows.register_window("inventory", "player", self, opener_id)
	
	back_button.visible = (opener_id != "")
	
	visible = true
	_center_panel()
	update_display()
	return true

func _center_panel():
	var viewport_size = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2

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
		var btn = Button.new()
		btn.text = item["name"] + " (" + item["type"] + ")"
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		btn.set_script(preload("res://src/ui/draggable_item.gd")) 
		btn.item_data = item
		
		inventory_list.add_child(btn)
		
	# 3. Update Equipment Slots
	var equipment = DatabaseManager.get_player_equipment(player_id)
	
	var slots = ["HEAD", "CHEST", "LEGS", "RIGHT_HAND", "LEFT_HAND"]
	var ui_slots = equipment_panel.get_children()
	
	for i in range(slots.size()):
		var slot_name = slots[i]
		if i < ui_slots.size():
			var slot_btn = ui_slots[i]
			var item = equipment.get(slot_name)
			
			if item:
				slot_btn.text = slot_name + ": " + item["name"]
			else:
				slot_btn.text = slot_name + ": Empty"
				
			if not slot_btn.get_script():
				slot_btn.set_script(preload("res://src/ui/equipment_slot.gd"))
			
			slot_btn.slot_type = slot_name
			slot_btn.equipped_item = item
			
			if slot_btn.pressed.is_connected(_on_slot_pressed):
				slot_btn.pressed.disconnect(_on_slot_pressed)
			slot_btn.pressed.connect(_on_slot_pressed.bind(slot_name))

func _on_slot_pressed(slot_name):
	var player = DatabaseManager.characters.get_player()
	if player["equipment"].get(slot_name):
		DatabaseManager.equipment.unequip_item(player["id"], slot_name)
		update_display()

func _on_close_pressed():
	_close_window()

func _on_back_pressed():
	emit_signal("back_requested")
	_close_window()

func _close_window():
	DatabaseManager.windows.close_window("inventory", "player")
	visible = false
	emit_signal("closed")

# TitleBar dragging
func _on_titlebar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
				
	elif event is InputEventMouseMotion and dragging:
		panel.position += event.relative
