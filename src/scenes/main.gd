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
@onready var tilemap = $TileMapLayer

var current_interaction_target = null
var _village_generated = false

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
	
	# Generate village tilemap if not already done
	_generate_village_if_needed()
	
	# Initialize action system for NPC actions
	DatabaseManager.initialize_action_system(self, tilemap)
	
	# Enable action mode for NPC dialogue (NPCs can take actions based on conversation)
	dialogue_window.set_action_mode(true)

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
			# Pass the NPC node so action mode can access world position
			dialogue_window.open(current_interaction_target.npc_id, current_interaction_target)
		
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

func _generate_village_if_needed():
	if _village_generated:
		return
	
	if not tilemap:
		tilemap = get_node_or_null("TileMapLayer")
	
	if not tilemap:
		print("Main: No TileMapLayer found!")
		_village_generated = true
		return
	
	print("Main: Checking tilemap...")
	print("Main: Current tile count: ", tilemap.get_used_cells().size())
	
	# Always regenerate for now to ensure buildings are placed
	print("Main: Clearing and regenerating village tilemap...")
	tilemap.clear()
	
	# Generate the village using data-driven building definitions
	var WorldRendererScript = load("res://src/components/world_renderer.gd")
	var renderer = WorldRendererScript.new()
	renderer.render_village(tilemap)
	
	print("Main: Village generated! Tile count: ", tilemap.get_used_cells().size())
	_village_generated = true
	
	# Initialize scene manager for building transitions
	_init_scene_manager()

func _init_scene_manager():
	# Initialize the scene manager with references to this scene and player
	var scene_manager = DatabaseManager.scenes
	if scene_manager:
		# Add to tree if not already (SceneManager extends Node)
		if not scene_manager.is_inside_tree():
			add_child(scene_manager)
		scene_manager.initialize(self, player)
		scene_manager.current_location_id = "loc_willowbrook"
		print("Main: Scene manager initialized")

func _process(_delta):
	# If inside a building, show exit prompt
	if _current_interior != null:
		_show_exit_prompt()
		return
	
	# Check if player is near a building entrance
	_check_building_entry()

func _show_exit_prompt():
	if not _entry_prompt_label:
		_entry_prompt_label = Label.new()
		_entry_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_entry_prompt_label.add_theme_font_size_override("font_size", 20)
		_entry_prompt_label.add_theme_color_override("font_color", Color.WHITE)
		_entry_prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		_entry_prompt_label.add_theme_constant_override("shadow_offset_x", 2)
		_entry_prompt_label.add_theme_constant_override("shadow_offset_y", 2)
		$CanvasLayer.add_child(_entry_prompt_label)
	
	var building_name = ""
	if not _current_interior_building.is_empty():
		var building = DatabaseManager.buildings.get_building(_current_interior_building)
		building_name = building.get("name", _current_interior_building)
	
	# Show different message based on player position
	if _is_player_near_exit():
		_entry_prompt_label.text = "Press E to exit " + building_name
		_entry_prompt_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_entry_prompt_label.text = "Inside: " + building_name + " (walk to door to exit)"
		_entry_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	
	_entry_prompt_label.visible = true
	_entry_prompt_label.position = Vector2(get_viewport().size.x / 2 - 180, 50)

var _entry_cooldown = 0.0
func _check_building_entry():
	if _entry_cooldown > 0:
		_entry_cooldown -= get_process_delta_time()
		return
	
	var building_repo = DatabaseManager.buildings
	if not building_repo:
		return
	
	var player_pos = player.global_position
	var found_door = false
	
	# Check each building's door position
	for building_id in building_repo.get_building_ids():
		var building = building_repo.get_building(building_id)
		var entry_points = building.get("entry_points", {})
		
		for entry_name in entry_points.keys():
			var entry = entry_points[entry_name]
			var entry_pos = Vector2(entry.get("x", 0), entry.get("y", 0))
			
			# Check if player is within 80 pixels of door
			if player_pos.distance_to(entry_pos) < 80:
				_prompt_building_entry(building_id, entry_name)
				found_door = true
				return
	
	# Hide prompt if not near any door
	if not found_door and not _current_entry_prompt.is_empty():
		_hide_entry_prompt()

var _current_entry_prompt: Dictionary = {}
var _entry_prompt_label: Label = null

func _prompt_building_entry(building_id: String, entry_name: String):
	# Show a prompt to enter the building
	if _current_entry_prompt.get("building_id") != building_id:
		var building = DatabaseManager.buildings.get_building(building_id)
		var building_name = building.get("name", building_id)
		print("Near door: Press E to enter ", building_name)
		_current_entry_prompt = {"building_id": building_id, "entry_name": entry_name}
		
		# Show on-screen prompt
		_show_entry_prompt(building_name)

func _show_entry_prompt(building_name: String):
	if not _entry_prompt_label:
		_entry_prompt_label = Label.new()
		_entry_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_entry_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_entry_prompt_label.add_theme_font_size_override("font_size", 20)
		_entry_prompt_label.add_theme_color_override("font_color", Color.WHITE)
		_entry_prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		_entry_prompt_label.add_theme_constant_override("shadow_offset_x", 2)
		_entry_prompt_label.add_theme_constant_override("shadow_offset_y", 2)
		$CanvasLayer.add_child(_entry_prompt_label)
	
	_entry_prompt_label.text = "Press E to enter: " + building_name
	_entry_prompt_label.visible = true
	_entry_prompt_label.position = Vector2(get_viewport().size.x / 2 - 150, get_viewport().size.y - 100)

func _hide_entry_prompt():
	if _entry_prompt_label:
		_entry_prompt_label.visible = false
	_current_entry_prompt = {}

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		# If inside a building, only exit if near the door (bottom of room)
		if _current_interior != null:
			# Check if player is near exit (bottom center of room)
			if _is_player_near_exit():
				_exit_building()
				get_viewport().set_input_as_handled()
			# Otherwise, let the player interact with NPCs (don't consume the event)
			return
		
		# If near a door in the exterior, enter the building
		if not _current_entry_prompt.is_empty():
			_enter_building(_current_entry_prompt.building_id, _current_entry_prompt.entry_name)
			_current_entry_prompt = {}
			get_viewport().set_input_as_handled()

func _is_player_near_exit() -> bool:
	"""Check if player is near the exit door in the interior"""
	if _current_interior_building.is_empty():
		return false
	
	var building = DatabaseManager.buildings.get_building(_current_interior_building)
	var interior = building.get("interior", {})
	var height = interior.get("height", 6)
	
	# Exit is at bottom center - check if player is in the bottom area
	var exit_y = (height / 2.0 - 0.5) * 48  # Bottom of room in local coords
	var player_y = player.global_position.y
	
	# Player must be near the bottom (within 60 pixels) and horizontally centered (within 80 pixels)
	var near_bottom = player_y > exit_y - 60
	var near_center = abs(player.global_position.x) < 80
	
	return near_bottom and near_center

func _exit_building():
	print("Main: Exiting building...")
	
	var scene_manager = DatabaseManager.scenes
	if scene_manager and scene_manager.is_inside_tree():
		_transition_to_exterior()
	else:
		_exit_building_immediate()

func _transition_to_exterior():
	var scene_manager = DatabaseManager.scenes
	
	# Fade out
	await scene_manager._fade_out()
	
	_exit_building_immediate()
	
	# Fade back in
	await scene_manager._fade_in()

func _exit_building_immediate():
	# Remove interior
	if _current_interior:
		_current_interior.queue_free()
		_current_interior = null
	
	# Show exterior elements and re-enable NPCs
	var npcs_node = get_node_or_null("NPCs")
	if npcs_node:
		npcs_node.visible = true
		# Re-enable processing on exterior NPCs
		for npc in npcs_node.get_children():
			npc.set_process(true)
			npc.set_physics_process(true)
	
	tilemap.visible = true
	
	# Position player outside the building door
	if not _current_interior_building.is_empty():
		var building = DatabaseManager.buildings.get_building(_current_interior_building)
		var entry_points = building.get("entry_points", {})
		var main_door = entry_points.get("main_door", entry_points.get("default", {}))
		if not main_door.is_empty():
			var exit_pos = Vector2(main_door.get("x", 0), main_door.get("y", 0) + 48)  # Below door
			player.global_position = exit_pos
			player.target_position = exit_pos
			player.velocity = Vector2.ZERO
	
	_current_interior_building = ""
	
	# Hide the prompt label when exiting
	_hide_entry_prompt()
	
	print("Main: Back outside")

func _enter_building(building_id: String, entry_name: String):
	print("Main: Entering building: ", building_id)
	_entry_cooldown = 2.0  # Prevent immediate re-entry
	_hide_entry_prompt()
	
	var building = DatabaseManager.buildings.get_building(building_id)
	var building_name = building.get("name", building_id)
	
	# Perform the scene transition with fade
	var scene_manager = DatabaseManager.scenes
	if scene_manager and scene_manager.is_inside_tree():
		print("Main: Starting transition to ", building_name)
		_transition_to_interior(building_id, entry_name)
	else:
		print("Main: Scene manager not ready, showing placeholder")
		_show_interior_placeholder(building_id)

func _transition_to_interior(building_id: String, entry_name: String):
	var scene_manager = DatabaseManager.scenes
	
	# Fade out
	await scene_manager._fade_out()
	
	# Generate interior
	var interior_renderer = load("res://src/components/interior_renderer.gd").new()
	var interior = interior_renderer.render_interior(building_id, self)
	
	if interior:
		# Hide exterior elements completely
		var npcs_node = get_node_or_null("NPCs")
		if npcs_node:
			npcs_node.visible = false
			# Also disable processing on exterior NPCs so they don't interfere
			for npc in npcs_node.get_children():
				npc.set_process(false)
				npc.set_physics_process(false)
		
		tilemap.visible = false
		
		# Position player at entry point
		var entry_pos = interior_renderer.get_entry_position(building_id, entry_name)
		player.global_position = entry_pos
		player.target_position = entry_pos
		player.velocity = Vector2.ZERO
		player.facing_direction = Vector2.UP  # Face into the room
		print("Main: Player positioned at ", entry_pos)
		
		# Store reference for exit
		_current_interior = interior
		_current_interior_building = building_id
	
	# Fade back in
	await scene_manager._fade_in()
	
	print("Main: Now inside ", DatabaseManager.buildings.get_building(building_id).get("name", building_id))

var _current_interior: Node2D = null
var _current_interior_building: String = ""

func _show_interior_placeholder(building_id: String):
	# Fallback: just show a message
	var building = DatabaseManager.buildings.get_building(building_id)
	print("Entered: ", building.get("name", building_id))
	print("Interior: ", building.get("description", "No description"))
	
	# Show dialogue with building info
	if dialogue_window:
		dialogue_window.visible = true
		# Set some placeholder text
		var desc = building.get("description", "You enter the building.")
		print("Building description: ", desc)
