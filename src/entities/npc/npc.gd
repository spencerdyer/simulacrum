extends CharacterBody2D

@export var npc_id: String = "npc_merchant_1"
@export var npc_color: Color = Color(0.9, 0.6, 0.3, 1)

@onready var sprite = $Sprite2D
@onready var name_label = $NameLabel

# Facing direction (for future AI movement)
var facing_direction = Vector2.DOWN

func _ready():
	# Set color
	sprite.modulate = npc_color
	
	# Load name from database
	var char_data = DatabaseManager.characters.get_by_id(npc_id)
	if char_data:
		name_label.text = char_data.get("name", "NPC")
	else:
		name_label.text = "NPC"

func interact():
	print("Interacting with NPC: ", npc_id)
	return self

func get_npc_id() -> String:
	return npc_id

func get_facing_direction() -> Vector2:
	return facing_direction

func set_facing_direction(dir: Vector2):
	facing_direction = dir.normalized()

func face_towards(target_pos: Vector2):
	facing_direction = (target_pos - global_position).normalized()
