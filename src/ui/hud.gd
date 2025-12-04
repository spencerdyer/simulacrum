extends Control

signal toggle_character_screen
signal toggle_inventory_screen

@onready var time_label: Label = $TimeDisplay/TimeLabel

var _game_clock  # GameClock reference
var _last_displayed_time: String = ""

func _ready():
	print("HUD: _ready called")
	# Ensure processing is enabled
	set_process(true)
	print("HUD: set_process(true), process_mode=", process_mode)
	# Defer clock setup to ensure DatabaseManager is ready
	call_deferred("_setup_clock")
	
	# Create a timer as backup for updating time
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_update)
	add_child(timer)
	print("HUD: Timer created for time updates")

func _on_timer_update():
	print("HUD Timer: tick")
	_update_time_display()

func _setup_clock():
	if DatabaseManager.game_clock:
		_game_clock = DatabaseManager.game_clock
		_update_time_display()
		print("HUD: Connected to game clock")
	else:
		print("HUD: Game clock not available yet, will retry in _process")

var _hud_debug_timer: float = 0.0

func _process(delta: float):
	# Debug - check every 5 seconds
	_hud_debug_timer += delta
	if _hud_debug_timer >= 5.0:
		_hud_debug_timer = 0.0
		print("HUD: _game_clock=", _game_clock, ", time_label=", time_label)
		if _game_clock:
			print("HUD: Clock says ", _game_clock.get_formatted_time())
	
	# Update time display every frame (only changes text when time changes)
	_update_time_display()

func _update_time_display():
	if not time_label:
		return
	
	if not _game_clock:
		# Try to get clock again if we didn't have it before
		if DatabaseManager.game_clock:
			_game_clock = DatabaseManager.game_clock
			print("HUD: Got game clock reference on retry")
		else:
			return
	
	var current_time = _game_clock.get_formatted_time()
	if current_time != _last_displayed_time:
		print("HUD: Updating display from '", _last_displayed_time, "' to '", current_time, "'")
		_last_displayed_time = current_time
		time_label.text = current_time

func _on_char_button_pressed():
	emit_signal("toggle_character_screen")

func _on_inv_button_pressed():
	emit_signal("toggle_inventory_screen")
