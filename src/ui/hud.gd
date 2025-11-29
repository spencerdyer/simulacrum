extends Control

signal toggle_character_screen
signal toggle_inventory_screen

func _on_char_button_pressed():
	emit_signal("toggle_character_screen")

func _on_inv_button_pressed():
	emit_signal("toggle_inventory_screen")
