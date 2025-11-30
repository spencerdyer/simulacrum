extends Control

signal option_selected(option)

@onready var panel = $Panel

# Dragging state
var dragging = false
var drag_offset = Vector2.ZERO
const TITLE_BAR_HEIGHT = 30

func _on_talk_pressed():
	emit_signal("option_selected", "talk")

func _on_trade_pressed():
	emit_signal("option_selected", "trade")

func _on_inspect_pressed():
	emit_signal("option_selected", "inspect")

func _on_close_pressed():
	visible = false

# TitleBar dragging
func _on_titlebar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
				
	elif event is InputEventMouseMotion and dragging:
		panel.position += event.relative
