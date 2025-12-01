extends RefCounted

# ActionPromptBuilder - Builds the action context section for LLM prompts
# Combines action registry, world context, and response format instructions

var _action_registry
var _world_scanner

func _init():
	_action_registry = load("res://src/systems/action_registry.gd").new()
	_world_scanner = load("res://src/components/world_scanner.gd").new()

func initialize(scene_root: Node, tilemap: TileMapLayer = null):
	_world_scanner.initialize(scene_root, tilemap)

# Build the complete action context for an NPC's LLM prompt
func build_action_context(npc: Node2D, include_world_context: bool = true) -> String:
	var sections = []
	
	# World context
	if include_world_context:
		sections.append(_world_scanner.get_context_for_prompt(npc))
	
	# Available actions
	sections.append("")
	sections.append(_action_registry.get_actions_for_prompt())
	
	# Response format instructions
	sections.append("")
	sections.append(_get_response_format_instructions())
	
	return "\n".join(sections)

func _get_response_format_instructions() -> String:
	return """## Response Format

You must respond with valid JSON in this exact format:

```json
{
  "thought": "Your internal reasoning about the situation and what you should do",
  "dialogue": "What you say out loud to the player (can be empty string if just acting)",
  "actions": [
    {
      "sequence": 1,
      "action": "action_name",
      "params": {
        "param1": value1,
        "param2": value2
      }
    }
  ]
}
```

Rules:
- "thought" is your private reasoning (player won't see this)
- "dialogue" is what you say out loud
- "actions" is an ordered list of actions to perform
- Each action needs a "sequence" number (1, 2, 3...) for execution order
- Actions execute one at a time - next action waits for previous to complete
- You can include 0 actions if you just want to speak
- All coordinates are in pixels, not tiles

Example - Moving to the player:
```json
{
  "thought": "The player asked me to come closer, I should walk to them",
  "dialogue": "On my way!",
  "actions": [
    {
      "sequence": 1,
      "action": "move",
      "params": {
        "target_x": 150,
        "target_y": 200
      }
    }
  ]
}
```

Example - Just speaking (no action):
```json
{
  "thought": "The player is just making conversation",
  "dialogue": "It's a lovely day today, isn't it?",
  "actions": []
}
```"""

# Get just the world context as JSON for compact prompts
func get_world_context_json(npc: Node2D) -> String:
	return _world_scanner.get_context_json(npc)

# Get just the action schema for structured output models
func get_action_schema() -> Dictionary:
	return _action_registry.get_actions_schema()

# Get the world scanner for direct access
func get_world_scanner():
	return _world_scanner

# Get the action registry for direct access
func get_action_registry():
	return _action_registry

