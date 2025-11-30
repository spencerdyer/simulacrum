extends RefCounted

# Conversation History Repository
# Manages conversation history between NPCs and players

var _store

func _init(store):
	_store = store

func _get_timestamp() -> float:
	return Time.get_unix_time_from_system()

func get_all() -> Array:
	return _store.get_table("conversation_history")

func get_by_pair(npc_id: String, player_id: String) -> Dictionary:
	for conv in get_all():
		if conv.get("npc_id") == npc_id and conv.get("player_id") == player_id:
			return conv
	return {}

func get_or_create(npc_id: String, player_id: String) -> Dictionary:
	var existing = get_by_pair(npc_id, player_id)
	if not existing.is_empty():
		return existing
	
	var id = "conv_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	var now = _get_timestamp()
	
	var conversation = {
		"id": id,
		"npc_id": npc_id,
		"player_id": player_id,
		"messages": [],  # Array of {role, content, timestamp}
		"summary": "",  # LLM-generated summary of past conversations
		"total_exchanges": 0,
		"first_conversation_at": now,
		"last_conversation_at": now,
		"updated_at": now
	}
	
	get_all().append(conversation)
	_store.save_data()
	return conversation

func add_message(npc_id: String, player_id: String, role: String, content: String):
	var conv = get_or_create(npc_id, player_id)
	var now = _get_timestamp()
	
	conv["messages"].append({
		"role": role,  # "user" or "assistant"
		"content": content,
		"timestamp": now
	})
	conv["total_exchanges"] += 1
	conv["last_conversation_at"] = now
	conv["updated_at"] = now
	
	_store.save_data()

func get_messages(npc_id: String, player_id: String) -> Array:
	var conv = get_by_pair(npc_id, player_id)
	if conv.is_empty():
		return []
	return conv.get("messages", [])

func get_recent_messages(npc_id: String, player_id: String, limit: int = 20) -> Array:
	var messages = get_messages(npc_id, player_id)
	if messages.size() <= limit:
		return messages
	return messages.slice(messages.size() - limit)

func update_summary(npc_id: String, player_id: String, summary: String):
	var conversations = get_all()
	for i in range(conversations.size()):
		if conversations[i].get("npc_id") == npc_id and conversations[i].get("player_id") == player_id:
			conversations[i]["summary"] = summary
			conversations[i]["updated_at"] = _get_timestamp()
			_store.save_data()
			return

func get_summary(npc_id: String, player_id: String) -> String:
	var conv = get_by_pair(npc_id, player_id)
	return conv.get("summary", "")

func has_previous_conversations(npc_id: String, player_id: String) -> bool:
	var conv = get_by_pair(npc_id, player_id)
	return conv.get("total_exchanges", 0) > 0

func clear_current_session(npc_id: String, player_id: String):
	# This would be called to mark end of a conversation session
	# Messages are kept, but we could add session markers if needed
	pass

func get_history_text(npc_id: String, player_id: String, include_summary: bool = true) -> String:
	var conv = get_by_pair(npc_id, player_id)
	if conv.is_empty():
		return "No previous conversations."
	
	var text = ""
	
	if include_summary and conv.get("summary", "") != "":
		text += "Summary of past conversations:\n" + conv["summary"] + "\n\n"
	
	return text

