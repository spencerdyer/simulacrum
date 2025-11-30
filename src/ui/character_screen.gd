extends Control

signal back_requested
signal closed

@onready var name_label = $Panel/HBoxContainer/VBoxContainer/NameLabel
@onready var desc_label = $Panel/HBoxContainer/VBoxContainer/DescLabel
@onready var stats_label = $Panel/HBoxContainer/VBoxContainer2/StatsLabel
@onready var panel = $Panel
@onready var back_button = $Panel/BackButton

# Default to player, but can be set to view others
var current_character_id = null
var opener_window_id = ""

# Dragging state
var dragging = false
var drag_offset = Vector2.ZERO
const TITLE_BAR_HEIGHT = 40

func _ready():
	back_button.visible = false

func open(character_id = null, opener_id: String = ""):
	if character_id:
		current_character_id = character_id
	else:
		var player = DatabaseManager.characters.get_player()
		if player:
			current_character_id = player["id"]
	
	opener_window_id = opener_id
	
	# Check if already open
	if DatabaseManager.windows.is_window_open("character", current_character_id):
		print("Character screen already open for: ", current_character_id)
		return false
	
	# Register with window manager
	DatabaseManager.windows.register_window("character", current_character_id, self, opener_id)
	
	# Show back button if we came from another window
	back_button.visible = (opener_id != "")
	
	visible = true
	_center_panel()
	update_display()
	return true

func _center_panel():
	var viewport_size = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2

func update_display():
	if not current_character_id: return
	
	var char_data = DatabaseManager.characters.get_by_id(current_character_id)
	
	if char_data:
		name_label.text = "Name: " + char_data.get("name", "Unknown")
		desc_label.text = "Gender: " + char_data.get("gender", "?") + "\n\n" + \
						  "Bio: " + char_data.get("description", "") + "\n\n" + \
						  "Backstory: " + char_data.get("backstory", "")
		
		var stats_text = "STATS\n" + \
						 "Health: " + str(char_data.get("health", 0)) + "/" + str(char_data.get("max_health", 0)) + "\n" + \
						 "Stamina: " + str(char_data.get("stamina", 0)) + "\n" + \
						 "Strength: " + str(char_data.get("strength", 0)) + "\n" + \
						 "Dexterity: " + str(char_data.get("dexterity", 0)) + "\n" + \
						 "Intelligence: " + str(char_data.get("intelligence", 0)) + "\n" + \
						 "Charisma: " + str(char_data.get("charisma", 0))
		stats_label.text = stats_text

func _on_close_pressed():
	_close_window()

func _on_back_pressed():
	emit_signal("back_requested")
	_close_window()

func _close_window():
	DatabaseManager.windows.close_window("character", current_character_id)
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
