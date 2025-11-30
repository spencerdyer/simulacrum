extends Node2D

@onready var character_screen = $CanvasLayer/CharacterScreen
@onready var inventory_screen = $CanvasLayer/InventoryScreen
@onready var trade_screen = $CanvasLayer/TradeScreen
@onready var interaction_menu = $CanvasLayer/InteractionMenu
@onready var dialogue_window = $CanvasLayer/DialogueWindow
@onready var system_menu = $CanvasLayer/SystemMenu
@onready var save_menu = $CanvasLayer/SaveMenu
@onready var load_menu = $CanvasLayer/LoadMenu
@onready var settings_menu = $CanvasLayer/SettingsMenu
@onready var player = $Player

var current_interaction_target = null

func _ready():
	character_screen.visible = false
	inventory_screen.visible = false
	trade_screen.visible = false
	interaction_menu.visible = false
	dialogue_window.visible = false
	system_menu.visible = false
	save_menu.visible = false
	load_menu.visible = false
	settings_menu.visible = false
	
	# Connect Player Signal
	player.interaction_requested.connect(_on_player_interaction_requested)
	# Connect Interaction Menu Signals
	interaction_menu.option_selected.connect(_on_interaction_option)
	
	# Connect back signals for navigation
	character_screen.back_requested.connect(_on_character_back)
	trade_screen.back_requested.connect(_on_trade_back)
	inventory_screen.back_requested.connect(_on_inventory_back)
	dialogue_window.closed.connect(_on_dialogue_closed)
	
	# Connect system menu signals
	save_menu.back_requested.connect(_on_system_submenu_back)
	load_menu.back_requested.connect(_on_system_submenu_back)
	load_menu.game_loaded.connect(_on_game_loaded)
	settings_menu.back_requested.connect(_on_system_submenu_back)

func _is_text_input_focused() -> bool:
	var focused = get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Escape key
		_handle_escape()
		get_viewport().set_input_as_handled()
		return
	
	# Block hotkeys when typing in a text field
	if _is_text_input_focused():
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			toggle_character_screen()
		elif event.keycode == KEY_I:
			toggle_inventory_screen()

func _handle_escape():
	# If dialogue window is open, close it
	if dialogue_window.visible:
		dialogue_window.visible = false
		return
	
	# If any game window is open, close it
	if character_screen.visible or inventory_screen.visible or trade_screen.visible or interaction_menu.visible:
		_close_all_game_windows()
		return
	
	# If a system submenu is open, go back to system menu
	if save_menu.visible or load_menu.visible or settings_menu.visible:
		save_menu.visible = false
		load_menu.visible = false
		settings_menu.visible = false
		system_menu.open()
		return
	
	# If system menu is open, close it
	if system_menu.visible:
		system_menu.visible = false
		return
	
	# Otherwise, open system menu
	system_menu.open()

func _close_all_game_windows():
	character_screen.visible = false
	inventory_screen.visible = false
	trade_screen.visible = false
	interaction_menu.visible = false
	dialogue_window.visible = false
	DatabaseManager.windows.close_all()

func toggle_character_screen():
	if character_screen.visible:
		character_screen._close_window()
	else:
		character_screen.open("player_1", "")

func toggle_inventory_screen():
	if inventory_screen.visible:
		inventory_screen._close_window()
	else:
		inventory_screen.open("")

func _on_hud_toggle_character_screen():
	toggle_character_screen()

func _on_hud_toggle_inventory_screen():
	toggle_inventory_screen()

func _on_player_interaction_requested(target):
	current_interaction_target = target
	print("Main: Interaction requested with ", target.name)
	interaction_menu.visible = true

func _on_interaction_option(option):
	var opener_id = "interaction_menu"
	
	if option == "talk":
		print("Main: Opening dialogue with NPC")
		interaction_menu.visible = false
		if current_interaction_target and "npc_id" in current_interaction_target:
			dialogue_window.open(current_interaction_target.npc_id)
		
	elif option == "trade":
		print("Main: Trading with NPC")
		if current_interaction_target and "npc_id" in current_interaction_target:
			interaction_menu.visible = false
			trade_screen.open_trade(current_interaction_target.npc_id, opener_id)
			
	elif option == "inspect":
		print("Main: Inspecting NPC")
		if current_interaction_target and "npc_id" in current_interaction_target:
			interaction_menu.visible = false
			character_screen.open(current_interaction_target.npc_id, opener_id)

# Back navigation handlers
func _on_character_back():
	interaction_menu.visible = true

func _on_trade_back():
	interaction_menu.visible = true

func _on_inventory_back():
	pass

func _on_dialogue_closed():
	# Optionally reopen interaction menu
	pass

func _on_system_submenu_back():
	system_menu.open()

func _on_game_loaded():
	# Refresh UI after loading a game
	print("Game loaded, refreshing state...")
