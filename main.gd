extends Node2D

@onready var character_screen = $CanvasLayer/CharacterScreen
@onready var player = $Player

func _ready():
	character_screen.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Escape key often
		character_screen.visible = false
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		toggle_character_screen()

func toggle_character_screen():
	character_screen.visible = !character_screen.visible
	if character_screen.visible:
		character_screen.update_display()

func _on_hud_toggle_character_screen():
	toggle_character_screen()
