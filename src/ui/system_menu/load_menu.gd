extends Control

signal back_requested
signal game_loaded

@onready var panel = $Panel
@onready var save_list = $Panel/VBoxContainer/ScrollContainer/SaveList
@onready var status_label = $Panel/VBoxContainer/StatusLabel

var dragging = false

func _ready():
	visible = false

func open():
	visible = true
	_center_panel()
	_populate_save_list()
	status_label.text = ""

func _center_panel():
	var viewport_size = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2

func _populate_save_list():
	# Clear existing
	for child in save_list.get_children():
		child.queue_free()
	
	var saves = DatabaseManager.saves.get_save_list()
	
	if saves.is_empty():
		var label = Label.new()
		label.text = "No save files found"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_list.add_child(label)
		return
	
	for save_info in saves:
		var container = HBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Save info
		var info_label = Label.new()
		var timestamp_str = DatabaseManager.saves.format_timestamp(save_info.get("timestamp", 0))
		var playtime_str = DatabaseManager.saves.format_playtime(save_info.get("playtime", 0))
		var last_loaded_marker = " ★" if save_info.get("last_loaded", false) else ""
		info_label.text = "%s%s\n%s | Playtime: %s" % [
			save_info.get("name", "Unknown"),
			last_loaded_marker,
			timestamp_str,
			playtime_str
		]
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(info_label)
		
		# Load button
		var load_btn = Button.new()
		load_btn.text = "Load"
		load_btn.pressed.connect(_on_load_save.bind(save_info["filename"]))
		container.add_child(load_btn)
		
		# Delete button
		var delete_btn = Button.new()
		delete_btn.text = "X"
		delete_btn.pressed.connect(_on_delete_save.bind(save_info["filename"]))
		container.add_child(delete_btn)
		
		save_list.add_child(container)

func _on_load_save(filename: String):
	status_label.text = "Loading..."
	
	var success = DatabaseManager.load_game(filename)
	
	if success:
		status_label.text = "Loaded!"
		await get_tree().create_timer(0.3).timeout
		visible = false
		emit_signal("game_loaded")
	else:
		status_label.text = "Failed to load save"

func _on_delete_save(filename: String):
	DatabaseManager.saves.delete_save(filename)
	_populate_save_list()
	status_label.text = "Deleted: " + filename

func _on_back_pressed():
	visible = false
	emit_signal("back_requested")

func _on_close_pressed():
	visible = false

func _on_titlebar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		panel.position += event.relative

