extends Node
class_name CharacterRenderer

# CharacterRenderer - Reusable component for character sprite animation
# Handles loading sprite sheets, creating animations, and switching based on movement/direction
#
# Usage:
#   1. Add this as a child node to any CharacterBody2D
#   2. Assign the animated_sprite reference
#   3. Call load_sprite(sprite_id) to load a character's appearance
#   4. Call update_animation(is_moving, facing_direction) each frame

signal sprite_loaded(sprite_id: String)
signal animation_changed(animation_name: String)

# Reference to the AnimatedSprite2D node (set via inspector or code)
@export var animated_sprite: AnimatedSprite2D

# Current state
var current_sprite_id: String = ""
var current_direction: String = "down"
var is_moving: bool = false

# Animation speed settings
var walk_animation_speed: float = 8.0
var idle_animation_speed: float = 1.0

func _ready():
	# Try to find AnimatedSprite2D in parent if not set
	if not animated_sprite:
		var parent = get_parent()
		if parent:
			animated_sprite = parent.get_node_or_null("AnimatedSprite2D")

# Load a sprite sheet by ID from the sprite registry
func load_sprite(sprite_id: String) -> bool:
	if not animated_sprite:
		push_error("CharacterRenderer: No AnimatedSprite2D assigned")
		return false
	
	var sprite_data = DatabaseManager.sprites.get_or_default(sprite_id)
	if sprite_data.is_empty():
		push_error("CharacterRenderer: Sprite not found: " + sprite_id)
		return false
	
	var texture = load(sprite_data["path"])
	if not texture:
		push_error("CharacterRenderer: Could not load texture: " + sprite_data["path"])
		return false
	
	_create_animations(texture, sprite_data)
	current_sprite_id = sprite_id
	sprite_loaded.emit(sprite_id)
	
	# Start with idle down animation
	_play_animation("idle_down")
	return true

# Load sprite for a character from their database record
func load_from_character_data(char_data: Dictionary) -> bool:
	var sprite_id = char_data.get("sprite", DatabaseManager.sprites.get_default_id())
	return load_sprite(sprite_id)

# Update animation based on movement state and facing direction
func update_animation(moving: bool, facing_direction: Vector2):
	var new_direction = _vector_to_direction(facing_direction)
	var state_changed = (moving != is_moving) or (new_direction != current_direction)
	
	is_moving = moving
	current_direction = new_direction
	
	if state_changed:
		var anim_prefix = "walk_" if is_moving else "idle_"
		var anim_name = anim_prefix + current_direction
		_play_animation(anim_name)

# Set facing direction without changing movement state
func set_direction(facing_direction: Vector2):
	var new_direction = _vector_to_direction(facing_direction)
	if new_direction != current_direction:
		current_direction = new_direction
		var anim_prefix = "walk_" if is_moving else "idle_"
		_play_animation(anim_prefix + current_direction)

# Set moving state without changing direction
func set_moving(moving: bool):
	if moving != is_moving:
		is_moving = moving
		var anim_prefix = "walk_" if is_moving else "idle_"
		_play_animation(anim_prefix + current_direction)

# Internal: Create all animations from sprite sheet data
func _create_animations(texture: Texture2D, sprite_data: Dictionary):
	var frames = SpriteFrames.new()
	
	var frame_w = sprite_data.get("frame_width", 48)
	var frame_h = sprite_data.get("frame_height", 96)
	var cols = sprite_data.get("columns", 3)
	var directions = sprite_data.get("directions", {"down": 0, "left": 1, "right": 2, "up": 3})
	
	# Create animations for each direction
	for dir_name in directions.keys():
		var row = directions[dir_name]
		
		# Walk animation (all frames)
		var walk_anim = "walk_" + dir_name
		frames.add_animation(walk_anim)
		frames.set_animation_speed(walk_anim, walk_animation_speed)
		frames.set_animation_loop(walk_anim, true)
		
		for col in range(cols):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
			frames.add_frame(walk_anim, atlas)
		
		# Idle animation (middle frame)
		var idle_anim = "idle_" + dir_name
		frames.add_animation(idle_anim)
		frames.set_animation_speed(idle_anim, idle_animation_speed)
		frames.set_animation_loop(idle_anim, false)
		
		var idle_atlas = AtlasTexture.new()
		idle_atlas.atlas = texture
		# Use middle frame (index 1) for idle
		var idle_col = mini(1, cols - 1)
		idle_atlas.region = Rect2(idle_col * frame_w, row * frame_h, frame_w, frame_h)
		frames.add_frame(idle_anim, idle_atlas)
	
	animated_sprite.sprite_frames = frames

# Internal: Play an animation by name
func _play_animation(anim_name: String):
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
			animation_changed.emit(anim_name)
	else:
		push_warning("CharacterRenderer: Animation not found: " + anim_name)

# Internal: Convert facing vector to direction string
func _vector_to_direction(facing: Vector2) -> String:
	if abs(facing.x) > abs(facing.y):
		return "right" if facing.x > 0 else "left"
	else:
		return "down" if facing.y > 0 else "up"

# Get available sprite IDs (for editor tooling)
static func get_available_sprites() -> Array:
	if Engine.is_editor_hint():
		# In editor, load directly
		var repo = preload("res://src/core/repositories/sprite_sheet_repository.gd").new()
		return repo.get_all_ids()
	else:
		# At runtime, use DatabaseManager
		return DatabaseManager.sprites.get_all_ids()

