extends Control

signal menu_closed

@onready var panel = $Panel
@onready var save_button = $Panel/VBoxContainer/SaveButton
@onready var load_button = $Panel/VBoxContainer/LoadButton
@onready var settings_button = $Panel/VBoxContainer/SettingsButton
@onready var exit_button = $Panel/VBoxContainer/ExitButton

# Dragging
var dragging = false

func _ready():
	visible = false

func open():
	visible = true
	_center_panel()

func _center_panel():
	var viewport_size = get_viewport_rect().size
	panel.position = (viewport_size - panel.size) / 2

func _on_save_pressed():
	emit_signal("menu_closed")
	visible = false
	get_parent().get_node("SaveMenu").open()

func _on_load_pressed():
	emit_signal("menu_closed")
	visible = false
	get_parent().get_node("LoadMenu").open()

func _on_settings_pressed():
	emit_signal("menu_closed")
	visible = false
	get_parent().get_node("SettingsMenu").open()

func _on_exit_pressed():
	# Auto-save before exit
	DatabaseManager.auto_save()
	get_tree().quit()

func _on_close_pressed():
	visible = false
	emit_signal("menu_closed")

func _on_titlebar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		panel.position += event.relative

