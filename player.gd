extends CharacterBody2D

@export var speed = 400.0
var target_position = Vector2.ZERO

func _ready():
	# Initialize target to current position so we don't drift at start
	target_position = position

func _unhandled_input(event):
	# We use _unhandled_input instead of _input so that if the UI
	# handles the click (e.g. pressing a button), this function won't fire.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Since we are using a camera, we need to make sure we get the global position correctly
			target_position = get_global_mouse_position()
			print("Target set to: ", target_position)

func _physics_process(_delta):
	var current_pos = global_position
	
	# Check if we are close enough to the target to stop
	if current_pos.distance_to(target_position) > 5.0:
		var direction = (target_position - current_pos).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Log location occasionally (or every frame if preferred, but this is spammy)
		# For now, let's print every 60 frames or so to keep log readable, 
		# or just rely on the 'Target set' log + visual verification.
		# User asked to "show some log of the player location as they're moving"
		print("Player moving... Pos: ", current_pos.snapped(Vector2(0.1, 0.1)))
	else:
		velocity = Vector2.ZERO
