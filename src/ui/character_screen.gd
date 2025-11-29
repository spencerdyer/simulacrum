extends Control

@onready var name_label = $Panel/HBoxContainer/VBoxContainer/NameLabel
@onready var desc_label = $Panel/HBoxContainer/VBoxContainer/DescLabel
@onready var stats_label = $Panel/HBoxContainer/VBoxContainer2/StatsLabel

# Default to player, but can be set to view others
var current_character_id = null

func _ready():
	pass

func open(character_id = null):
	if character_id:
		current_character_id = character_id
	else:
		var player = DatabaseManager.characters.get_player()
		if player:
			current_character_id = player["id"]
	
	visible = true
	update_display()

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
	visible = false
