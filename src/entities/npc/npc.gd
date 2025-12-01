extends CharacterBody2D

@export var npc_id: String = "npc_merchant_1"
@export var speed: float = 200.0  # Slower than player

@onready var character_renderer = $CharacterRenderer
@onready var name_label = $NameLabel

# Movement - same pattern as player for action system compatibility
var target_position: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false

# Display name cached from character data
var display_name: String = "NPC"

func _ready():
	# Initialize target to current position
	target_position = global_position
	
	# Load name and sprite from database
	var char_data = DatabaseManager.characters.get_by_id(npc_id)
	if char_data:
		display_name = char_data.get("name", "NPC")
		name_label.text = display_name
		
		# Load sprite via CharacterRenderer
		if character_renderer:
			character_renderer.load_from_character_data(char_data)
	else:
		name_label.text = "NPC"
		# Load default sprite
		if character_renderer:
			character_renderer.load_sprite(DatabaseManager.sprites.get_default_id())

func _physics_process(_delta):
	var current_pos = global_position
	var was_moving = is_moving
	
	# Move toward target position (same logic as player)
	if current_pos.distance_to(target_position) > 5.0:
		var direction = (target_position - current_pos).normalized()
		velocity = direction * speed
		is_moving = true
		facing_direction = direction
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		is_moving = false
	
	# Update animation
	if character_renderer and (is_moving != was_moving or is_moving):
		character_renderer.update_animation(is_moving, facing_direction)

func set_moving(moving: bool):
	if is_moving != moving:
		is_moving = moving
		if character_renderer:
			character_renderer.update_animation(is_moving, facing_direction)

func interact():
	print("Interacting with NPC: ", npc_id)
	return self

func get_npc_id() -> String:
	return npc_id

func get_display_name() -> String:
	return display_name

func get_facing_direction() -> Vector2:
	return facing_direction

func set_facing_direction(dir: Vector2):
	facing_direction = dir.normalized()
	if character_renderer:
		character_renderer.update_animation(is_moving, facing_direction)

func face_towards(target_pos: Vector2):
	set_facing_direction(target_pos - global_position)

# Move to a specific position (used by action system)
func move_to(pos: Vector2):
	target_position = pos

# Stop all movement
func stop_moving():
	target_position = global_position
	velocity = Vector2.ZERO
	is_moving = false
