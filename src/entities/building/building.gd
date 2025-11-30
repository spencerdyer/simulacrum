extends StaticBody2D

# Building - A structure in the world with walls and a door that opens/closes

@export var building_name: String = "Building"
@export var building_type: String = "house"  # tavern, church, shop, house
@export var building_color: Color = Color(0.5, 0.4, 0.3)  # Wall color
@export var floor_color: Color = Color(0.28, 0.22, 0.18)  # Floor color - darker wood tone
@export var door_locked: bool = false
@export var interior_location_id: String = ""  # Links to world_locations entry

@onready var floor_sprite = $Floor
@onready var wall_top = $WallTop
@onready var wall_left = $WallLeft
@onready var wall_right = $WallRight
@onready var wall_bottom_left = $WallBottomLeft
@onready var wall_bottom_right = $WallBottomRight
@onready var door_sprite = $DoorSprite
@onready var door_area = $DoorArea
@onready var door_collision = $DoorCollision
@onready var label = $Label

var player_near_door = false
var door_open = false
var auto_close_timer = 0.0
const AUTO_CLOSE_DELAY = 2.0  # Seconds before door auto-closes

# Door position offset from building center
const DOOR_OFFSET = Vector2(0, 120)

func _ready():
	# Set wall colors
	if wall_top: wall_top.color = building_color
	if wall_left: wall_left.color = building_color
	if wall_right: wall_right.color = building_color
	if wall_bottom_left: wall_bottom_left.color = building_color
	if wall_bottom_right: wall_bottom_right.color = building_color
	
	# Set floor color (slightly darker than walls)
	if floor_sprite:
		floor_sprite.color = floor_color
	
	# Set label
	if label:
		label.text = building_name
	
	# Connect door area signals
	if door_area:
		door_area.body_entered.connect(_on_door_area_entered)
		door_area.body_exited.connect(_on_door_area_exited)
	
	# Ensure door starts closed
	_close_door()

func _process(delta):
	# Auto-close door if open and no one nearby
	if door_open and not player_near_door:
		auto_close_timer += delta
		if auto_close_timer >= AUTO_CLOSE_DELAY:
			_close_door()

func _unhandled_input(event):
	if player_near_door and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		# Check if player is facing the door (from either inside or outside)
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("is_facing"):
			var door_pos = get_door_position()
			# Check if facing the door from either direction
			if player.is_facing(door_pos, 70.0):  # 70 degree tolerance for doors
				_toggle_door()
				get_viewport().set_input_as_handled()

func _on_door_area_entered(body):
	if body.is_in_group("Player"):
		player_near_door = true
		auto_close_timer = 0.0  # Reset auto-close timer

func _on_door_area_exited(body):
	if body.is_in_group("Player"):
		player_near_door = false
		auto_close_timer = 0.0  # Start counting for auto-close

func _toggle_door():
	if door_locked:
		print("The door to ", building_name, " is locked.")
		return
	
	if door_open:
		_close_door()
	else:
		_open_door()

func _open_door():
	if door_locked:
		return
	
	door_open = true
	auto_close_timer = 0.0
	
	# Hide the door collision so player can walk through
	if door_collision:
		door_collision.disabled = true
	
	# Change door appearance (make it look open - lighter/transparent)
	if door_sprite:
		door_sprite.color = Color(0.3, 0.2, 0.1, 0.3)  # Faded/open look
	
	print(building_name, " door opened")

func _close_door():
	door_open = false
	
	# Enable the door collision to block passage
	if door_collision:
		door_collision.disabled = false
	
	# Change door appearance back to closed
	if door_sprite:
		door_sprite.color = Color(0.4, 0.25, 0.1, 1.0)  # Solid closed look

func is_door_open() -> bool:
	return door_open

func get_door_position() -> Vector2:
	return global_position + DOOR_OFFSET

func unlock_door():
	door_locked = false

func lock_door():
	door_locked = true
	if door_open:
		_close_door()
