extends RefCounted

# NPC Known Facts Repository
# Manages facts that NPCs know about the world

var _store

func _init(store):
	_store = store

func _get_timestamp() -> float:
	return Time.get_unix_time_from_system()

func get_all() -> Array:
	return _store.get_table("npc_known_facts")

func get_by_npc(npc_id: String) -> Array:
	var result = []
	for fact in get_all():
		if fact.get("npc_id") == npc_id:
			result.append(fact)
	# Sort by learned_at descending (most recent first)
	result.sort_custom(func(a, b): return a.get("learned_at", 0) > b.get("learned_at", 0))
	return result

func get_by_npc_and_type(npc_id: String, fact_type: String) -> Array:
	var result = []
	for fact in get_all():
		if fact.get("npc_id") == npc_id and fact.get("fact_type") == fact_type:
			result.append(fact)
	return result

func create(npc_id: String, fact_type: String, content: String, source: String = "experience") -> String:
	var id = "fact_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 10000)
	var now = _get_timestamp()
	
	var fact = {
		"id": id,
		"npc_id": npc_id,
		"fact_type": fact_type,  # "world", "character", "location", "event", "self"
		"content": content,
		"source": source,  # "experience", "told_by_player", "told_by_npc", "initial"
		"source_id": "",  # ID of who told them, if applicable
		"learned_at": now,
		"updated_at": now,
		"superseded": false  # True if newer information invalidates this
	}
	
	get_all().append(fact)
	_store.save_data()
	return id

func update(id: String, updates: Dictionary):
	var facts = get_all()
	for i in range(facts.size()):
		if facts[i].get("id") == id:
			for key in updates.keys():
				facts[i][key] = updates[key]
			facts[i]["updated_at"] = _get_timestamp()
			_store.save_data()
			return

func supersede_facts(npc_id: String, fact_type: String, new_content: String, source: String = "experience"):
	# Mark old facts of this type as superseded and add new one
	for fact in get_by_npc_and_type(npc_id, fact_type):
		if not fact.get("superseded", false):
			update(fact["id"], {"superseded": true})
	
	return create(npc_id, fact_type, new_content, source)

func delete(id: String):
	var facts = get_all()
	for i in range(facts.size() - 1, -1, -1):
		if facts[i].get("id") == id:
			facts.remove_at(i)
			_store.save_data()
			return

func get_active_facts_text(npc_id: String) -> String:
	var facts = get_by_npc(npc_id)
	var lines = []
	
	for fact in facts:
		if not fact.get("superseded", false):
			lines.append("- " + fact.get("content", ""))
	
	if lines.is_empty():
		return "No known facts."
	
	return "\n".join(lines)

