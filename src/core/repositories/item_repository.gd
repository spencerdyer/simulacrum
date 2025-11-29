extends RefCounted

var _store

func _init(store):
	_store = store

func get_all():
	return _store.get_table("items")

func get_by_id(id: String):
	for item in get_all():
		if item["id"] == id: return item
	return null

func add_definition(id, name, type, value, desc):
	var items = get_all()
	# Check if exists
	for item in items:
		if item["id"] == id: return
		
	items.append({
		"id": id, "name": name, "type": type, "value": value, "description": desc
	})
	
func clear_definitions():
	_store.get_table("items").clear()

