extends RefCounted

# ActionResolver - Parses LLM responses and transforms them into executable actions
# Validates actions against the ActionRegistry and prepares them for execution

var _action_registry

func _init():
	_action_registry = load("res://src/systems/action_registry.gd").new()

# Parse an LLM response JSON string into a structured action list
func parse_response(response_json: String) -> Dictionary:
	var result = {
		"success": false,
		"thought": "",
		"dialogue": "",
		"actions": [],
		"error": ""
	}
	
	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(response_json)
	
	if parse_result != OK:
		result.error = "Failed to parse JSON: " + json.get_error_message()
		print("ActionResolver: ", result.error)
		return result
	
	var data = json.data
	if not data is Dictionary:
		result.error = "Response is not a JSON object"
		print("ActionResolver: ", result.error)
		return result
	
	# Extract thought and dialogue
	result.thought = data.get("thought", "")
	result.dialogue = data.get("dialogue", "")
	
	# Parse actions
	var raw_actions = data.get("actions", [])
	if not raw_actions is Array:
		result.error = "Actions must be an array"
		print("ActionResolver: ", result.error)
		return result
	
	# Validate and sort actions by sequence
	var validated_actions = []
	for raw_action in raw_actions:
		var validated = _validate_action(raw_action)
		if validated.valid:
			validated_actions.append(validated)
		else:
			print("ActionResolver: Skipping invalid action - ", validated.error)
	
	# Sort by sequence number
	validated_actions.sort_custom(func(a, b): return a.sequence < b.sequence)
	
	result.actions = validated_actions
	result.success = true
	
	return result

# Validate a single action against the registry
func _validate_action(raw_action: Dictionary) -> Dictionary:
	var validated = {
		"valid": false,
		"sequence": 0,
		"action": "",
		"params": {},
		"error": ""
	}
	
	# Check required fields
	if not raw_action.has("action"):
		validated.error = "Action missing 'action' field"
		return validated
	
	var action_name = raw_action.get("action", "")
	validated.action = action_name
	validated.sequence = raw_action.get("sequence", 1)
	
	# Check if action exists in registry
	if not _action_registry.has_action(action_name):
		validated.error = "Unknown action: " + action_name
		return validated
	
	var action_def = _action_registry.get_action(action_name)
	var required_params = action_def.get("parameters", {})
	var provided_params = raw_action.get("params", {})
	
	# Validate parameters
	for param_name in required_params.keys():
		if not provided_params.has(param_name):
			validated.error = "Missing required parameter: " + param_name
			return validated
		
		var param_def = required_params[param_name]
		var param_value = provided_params[param_name]
		
		# Type check
		var expected_type = param_def.get("type", "string")
		if not _check_param_type(param_value, expected_type):
			validated.error = "Parameter '%s' has wrong type (expected %s)" % [param_name, expected_type]
			return validated
		
		validated.params[param_name] = param_value
	
	validated.valid = true
	return validated

func _check_param_type(value, expected_type: String) -> bool:
	match expected_type:
		"int":
			return value is int or value is float
		"float":
			return value is int or value is float
		"string":
			return value is String
		"bool":
			return value is bool
		_:
			return true

# Get the executor function name for an action
func get_executor(action_name: String) -> String:
	var action_def = _action_registry.get_action(action_name)
	return action_def.get("executor", "")

# Get the action registry for prompt building
func get_registry():
	return _action_registry

