extends RefCounted

# ActionRegistry - Defines available actions NPCs can take
# Each action has a schema describing its parameters and how to execute it

# Action definition structure:
# {
#   "name": "action_name",
#   "description": "What this action does (for LLM context)",
#   "parameters": {
#     "param_name": {"type": "int/float/string/vector2", "description": "..."}
#   },
#   "executor": "function_name_to_call"
# }

var _actions: Dictionary = {}

func _init():
	_register_default_actions()

func _register_default_actions():
	# Move action - same as player click-to-move
	register_action({
		"name": "move",
		"description": "Move to a specific location in the world. The character will walk to the target position if a path exists.",
		"parameters": {
			"target_x": {
				"type": "float",
				"description": "The X coordinate (in pixels) to move to"
			},
			"target_y": {
				"type": "float",
				"description": "The Y coordinate (in pixels) to move to"
			}
		},
		"executor": "execute_move"
	})
	
	# Wait action - pause before next action
	register_action({
		"name": "wait",
		"description": "Wait for a short duration before taking the next action.",
		"parameters": {
			"duration": {
				"type": "float",
				"description": "How long to wait in seconds (0.5 to 5.0)"
			}
		},
		"executor": "execute_wait"
	})
	
	# Face direction action
	register_action({
		"name": "face",
		"description": "Turn to face a specific direction or location.",
		"parameters": {
			"target_x": {
				"type": "float",
				"description": "The X coordinate to face toward"
			},
			"target_y": {
				"type": "float",
				"description": "The Y coordinate to face toward"
			}
		},
		"executor": "execute_face"
	})

func register_action(action_def: Dictionary):
	var name = action_def.get("name", "")
	if name.is_empty():
		push_error("ActionRegistry: Cannot register action without name")
		return
	
	_actions[name] = action_def
	print("ActionRegistry: Registered action '", name, "'")

func get_action(action_name: String) -> Dictionary:
	return _actions.get(action_name, {})

func get_all_actions() -> Dictionary:
	return _actions

func get_action_names() -> Array:
	return _actions.keys()

func has_action(action_name: String) -> bool:
	return _actions.has(action_name)

# Generate LLM-friendly description of all available actions
func get_actions_for_prompt() -> String:
	var lines = ["Available actions you can take:"]
	
	for action_name in _actions.keys():
		var action = _actions[action_name]
		lines.append("")
		lines.append("- " + action_name + ": " + action.get("description", ""))
		
		var params = action.get("parameters", {})
		if not params.is_empty():
			lines.append("  Parameters:")
			for param_name in params.keys():
				var param = params[param_name]
				lines.append("    - " + param_name + " (" + param.get("type", "unknown") + "): " + param.get("description", ""))
	
	return "\n".join(lines)

# Generate JSON schema for structured output
func get_actions_schema() -> Dictionary:
	var action_schemas = []
	
	for action_name in _actions.keys():
		var action = _actions[action_name]
		var param_props = {}
		var required_params = []
		
		for param_name in action.get("parameters", {}).keys():
			var param = action["parameters"][param_name]
			var json_type = "number"
			match param.get("type", "string"):
				"int", "float":
					json_type = "number"
				"string":
					json_type = "string"
				"bool":
					json_type = "boolean"
			
			param_props[param_name] = {
				"type": json_type,
				"description": param.get("description", "")
			}
			required_params.append(param_name)
		
		action_schemas.append({
			"action": action_name,
			"params": param_props,
			"required": required_params
		})
	
	return {
		"type": "object",
		"properties": {
			"thought": {
				"type": "string",
				"description": "Your internal reasoning about what to do"
			},
			"dialogue": {
				"type": "string",
				"description": "What you say out loud (can be empty if just acting)"
			},
			"actions": {
				"type": "array",
				"description": "List of actions to take, in order",
				"items": {
					"type": "object",
					"properties": {
						"sequence": {"type": "integer", "description": "Order of execution (1, 2, 3...)"},
						"action": {"type": "string", "description": "Action name"},
						"params": {"type": "object", "description": "Action parameters"}
					}
				}
			}
		}
	}

