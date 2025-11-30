extends Node

# Window Manager - tracks open windows, prevents duplicates, manages navigation stack

signal window_opened(window_id)
signal window_closed(window_id)

# Track open windows by unique ID (e.g., "character_npc_merchant_1", "trade_npc_merchant_1")
var open_windows = {}

# Navigation stack for back button support
# Each entry: { "window_id": String, "opener_id": String or null }
var navigation_stack = []

func get_window_id(window_type: String, context: String = "") -> String:
	if context != "":
		return window_type + "_" + context
	return window_type

func is_window_open(window_type: String, context: String = "") -> bool:
	var id = get_window_id(window_type, context)
	return open_windows.has(id)

func register_window(window_type: String, context: String, window_node, opener_id: String = ""):
	var id = get_window_id(window_type, context)
	
	if open_windows.has(id):
		print("WindowManager: Window already open: ", id)
		return false
	
	open_windows[id] = {
		"node": window_node,
		"type": window_type,
		"context": context
	}
	
	navigation_stack.append({
		"window_id": id,
		"opener_id": opener_id
	})
	
	emit_signal("window_opened", id)
	print("WindowManager: Opened window: ", id)
	return true

func close_window(window_type: String, context: String = ""):
	var id = get_window_id(window_type, context)
	
	if not open_windows.has(id):
		return null
	
	var window_data = open_windows[id]
	open_windows.erase(id)
	
	# Find and remove from navigation stack, get opener
	var opener_id = null
	for i in range(navigation_stack.size() - 1, -1, -1):
		if navigation_stack[i]["window_id"] == id:
			opener_id = navigation_stack[i]["opener_id"]
			navigation_stack.remove_at(i)
			break
	
	emit_signal("window_closed", id)
	print("WindowManager: Closed window: ", id)
	
	return opener_id

func get_opener_for_window(window_type: String, context: String = "") -> String:
	var id = get_window_id(window_type, context)
	
	for entry in navigation_stack:
		if entry["window_id"] == id:
			return entry["opener_id"]
	
	return ""

func close_all():
	open_windows.clear()
	navigation_stack.clear()

