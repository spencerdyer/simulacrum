extends RefCounted

# Relationships Repository
# Manages bidirectional relationships between characters

var _store

# Default relationship attributes
const DEFAULT_ATTRIBUTES = {
	"trust": {"value": 5, "transparency": 5},
	"attraction": {"value": 5, "transparency": 5},
	"affection": {"value": 0, "transparency": 5},
	"loyalty": {"value": 5, "transparency": 5},
	"fear": {"value": 0, "transparency": 5}
}

func _init(store):
	_store = store

func _get_timestamp() -> float:
	return Time.get_unix_time_from_system()

func get_all() -> Array:
	return _store.get_table("relationships")

func get_relationship(possessor_id: String, target_id: String) -> Dictionary:
	for rel in get_all():
		if rel.get("possessor_id") == possessor_id and rel.get("target_id") == target_id:
			return rel
	return {}

func get_or_create(possessor_id: String, target_id: String) -> Dictionary:
	var existing = get_relationship(possessor_id, target_id)
	if not existing.is_empty():
		return existing
	
	var id = "rel_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	var now = _get_timestamp()
	
	var relationship = {
		"id": id,
		"possessor_id": possessor_id,
		"target_id": target_id,
		"attributes": DEFAULT_ATTRIBUTES.duplicate(true),
		"created_at": now,
		"updated_at": now
	}
	
	get_all().append(relationship)
	_store.save_data()
	return relationship

func get_attribute(possessor_id: String, target_id: String, attribute: String) -> Dictionary:
	var rel = get_or_create(possessor_id, target_id)
	var attrs = rel.get("attributes", {})
	return attrs.get(attribute, {"value": 5, "transparency": 5})

func set_attribute_value(possessor_id: String, target_id: String, attribute: String, value: int):
	value = clamp(value, 0, 10)
	var relationships = get_all()
	
	for i in range(relationships.size()):
		if relationships[i].get("possessor_id") == possessor_id and relationships[i].get("target_id") == target_id:
			if not relationships[i].has("attributes"):
				relationships[i]["attributes"] = DEFAULT_ATTRIBUTES.duplicate(true)
			if not relationships[i]["attributes"].has(attribute):
				relationships[i]["attributes"][attribute] = {"value": 5, "transparency": 5}
			
			relationships[i]["attributes"][attribute]["value"] = value
			relationships[i]["updated_at"] = _get_timestamp()
			_store.save_data()
			return
	
	# Create if doesn't exist
	var rel = get_or_create(possessor_id, target_id)
	set_attribute_value(possessor_id, target_id, attribute, value)

func set_attribute_transparency(possessor_id: String, target_id: String, attribute: String, transparency: int):
	transparency = clamp(transparency, 0, 10)
	var relationships = get_all()
	
	for i in range(relationships.size()):
		if relationships[i].get("possessor_id") == possessor_id and relationships[i].get("target_id") == target_id:
			if not relationships[i].has("attributes"):
				relationships[i]["attributes"] = DEFAULT_ATTRIBUTES.duplicate(true)
			if not relationships[i]["attributes"].has(attribute):
				relationships[i]["attributes"][attribute] = {"value": 5, "transparency": 5}
			
			relationships[i]["attributes"][attribute]["transparency"] = transparency
			relationships[i]["updated_at"] = _get_timestamp()
			_store.save_data()
			return

func modify_attribute(possessor_id: String, target_id: String, attribute: String, delta: int):
	var current = get_attribute(possessor_id, target_id, attribute)
	var new_value = clamp(current.get("value", 5) + delta, 0, 10)
	set_attribute_value(possessor_id, target_id, attribute, new_value)

func get_relationships_for(possessor_id: String) -> Array:
	var result = []
	for rel in get_all():
		if rel.get("possessor_id") == possessor_id:
			result.append(rel)
	return result

func get_relationships_toward(target_id: String) -> Array:
	var result = []
	for rel in get_all():
		if rel.get("target_id") == target_id:
			result.append(rel)
	return result

func get_relationship_text(possessor_id: String, target_id: String, include_hidden: bool = false) -> String:
	var rel = get_relationship(possessor_id, target_id)
	if rel.is_empty():
		return "No established relationship."
	
	var attrs = rel.get("attributes", {})
	var lines = []
	
	for attr_name in attrs.keys():
		var attr = attrs[attr_name]
		var value = attr.get("value", 5)
		var transparency = attr.get("transparency", 5)
		
		# Only include if transparency is high enough (or if we're including hidden)
		if include_hidden or transparency >= 5:
			var level = _value_to_level(value)
			lines.append(attr_name.capitalize() + ": " + level)
	
	if lines.is_empty():
		return "Relationship details are unclear."
	
	return "\n".join(lines)

func get_relationship_context_for_prompt(npc_id: String, player_id: String) -> String:
	var rel = get_or_create(npc_id, player_id)
	var attrs = rel.get("attributes", {})
	var lines = []
	
	lines.append("YOUR FEELINGS TOWARD THIS PERSON:")
	
	for attr_name in attrs.keys():
		var attr = attrs[attr_name]
		var value = attr.get("value", 5)
		var transparency = attr.get("transparency", 5)
		var level = _value_to_level(value)
		var openness = _transparency_to_text(transparency)
		
		lines.append("- " + attr_name.capitalize() + ": " + level + " (Openness about this: " + openness + ")")
	
	return "\n".join(lines)

func _value_to_level(value: int) -> String:
	if value <= 1:
		return "Very Low"
	elif value <= 3:
		return "Low"
	elif value <= 6:
		return "Moderate"
	elif value <= 8:
		return "High"
	else:
		return "Very High"

func _transparency_to_text(transparency: int) -> String:
	if transparency <= 2:
		return "You hide this completely"
	elif transparency <= 4:
		return "You rarely show this"
	elif transparency <= 6:
		return "You sometimes express this"
	elif transparency <= 8:
		return "You often express this"
	else:
		return "You openly express this"

