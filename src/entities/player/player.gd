extends CharacterBody2D

signal interaction_requested(target)

@export var speed = 400.0
var target_position = Vector2.ZERO

# Interaction
var interact_range = 100.0

func _ready():
	# Initialize target to current position so we don't drift at start
	target_position = position

func _unhandled_input(event):
	# Mouse Movement
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			target_position = get_global_mouse_position()
			# print("Target set to: ", target_position)
			
	# Keyboard Interaction
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_try_interact()

func _try_interact():
	# Find closest interactable
	var interactables = get_tree().get_nodes_in_group("interactable")
	var closest = null
	var min_dist = interact_range
	
	for node in interactables:
		if node is Node2D:
			var dist = global_position.distance_to(node.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = node
				
	if closest:
		emit_signal("interaction_requested", closest)
	else:
		print("Nothing to interact with nearby.")

func _physics_process(_delta):
	var current_pos = global_position
	
	# Check if we are close enough to the target to stop
	if current_pos.distance_to(target_position) > 5.0:
		var direction = (target_position - current_pos).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
