extends Control

signal option_selected(option)

func _on_talk_pressed():
	emit_signal("option_selected", "talk")

func _on_trade_pressed():
	emit_signal("option_selected", "trade")

func _on_inspect_pressed():
	emit_signal("option_selected", "inspect")

func _on_close_pressed():
	visible = false
