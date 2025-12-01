extends RefCounted

# NPCActionExecutor - Executes actions on NPCs
# Handles action queues and sequential execution

signal action_started(npc: Node2D, action: Dictionary)
signal action_completed(npc: Node2D, action: Dictionary, success: bool)
signal all_actions_completed(npc: Node2D)

var _action_resolver
var _current_action: Dictionary = {}
var _action_queue: Array = []
var _executing: bool = false
var _current_npc: Node2D = null

func _init():
	_action_resolver = load("res://src/systems/action_resolver.gd").new()

# Queue actions from an LLM response for a specific NPC
func queue_actions_from_response(npc: Node2D, response_json: String) -> Dictionary:
	var parsed = _action_resolver.parse_response(response_json)
	
	if not parsed.success:
		return {
			"success": false,
			"error": parsed.error,
			"dialogue": ""
		}
	
	if parsed.actions.size() > 0:
		_current_npc = npc
		_action_queue = parsed.actions.duplicate()
		_execute_next_action()
	
	return {
		"success": true,
		"dialogue": parsed.dialogue,
		"thought": parsed.thought,
		"action_count": parsed.actions.size()
	}

# Execute the next action in the queue
func _execute_next_action():
	if _action_queue.is_empty():
		_executing = false
		if _current_npc:
			all_actions_completed.emit(_current_npc)
		_current_npc = null
		return
	
	_executing = true
	_current_action = _action_queue.pop_front()
	
	print("NPCActionExecutor: Executing action %d - %s" % [
		_current_action.sequence, _current_action.action
	])
	
	action_started.emit(_current_npc, _current_action)
	
	# Execute the action
	var success = _execute_action(_current_npc, _current_action)
	
	if not success:
		print("NPCActionExecutor: Action failed, continuing to next")
		action_completed.emit(_current_npc, _current_action, false)
		_execute_next_action()

# Execute a single action on an NPC
func _execute_action(npc: Node2D, action: Dictionary) -> bool:
	var action_name = action.action
	var params = action.params
	
	match action_name:
		"move":
			return _execute_move(npc, params)
		"wait":
			return _execute_wait(npc, params)
		"face":
			return _execute_face(npc, params)
		_:
			print("NPCActionExecutor: Unknown action - ", action_name)
			return false

# Execute move action - same as player click-to-move
func _execute_move(npc: Node2D, params: Dictionary) -> bool:
	var target_x = params.get("target_x", 0.0)
	var target_y = params.get("target_y", 0.0)
	var target_pos = Vector2(target_x, target_y)
	
	print("NPCActionExecutor: Moving NPC to (%d, %d)" % [target_x, target_y])
	
	# Check if NPC has the target_position property (like player does)
	if "target_position" in npc:
		npc.target_position = target_pos
		
		# Connect to monitor when movement completes
		_monitor_movement(npc, target_pos)
		return true
	else:
		# Fallback: directly set position (instant teleport)
		npc.global_position = target_pos
		action_completed.emit(npc, _current_action, true)
		_execute_next_action()
		return true

# Monitor NPC movement and trigger completion when arrived
func _monitor_movement(npc: Node2D, target: Vector2):
	# Create a timer to check movement progress
	var scene_tree = npc.get_tree()
	if not scene_tree:
		action_completed.emit(npc, _current_action, false)
		_execute_next_action()
		return
	
	var timer = scene_tree.create_timer(0.1)
	timer.timeout.connect(_check_movement_progress.bind(npc, target))

func _check_movement_progress(npc: Node2D, target: Vector2):
	if not is_instance_valid(npc):
		action_completed.emit(npc, _current_action, false)
		_execute_next_action()
		return
	
	var distance = npc.global_position.distance_to(target)
	
	if distance < 5.0:  # Close enough
		print("NPCActionExecutor: NPC arrived at destination")
		action_completed.emit(npc, _current_action, true)
		_execute_next_action()
	else:
		# Keep checking
		var scene_tree = npc.get_tree()
		if scene_tree:
			var timer = scene_tree.create_timer(0.1)
			timer.timeout.connect(_check_movement_progress.bind(npc, target))
		else:
			action_completed.emit(npc, _current_action, false)
			_execute_next_action()

# Execute wait action
func _execute_wait(npc: Node2D, params: Dictionary) -> bool:
	var duration = clamp(params.get("duration", 1.0), 0.5, 5.0)
	
	print("NPCActionExecutor: Waiting for ", duration, " seconds")
	
	var scene_tree = npc.get_tree()
	if not scene_tree:
		return false
	
	var timer = scene_tree.create_timer(duration)
	timer.timeout.connect(func():
		action_completed.emit(npc, _current_action, true)
		_execute_next_action()
	)
	
	return true

# Execute face action
func _execute_face(npc: Node2D, params: Dictionary) -> bool:
	var target_x = params.get("target_x", 0.0)
	var target_y = params.get("target_y", 0.0)
	var target_pos = Vector2(target_x, target_y)
	
	var direction = (target_pos - npc.global_position).normalized()
	
	# Set facing direction if NPC supports it
	if "facing_direction" in npc:
		npc.facing_direction = direction
	
	print("NPCActionExecutor: NPC facing toward (%d, %d)" % [target_x, target_y])
	
	action_completed.emit(npc, _current_action, true)
	_execute_next_action()
	return true

# Check if currently executing actions
func is_executing() -> bool:
	return _executing

# Cancel all queued actions
func cancel_actions():
	_action_queue.clear()
	_executing = false
	_current_npc = null

# Get the action resolver for prompt building
func get_resolver():
	return _action_resolver

