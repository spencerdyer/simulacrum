extends Control

signal back_requested
signal closed

@onready var panel = $Panel
@onready var back_button = $Panel/BackButton
@onready var title_label = $Panel/TitleBar/TitleLabel

# Name section
@onready var name_label = $Panel/ScrollContainer/ContentContainer/NameSection/NameLabel
@onready var occupation_label = $Panel/ScrollContainer/ContentContainer/NameSection/OccupationLabel

# Physical/Stats section
@onready var physical_info = $Panel/ScrollContainer/ContentContainer/TwoColumnContainer/LeftColumn/PhysicalInfo
@onready var stats_info = $Panel/ScrollContainer/ContentContainer/TwoColumnContainer/LeftColumn/StatsInfo
@onready var desc_label = $Panel/ScrollContainer/ContentContainer/TwoColumnContainer/RightColumn/DescLabel

# Story sections
@onready var backstory_section = $Panel/ScrollContainer/ContentContainer/BackstorySection
@onready var backstory_label = $Panel/ScrollContainer/ContentContainer/BackstorySection/BackstoryLabel
@onready var routine_section = $Panel/ScrollContainer/ContentContainer/RoutineSection
@onready var routine_label = $Panel/ScrollContainer/ContentContainer/RoutineSection/RoutineLabel
@onready var fact_section = $Panel/ScrollContainer/ContentContainer/FactSection
@onready var fact_label = $Panel/ScrollContainer/ContentContainer/FactSection/FactLabel

# Separators (to hide when sections are hidden)
@onready var separator2 = $Panel/ScrollContainer/ContentContainer/Separator2
@onready var separator3 = $Panel/ScrollContainer/ContentContainer/Separator3
@onready var separator4 = $Panel/ScrollContainer/ContentContainer/Separator4

# Default to player, but can be set to view others
var current_character_id = null
var opener_window_id = ""

# Dragging state
var dragging = false
var drag_offset = Vector2.ZERO

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
	if not current_character_id: 
		return
	
	var char_data = DatabaseManager.characters.get_by_id(current_character_id)
	
	if not char_data:
		return
	
	# Title
	var char_name = char_data.get("name", "Unknown")
	title_label.text = char_name.to_upper()
	
	# Name section
	name_label.text = char_name
	var occupation = char_data.get("occupation", "")
	if occupation != "":
		occupation_label.text = occupation
		occupation_label.visible = true
	else:
		occupation_label.visible = false
	
	# Physical traits
	var physical_text = ""
	var gender = char_data.get("gender", "")
	if gender != "":
		physical_text += "Gender: " + gender + "\n"
	
	var age = char_data.get("age", "")
	if str(age) != "" and str(age) != "0":
		physical_text += "Age: " + str(age) + " years\n"
	
	var height = char_data.get("height", "")
	if height != "":
		physical_text += "Height: " + str(height) + "\n"
	
	var weight = char_data.get("weight", "")
	if weight != "":
		physical_text += "Weight: " + str(weight) + "\n"
	
	var eyes = char_data.get("eye_color", "")
	if eyes != "":
		physical_text += "Eyes: " + str(eyes) + "\n"
	
	var hair = char_data.get("hair_color", "")
	if hair != "":
		physical_text += "Hair: " + str(hair)
	
	physical_info.text = physical_text.strip_edges()
	
	# Stats
	var stats_text = "Health: %d/%d\n" % [char_data.get("health", 0), char_data.get("max_health", 100)]
	stats_text += "Stamina: %d\n\n" % char_data.get("stamina", 0)
	stats_text += "Strength: %d\n" % char_data.get("strength", 0)
	stats_text += "Dexterity: %d\n" % char_data.get("dexterity", 0)
	stats_text += "Intelligence: %d\n" % char_data.get("intelligence", 0)
	stats_text += "Charisma: %d" % char_data.get("charisma", 0)
	stats_info.text = stats_text
	
	# Description
	var description = char_data.get("description", "No description available.")
	desc_label.text = description
	
	# Backstory
	var backstory = char_data.get("backstory", "")
	if backstory != "":
		backstory_label.text = backstory
		backstory_section.visible = true
		separator2.visible = true
	else:
		backstory_section.visible = false
		separator2.visible = false
	
	# Daily routine (only for NPCs)
	var routine = char_data.get("daily_routine", "")
	if routine != "":
		routine_label.text = routine
		routine_section.visible = true
		separator3.visible = true
	else:
		routine_section.visible = false
		separator3.visible = false
	
	# Interesting fact (only for NPCs)
	var fact = char_data.get("interesting_fact", "")
	if fact != "":
		fact_label.text = fact
		fact_section.visible = true
		separator4.visible = true
	else:
		fact_section.visible = false
		separator4.visible = false

func _on_close_pressed():
	_close_window()

func _on_back_pressed():
	emit_signal("back_requested")
	_close_window()

func _close_window():
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
