extends RefCounted

# NPC Context Builder
# Assembles all context needed for NPC conversations from various data sources

var _templates

func _init():
	_templates = preload("res://src/services/prompt_templates.gd").new()

func build_system_prompt(npc_id: String, player_id: String) -> String:
	var npc_data = DatabaseManager.characters.get_by_id(npc_id)
	var player_data = DatabaseManager.characters.get_by_id(player_id)
	
	if not npc_data or not player_data:
		return "You are an NPC. Respond in character."
	
	var variables = {
		# NPC Identity
		"npc_name": npc_data.get("name", "Unknown"),
		"npc_gender": npc_data.get("gender", "Unknown"),
		"npc_description": npc_data.get("description", "A mysterious figure."),
		"npc_backstory": npc_data.get("backstory", "Unknown origins."),
		"npc_occupation": npc_data.get("occupation", "Unknown"),
		"npc_daily_routine": npc_data.get("daily_routine", "Unknown routine."),
		"npc_interesting_fact": npc_data.get("interesting_fact", ""),
		
		# Physical appearance
		"npc_height": npc_data.get("height", "average height"),
		"npc_weight": npc_data.get("weight", "average build"),
		"npc_age": str(npc_data.get("age", "unknown age")),
		"npc_eye_color": npc_data.get("eye_color", "unknown"),
		"npc_hair_color": npc_data.get("hair_color", "unknown"),
		
		# Stats
		"npc_health": str(npc_data.get("health", 100)),
		"npc_max_health": str(npc_data.get("max_health", 100)),
		"npc_stamina": str(npc_data.get("stamina", 50)),
		"npc_strength": str(npc_data.get("strength", 10)),
		"npc_dexterity": str(npc_data.get("dexterity", 10)),
		"npc_intelligence": str(npc_data.get("intelligence", 10)),
		"npc_charisma": str(npc_data.get("charisma", 10)),
		
		# Player
		"player_name": player_data.get("name", "Adventurer"),
		"player_description": player_data.get("description", "A traveler."),
		
		# Dynamic content
		"npc_inventory": _build_inventory_text(npc_id, npc_data.get("can_trade", false)),
		"world_knowledge": _build_world_knowledge_text(npc_id),
		"npc_memories": _build_memories_text(npc_id),
		"relationship_context": _build_relationship_text(npc_id, player_id),
		"conversation_summary": _build_conversation_summary(npc_id, player_id),
		"speculation_rules": _get_speculation_rules()
	}
	
	return _templates.get_and_render("npc", "talk_grounded", variables)

func build_greeting_prompt(npc_id: String, player_id: String) -> String:
	var npc_data = DatabaseManager.characters.get_by_id(npc_id)
	var player_data = DatabaseManager.characters.get_by_id(player_id)
	
	if not npc_data or not player_data:
		return ""
	
	var variables = {
		"npc_name": npc_data.get("name", "Unknown"),
		"npc_description": npc_data.get("description", "A mysterious figure."),
		"npc_occupation": npc_data.get("occupation", "Unknown"),
		"player_name": player_data.get("name", "Adventurer"),
		"relationship_context": _build_relationship_text(npc_id, player_id),
		"conversation_summary": _build_conversation_summary(npc_id, player_id)
	}
	
	return _templates.get_and_render("npc", "greeting", variables)

func build_summarization_prompt(npc_id: String, player_id: String, messages: Array) -> String:
	var npc_data = DatabaseManager.characters.get_by_id(npc_id)
	var player_data = DatabaseManager.characters.get_by_id(player_id)
	
	if not npc_data or not player_data:
		return ""
	
	var conversation_text = ""
	for msg in messages:
		var speaker = player_data.get("name", "Player") if msg.get("role") == "user" else npc_data.get("name", "NPC")
		conversation_text += speaker + ": " + msg.get("content", "") + "\n"
	
	var variables = {
		"npc_name": npc_data.get("name", "Unknown"),
		"player_name": player_data.get("name", "Adventurer"),
		"conversation_text": conversation_text
	}
	
	return _templates.get_and_render("npc", "summarize_conversation", variables)

func _build_inventory_text(npc_id: String, can_trade: bool) -> String:
	if not can_trade:
		return "You are not a merchant and do not trade goods."
	
	var items = DatabaseManager.inventory.get_by_owner(npc_id, false)  # Don't include equipped
	
	if items.is_empty():
		return "You are a merchant, but currently have no items for trade."
	
	var lines = ["You are a merchant. Your current inventory for trade:"]
	for item in items:
		var name = item.get("name", "Unknown Item")
		var item_type = item.get("type", "MISC")
		var desc = item.get("description", "")
		lines.append("- " + name + " (" + item_type + "): " + desc)
	
	return "\n".join(lines)

func _build_world_knowledge_text(npc_id: String) -> String:
	var facts_text = DatabaseManager.npc_facts.get_active_facts_text(npc_id)
	
	if facts_text == "No known facts.":
		return "You know very little about the world around you."
	
	return "What you know about the world:\n" + facts_text

func _build_memories_text(npc_id: String) -> String:
	var memories_text = DatabaseManager.npc_memories.get_memories_text(npc_id, 10)
	
	if memories_text == "No memories recorded.":
		return "You have no notable memories of past events yet."
	
	return "Your memories of past events:\n" + memories_text

func _build_relationship_text(npc_id: String, player_id: String) -> String:
	var has_met = DatabaseManager.conversations.has_previous_conversations(npc_id, player_id)
	
	if not has_met:
		return "You have never met this person before. This is your first interaction."
	
	return DatabaseManager.relationships.get_relationship_context_for_prompt(npc_id, player_id)

func _build_conversation_summary(npc_id: String, player_id: String) -> String:
	var summary = DatabaseManager.conversations.get_summary(npc_id, player_id)
	
	if summary == "":
		var has_met = DatabaseManager.conversations.has_previous_conversations(npc_id, player_id)
		if has_met:
			return "You have spoken before, but the details are hazy."
		return "This is your first conversation."
	
	return "Previous conversations summary: " + summary

func _get_speculation_rules() -> String:
	var mode = DatabaseManager.settings.get_speculation_mode()
	
	if mode == "strict":
		return _templates.get_template("npc", "speculation_strict")
	else:
		return _templates.get_template("npc", "speculation_speculative")
