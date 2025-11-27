extends Node2D

@onready var character_screen = $CanvasLayer/CharacterScreen
@onready var inventory_screen = $CanvasLayer/InventoryScreen
@onready var player = $Player

func _ready():
	character_screen.visible = false
	inventory_screen.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Escape key
		character_screen.visible = false
		inventory_screen.visible = false
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			toggle_character_screen()
		elif event.keycode == KEY_I:
			toggle_inventory_screen()

func toggle_character_screen():
	character_screen.visible = !character_screen.visible
	inventory_screen.visible = false # Close others
	if character_screen.visible:
		character_screen.update_display()

func toggle_inventory_screen():
	inventory_screen.visible = !inventory_screen.visible
	character_screen.visible = false # Close others
	if inventory_screen.visible:
		inventory_screen.update_display()

func _on_hud_toggle_character_screen():
	toggle_character_screen()

func _on_hud_toggle_inventory_screen():
	toggle_inventory_screen()
