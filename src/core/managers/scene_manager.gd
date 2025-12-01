extends Node

# SceneManager - Handles location transitions with fade effects
# Manages loading/unloading of location scenes and player positioning

signal transition_started(from_location: String, to_location: String)
signal transition_completed(location_id: String)
signal location_changed(location_id: String)

const FADE_DURATION = 1.0  # seconds

var current_location_id: String = ""
var current_scene: Node = null
var _transition_in_progress: bool = false
var _fade_overlay: ColorRect = null
var _fade_tween: Tween = null

# Reference to the main scene tree root where locations are loaded
var _scene_root: Node = null
var _player: Node = null

func _ready():
	# Create fade overlay (will be added to CanvasLayer when needed)
	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color.BLACK
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.modulate.a = 0.0

func initialize(scene_root: Node, player: Node):
	_scene_root = scene_root
	_player = player
	print("SceneManager: Initialized with scene root: ", scene_root.name)

func get_current_location_id() -> String:
	return current_location_id

func is_transitioning() -> bool:
	return _transition_in_progress

# Transition to a new location
func transition_to(location_id: String, entry_point: String = "default") -> bool:
	if _transition_in_progress:
		push_warning("SceneManager: Transition already in progress")
		return false
	
	var location_data = DatabaseManager.world_locations.get_by_id(location_id)
	if not location_data:
		push_error("SceneManager: Location not found: " + location_id)
		return false
	
	print("SceneManager: Transitioning to ", location_id, " via entry point: ", entry_point)
	
	_transition_in_progress = true
	transition_started.emit(current_location_id, location_id)
	
	# Start fade out
	await _fade_out()
	
	# Unload current location if it exists
	if current_scene and current_scene != _scene_root:
		_unload_current_location()
	
	# Load new location
	var success = await _load_location(location_id, entry_point)
	
	if success:
		current_location_id = location_id
		location_changed.emit(location_id)
	
	# Fade back in
	await _fade_in()
	
	_transition_in_progress = false
	transition_completed.emit(location_id)
	
	return success

func _fade_out():
	_ensure_fade_overlay()
	_fade_overlay.modulate.a = 0.0
	
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_overlay, "modulate:a", 1.0, FADE_DURATION / 2.0)
	await _fade_tween.finished

func _fade_in():
	_ensure_fade_overlay()
	
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_DURATION / 2.0)
	await _fade_tween.finished

func _ensure_fade_overlay():
	if not _fade_overlay.get_parent():
		# Add to a CanvasLayer so it renders on top of everything
		var canvas_layer = _scene_root.get_node_or_null("CanvasLayer")
		if canvas_layer:
			canvas_layer.add_child(_fade_overlay)
			_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		else:
			push_warning("SceneManager: No CanvasLayer found for fade overlay")

func _unload_current_location():
	# Save any state before unloading
	_save_location_state(current_location_id)
	
	# For now, we don't actually unload the main world scene
	# This will be expanded when we have proper interior scenes
	print("SceneManager: Unloading location: ", current_location_id)

func _load_location(location_id: String, entry_point: String) -> bool:
	var location_data = DatabaseManager.world_locations.get_by_id(location_id)
	if not location_data:
		return false
	
	var location_type = location_data.get("type", "area")
	
	print("SceneManager: Loading location type: ", location_type)
	
	match location_type:
		"settlement", "area":
			# Outdoor areas - use the main world scene
			_position_player_at_entry(location_data, entry_point)
			return true
		
		"tavern", "shop", "house", "church":
			# Building interiors - generate from data
			return await _load_building_interior(location_data, entry_point)
		
		_:
			push_warning("SceneManager: Unknown location type: " + location_type)
			return false

func _load_building_interior(location_data: Dictionary, entry_point: String) -> bool:
	# TODO: Generate interior scene from location data
	# For now, just position the player
	print("SceneManager: Loading building interior: ", location_data.get("name", "Unknown"))
	
	var floor_layout = location_data.get("floor_layout", {})
	var entry_points = location_data.get("entry_points", {})
	
	# Position player at entry point
	_position_player_at_entry(location_data, entry_point)
	
	return true

func _position_player_at_entry(location_data: Dictionary, entry_point: String):
	if not _player:
		return
	
	var entry_points = location_data.get("entry_points", {})
	var position = Vector2.ZERO
	
	if entry_points.has(entry_point):
		var ep = entry_points[entry_point]
		position = Vector2(ep.get("x", 0), ep.get("y", 0))
	elif entry_points.has("default"):
		var ep = entry_points["default"]
		position = Vector2(ep.get("x", 0), ep.get("y", 0))
	
	# Set player position
	_player.global_position = position
	# Reset player target to current position so they don't walk away
	if _player.has_method("set") and "target_position" in _player:
		_player.target_position = position
	
	print("SceneManager: Positioned player at ", position)

func _save_location_state(location_id: String):
	if location_id.is_empty():
		return
	
	# Save NPC positions, item states, etc.
	var state = {
		"timestamp": Time.get_unix_time_from_system(),
		"npcs": _gather_npc_states(),
		"items": _gather_item_states()
	}
	
	# Store in location data
	var location = DatabaseManager.world_locations.get_by_id(location_id)
	if location:
		location["saved_state"] = state
		DatabaseManager.world_locations.update(location)

func _gather_npc_states() -> Array:
	var states = []
	var npcs = _scene_root.get_tree().get_nodes_in_group("NPC") if _scene_root else []
	
	for npc in npcs:
		if npc is Node2D:
			states.append({
				"id": npc.get("npc_id") if "npc_id" in npc else "",
				"position": {"x": npc.global_position.x, "y": npc.global_position.y},
				"facing": {"x": npc.get("facing_direction").x, "y": npc.get("facing_direction").y} if "facing_direction" in npc else {"x": 0, "y": 1}
			})
	
	return states

func _gather_item_states() -> Array:
	# TODO: Implement when we have world items
	return []

# Get a description of the current location for LLM context
func get_location_context() -> Dictionary:
	if current_location_id.is_empty():
		return {}
	
	var location = DatabaseManager.world_locations.get_by_id(current_location_id)
	if not location:
		return {}
	
	return {
		"id": current_location_id,
		"name": location.get("name", "Unknown"),
		"type": location.get("type", "area"),
		"description": location.get("description", ""),
		"features": location.get("features", []),
		"parent": location.get("parent_id", ""),
		"npcs_present": _get_npcs_in_location(),
		"environmental_state": location.get("environmental_state", {})
	}

func _get_npcs_in_location() -> Array:
	var npc_names = []
	var npcs = _scene_root.get_tree().get_nodes_in_group("NPC") if _scene_root else []
	
	for npc in npcs:
		if "npc_id" in npc:
			var char_data = DatabaseManager.characters.get_by_id(npc.npc_id)
			if char_data:
				npc_names.append(char_data.get("name", "Unknown"))
	
	return npc_names

