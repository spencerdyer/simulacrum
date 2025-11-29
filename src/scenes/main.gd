extends Node2D

@onready var character_screen = $CanvasLayer/CharacterScreen
@onready var inventory_screen = $CanvasLayer/InventoryScreen
@onready var trade_screen = $CanvasLayer/TradeScreen
@onready var interaction_menu = $CanvasLayer/InteractionMenu
@onready var player = $Player

var current_interaction_target = null

func _ready():
	character_screen.visible = false
	inventory_screen.visible = false
	trade_screen.visible = false
	interaction_menu.visible = false
	
	# Connect Player Signal
	player.interaction_requested.connect(_on_player_interaction_requested)
	# Connect Interaction Menu Signals
	interaction_menu.option_selected.connect(_on_interaction_option)

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Escape key
		character_screen.visible = false
		inventory_screen.visible = false
		trade_screen.visible = false
		interaction_menu.visible = false
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			toggle_character_screen()
		elif event.keycode == KEY_I:
			toggle_inventory_screen()

func toggle_character_screen():
	# If opening via key, default to player.
	# But if we toggle it closed, just hide.
	if character_screen.visible:
		character_screen.visible = false
	else:
		open_character_screen("player_1")

func open_character_screen(character_id):
	inventory_screen.visible = false
	trade_screen.visible = false
	interaction_menu.visible = false
	character_screen.open(character_id)

func toggle_inventory_screen():
	inventory_screen.visible = !inventory_screen.visible
	character_screen.visible = false
	trade_screen.visible = false
	interaction_menu.visible = false
	if inventory_screen.visible:
		inventory_screen.update_display()

func _on_hud_toggle_character_screen():
	toggle_character_screen()

func _on_hud_toggle_inventory_screen():
	toggle_inventory_screen()

func _on_player_interaction_requested(target):
	current_interaction_target = target
	print("Main: Interaction requested with ", target.name)
	
	# Position menu near the target or center screen
	interaction_menu.visible = true
	# Optional: Set menu title or context based on target

func _on_interaction_option(option):
	interaction_menu.visible = false
	
	if option == "talk":
		print("Main: Talking to NPC (Placeholder)")
		# Show dialog box (Todo)
		
	elif option == "trade":
		print("Main: Trading with NPC")
		if current_interaction_target and "npc_id" in current_interaction_target:
			trade_screen.open_trade(current_interaction_target.npc_id)
			
	elif option == "inspect":
		print("Main: Inspecting NPC")
		if current_interaction_target and "npc_id" in current_interaction_target:
			open_character_screen(current_interaction_target.npc_id)
