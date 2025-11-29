extends RefCounted

var _store

func _init(store):
	_store = store

func get_all():
	return _store.get_table("characters")

func get_by_id(id: String):
	for char_data in get_all():
		if char_data.get("id") == id: return char_data
	return null

func get_player():
	for char_data in get_all():
		if char_data.get("is_player", false): return char_data
	return null

func get_by_name(name: String):
	for char_data in get_all():
		if char_data.get("name") == name: return char_data
	return null

func create(data: Dictionary):
	# Basic validation
	if "gender" in data:
		var g = data["gender"]
		if g != "Male" and g != "Female": data["gender"] = "Male"
	else:
		data["gender"] = "Male"
		
	get_all().append(data)
	_store.save_data()

func update(char_data: Dictionary):
	# In-memory update is automatic if ref is held, but good to signal save
	_store.save_data()

