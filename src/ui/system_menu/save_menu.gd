extends Control

signal back_requested

@onready var panel = $Panel
@onready var filename_input = $Panel/VBoxContainer/FilenameInput
@onready var save_button = $Panel/VBoxContainer/SaveButton
@onready var status_label = $Panel/VBoxContainer/StatusLabel

var dragging = false

func _ready():
	visible = false

func open():
	visible = true
	_center_panel()
	
	# Default to current save name
	var current_name = DatabaseManager.saves.get_current_save_name()
	filename_input.text = current_name
	status_label.text = ""

func _center_panel():
	var viewport_size = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2

func _on_save_pressed():
	var save_name = filename_input.text.strip_edges()
	
	if save_name == "":
		status_label.text = "Please enter a save name"
		return
	
	# Sanitize filename
	save_name = save_name.replace("/", "_").replace("\\", "_").replace(":", "_")
	
	var success = DatabaseManager.save_game(save_name)
	
	if success:
		status_label.text = "Saved successfully!"
		# Brief delay then close
		await get_tree().create_timer(0.5).timeout
		visible = false
		emit_signal("back_requested")
	else:
		status_label.text = "Failed to save"

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

