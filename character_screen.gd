extends Control

@onready var name_label = $Panel/HBoxContainer/VBoxContainer/NameLabel
@onready var desc_label = $Panel/HBoxContainer/VBoxContainer/DescLabel
@onready var stats_label = $Panel/HBoxContainer/VBoxContainer2/StatsLabel

func _ready():
	# Update UI with data from DB
	update_display()

func update_display():
	var player_data = DatabaseManager.get_player_character()
	if player_data:
		name_label.text = "Name: " + player_data.get("name", "Unknown")
		desc_label.text = "Gender: " + player_data.get("gender", "?") + "\n\n" + \
						  "Bio: " + player_data.get("description", "") + "\n\n" + \
						  "Backstory: " + player_data.get("backstory", "")
		
		var stats_text = "STATS\n" + \
						 "Health: " + str(player_data.get("health", 0)) + "/" + str(player_data.get("max_health", 0)) + "\n" + \
						 "Stamina: " + str(player_data.get("stamina", 0)) + "\n" + \
						 "Strength: " + str(player_data.get("strength", 0)) + "\n" + \
						 "Dexterity: " + str(player_data.get("dexterity", 0)) + "\n" + \
						 "Intelligence: " + str(player_data.get("intelligence", 0)) + "\n" + \
						 "Charisma: " + str(player_data.get("charisma", 0))
		stats_label.text = stats_text

