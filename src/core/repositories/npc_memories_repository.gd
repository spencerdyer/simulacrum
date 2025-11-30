extends RefCounted

# NPC Memories Repository
# Manages memories of events that NPCs have experienced

var _store

func _init(store):
	_store = store

func _get_timestamp() -> float:
	return Time.get_unix_time_from_system()

func get_all() -> Array:
	return _store.get_table("npc_memories")

func get_by_npc(npc_id: String) -> Array:
	var result = []
	for memory in get_all():
		if memory.get("npc_id") == npc_id:
			result.append(memory)
	# Sort by occurred_at descending (most recent first)
	result.sort_custom(func(a, b): return a.get("occurred_at", 0) > b.get("occurred_at", 0))
	return result

func get_by_npc_and_type(npc_id: String, memory_type: String) -> Array:
	var result = []
	for memory in get_all():
		if memory.get("npc_id") == npc_id and memory.get("memory_type") == memory_type:
			result.append(memory)
	return result

func create(npc_id: String, memory_type: String, memory_text: String, related_id: String = "") -> String:
	var id = "mem_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	var now = _get_timestamp()
	
	var memory = {
		"id": id,
		"npc_id": npc_id,
		"memory_type": memory_type,  # "trade", "conversation", "observation", "action"
		"memory_text": memory_text,
		"related_id": related_id,  # ID of related entity (player, location, etc.)
		"occurred_at": now,
		"updated_at": now
	}
	
	get_all().append(memory)
	_store.save_data()
	return id

func create_trade_memory(npc_id: String, other_party_name: String, items_given: Array, items_received: Array):
	var given_names = []
	var received_names = []
	
	for item in items_given:
		if item is Dictionary:
			given_names.append(item.get("name", "unknown item"))
		else:
			given_names.append(str(item))
	
	for item in items_received:
		if item is Dictionary:
			received_names.append(item.get("name", "unknown item"))
		else:
			received_names.append(str(item))
	
	var given_str = ", ".join(given_names) if given_names.size() > 0 else "nothing"
	var received_str = ", ".join(received_names) if received_names.size() > 0 else "nothing"
	
	var text = other_party_name + " traded with me. I gave them: " + given_str + ". I received: " + received_str + "."
	
	return create(npc_id, "trade", text)

func create_conversation_memory(npc_id: String, other_party_name: String):
	var text = "I had a conversation with " + other_party_name + "."
	return create(npc_id, "conversation", text)

func delete(id: String):
	var memories = get_all()
	for i in range(memories.size() - 1, -1, -1):
		if memories[i].get("id") == id:
			memories.remove_at(i)
			_store.save_data()
			return

func get_memories_text(npc_id: String, limit: int = 20) -> String:
	var memories = get_by_npc(npc_id)
	var lines = []
	
	var count = 0
	for memory in memories:
		if count >= limit:
			break
		lines.append("- " + memory.get("memory_text", ""))
		count += 1
	
	if lines.is_empty():
		return "No memories recorded."
	
	return "\n".join(lines)

