extends StaticBody2D

# Tavern - A larger building with an L-shaped layout and interior features

@export var building_name: String = "The Rusty Tankard"
@export var building_type: String = "tavern"
@export var door_locked: bool = false

@onready var door_sprite = $DoorSprite
@onready var door_area = $DoorArea
@onready var door_collision = $DoorCollision
@onready var label = $Label

var player_near_door = false
var door_open = false
var auto_close_timer = 0.0
const AUTO_CLOSE_DELAY = 2.0

# Door position offset from building center
const DOOR_OFFSET = Vector2(0, 190)

func _ready():
	if label:
		label.text = building_name
	
	if door_area:
		door_area.body_entered.connect(_on_door_area_entered)
		door_area.body_exited.connect(_on_door_area_exited)
	
	_close_door()

func _process(delta):
	if door_open and not player_near_door:
		auto_close_timer += delta
		if auto_close_timer >= AUTO_CLOSE_DELAY:
			_close_door()

func _unhandled_input(event):
	if player_near_door and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		var player = get_tree().get_first_node_in_group("Player")
		if player and player.has_method("is_facing"):
			var door_pos = get_door_position()
			if player.is_facing(door_pos, 70.0):
				_toggle_door()
				get_viewport().set_input_as_handled()

func _on_door_area_entered(body):
	if body.is_in_group("Player"):
		player_near_door = true
		auto_close_timer = 0.0

func _on_door_area_exited(body):
	if body.is_in_group("Player"):
		player_near_door = false
		auto_close_timer = 0.0

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
	
	if door_collision:
		door_collision.disabled = true
	
	if door_sprite:
		door_sprite.color = Color(0.3, 0.2, 0.1, 0.3)
	
	print(building_name, " door opened")

func _close_door():
	door_open = false
	
	if door_collision:
		door_collision.disabled = false
	
	if door_sprite:
		door_sprite.color = Color(0.4, 0.25, 0.1, 1.0)

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

