extends CharacterBody2D

signal interaction_requested(target)

@export var speed = 400.0
var target_position = Vector2.ZERO

# Facing direction (normalized vector)
var facing_direction = Vector2.DOWN  # Default facing down
var is_moving = false

# Interaction
var interact_range = 120.0
var facing_cone_angle = 90.0  # Degrees - how wide the "facing" cone is

@onready var camera = $Camera2D
@onready var character_renderer = $CharacterRenderer

# Zoom settings
var zoom_level = 0.75  # Current zoom (matches Camera2D default)
var zoom_min = 0.3     # Maximum zoom in (close up, about house size)
var zoom_max = 1.5     # Maximum zoom out (see more of the world)
var zoom_speed = 0.1   # How much to zoom per scroll

func _ready():
	# Initialize target to current position so we don't drift at start
	target_position = position
	_load_player_sprite()

func _load_player_sprite():
	# Load sprite from player character data
	var player_data = DatabaseManager.characters.get_player()
	if player_data and character_renderer:
		character_renderer.load_from_character_data(player_data)

func _unhandled_input(event):
	# Mouse Movement
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			target_position = get_global_mouse_position()
		# Mouse wheel zoom - only if not over UI
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if not _is_mouse_over_ui():
				_zoom_camera(zoom_speed)  # Scroll up = zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if not _is_mouse_over_ui():
				_zoom_camera(-zoom_speed)  # Scroll down = zoom out
			
	# Keyboard Interaction
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_try_interact()

func _is_mouse_over_ui() -> bool:
	# Check if mouse is over any visible UI window (not HUD buttons)
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Find the World node and its CanvasLayer
	var world = get_tree().current_scene
	if not world:
		return false
	
	var canvas_layer = world.get_node_or_null("CanvasLayer")
	if not canvas_layer:
		return false
	
	# Check each UI child in the CanvasLayer
	for child in canvas_layer.get_children():
		if not child is Control or not child.visible:
			continue
		
		# Skip the HUD - it has mouse_filter = IGNORE and covers whole screen
		if child.name == "HUD":
			continue
		
		# For windows with Panel children, check the Panel's rect
		var panel = child.get_node_or_null("Panel")
		if panel and panel is Control:
			var rect = Rect2(panel.global_position, panel.size)
			if rect.has_point(mouse_pos):
				return true
	
	return false

func _zoom_camera(delta: float):
	zoom_level = clamp(zoom_level + delta, zoom_min, zoom_max)
	if camera:
		camera.zoom = Vector2(zoom_level, zoom_level)

func _try_interact():
	# Find the best interactable based on distance AND facing direction
	var interactables = get_tree().get_nodes_in_group("interactable")
	var buildings = get_tree().get_nodes_in_group("Building")
	
	var best_target = null
	var best_score = -1.0
	
	# Check NPCs and other interactables
	for node in interactables:
		if node is Node2D:
			var score = _get_interaction_score(node.global_position)
			if score > best_score:
				best_score = score
				best_target = node
	
	# Check building doors (they handle their own E press, but we want to know if we should block NPC interaction)
	var door_score = _get_best_door_score(buildings)
	
	# If a door has a better score than any NPC, don't emit interaction signal
	# (let the building handle it)
	if door_score > best_score:
		# Door wins - don't interact with NPC, building script will handle door
		print("Facing door - door interaction takes priority")
		return
	
	if best_target:
		emit_signal("interaction_requested", best_target)
	else:
		print("Nothing to interact with nearby.")

func _get_best_door_score(buildings: Array) -> float:
	var best_door_score = -1.0
	
	for building in buildings:
		if building.has_method("get_door_position"):
			var door_pos = building.get_door_position()
			var score = _get_interaction_score(door_pos)
			if score > best_door_score:
				best_door_score = score
		else:
			# Fallback: estimate door position (bottom center of building)
			var door_pos = building.global_position + Vector2(0, 120)
			var score = _get_interaction_score(door_pos)
			if score > best_door_score:
				best_door_score = score
	
	return best_door_score

func _get_interaction_score(target_pos: Vector2) -> float:
	# Returns a score from 0 to 1 based on distance and facing direction
	# Higher score = better interaction candidate
	
	var dist = global_position.distance_to(target_pos)
	
	# Must be within range
	if dist > interact_range:
		return -1.0
	
	# Calculate direction to target
	var dir_to_target = (target_pos - global_position).normalized()
	
	# Calculate angle between facing direction and direction to target
	var angle = rad_to_deg(facing_direction.angle_to(dir_to_target))
	angle = abs(angle)
	
	# Must be within facing cone
	if angle > facing_cone_angle / 2.0:
		return -1.0
	
	# Score based on:
	# - Distance (closer = better): 0.0 to 0.5
	# - Angle (more centered = better): 0.0 to 0.5
	var distance_score = 1.0 - (dist / interact_range)  # 1.0 when close, 0.0 at max range
	var angle_score = 1.0 - (angle / (facing_cone_angle / 2.0))  # 1.0 when centered, 0.0 at edge
	
	return (distance_score * 0.4) + (angle_score * 0.6)  # Weight angle more than distance

func _physics_process(_delta):
	var current_pos = global_position
	var was_moving = is_moving
	
	# Check if we are close enough to the target to stop
	if current_pos.distance_to(target_position) > 5.0:
		var direction = (target_position - current_pos).normalized()
		velocity = direction * speed
		is_moving = true
		
		# Update facing direction based on movement
		facing_direction = direction
		
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		is_moving = false
	
	# Update character animation
	if character_renderer:
		character_renderer.update_animation(is_moving, facing_direction)

func get_facing_direction() -> Vector2:
	return facing_direction

func is_facing(target_pos: Vector2, tolerance_degrees: float = 45.0) -> bool:
	var dir_to_target = (target_pos - global_position).normalized()
	var angle = rad_to_deg(abs(facing_direction.angle_to(dir_to_target)))
	return angle <= tolerance_degrees
