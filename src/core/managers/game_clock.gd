extends Node
class_name GameClock

# GameClock - Manages in-game time with configurable day/night cycle
# 1 game hour = 10 real minutes by default (time_scale = 6)

signal time_changed(hour: int, minute: int)
signal hour_changed(hour: int)
signal period_changed(period: String)  # "dawn", "day", "dusk", "night"

# Time configuration
@export var game_hour: float = 8.0  # Start at 8:00 AM
@export var time_scale: float = 6.0  # 6 = 1 game hour per 10 real minutes

# Time periods (for day/night cycle)
const PERIOD_DAWN_START = 5    # 5:00 AM
const PERIOD_DAY_START = 7     # 7:00 AM
const PERIOD_DUSK_START = 18   # 6:00 PM
const PERIOD_NIGHT_START = 20  # 8:00 PM

var _last_hour: int = -1
var _last_minute: int = -1
var _last_period: String = ""
var _paused: bool = false

var _debug_timer: float = 0.0

func _ready():
	_last_hour = int(game_hour)
	_last_minute = get_minute()
	_last_period = get_current_period()
	print("GameClock: Initialized at ", get_formatted_time())
	print("GameClock: time_scale = ", time_scale, ", is_inside_tree = ", is_inside_tree())

func _process(delta: float):
	if _paused:
		return
	
	# Debug timer - print every 5 real seconds
	_debug_timer += delta
	if _debug_timer >= 5.0:
		_debug_timer = 0.0
		print("GameClock: ", get_formatted_time(), " (game_hour=", snappedf(game_hour, 0.001), ")")
	
	# Advance time
	game_hour += delta * time_scale / 3600.0
	
	# Wrap around at midnight
	if game_hour >= 24.0:
		game_hour -= 24.0
	
	# Check for time changes and emit signals
	var current_hour = get_hour()
	var current_minute = get_minute()
	var current_period = get_current_period()
	
	# Emit minute change (throttled to avoid spam)
	if current_minute != _last_minute:
		_last_minute = current_minute
		time_changed.emit(current_hour, current_minute)
	
	# Emit hour change
	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_changed.emit(current_hour)
	
	# Emit period change (dawn/day/dusk/night)
	if current_period != _last_period:
		_last_period = current_period
		period_changed.emit(current_period)

# Get current hour (0-23)
func get_hour() -> int:
	return int(game_hour) % 24

# Get current minute (0-59)
func get_minute() -> int:
	return int((game_hour - int(game_hour)) * 60) % 60

# Get time as dictionary
func get_time() -> Dictionary:
	return {
		"hour": get_hour(),
		"minute": get_minute(),
		"period": get_current_period(),
		"is_day": is_daytime(),
		"raw_hour": game_hour
	}

# Get formatted time string (e.g., "8:05am" or "4:54pm")
func get_formatted_time() -> String:
	var hour = get_hour()
	var minute = get_minute()
	var period = "am"
	var display_hour = hour
	
	if hour == 0:
		display_hour = 12
		period = "am"
	elif hour < 12:
		display_hour = hour
		period = "am"
	elif hour == 12:
		display_hour = 12
		period = "pm"
	else:
		display_hour = hour - 12
		period = "pm"
	
	return "%d:%02d%s" % [display_hour, minute, period]

# Get current time period
func get_current_period() -> String:
	var hour = get_hour()
	
	if hour >= PERIOD_NIGHT_START or hour < PERIOD_DAWN_START:
		return "night"
	elif hour >= PERIOD_DUSK_START:
		return "dusk"
	elif hour >= PERIOD_DAY_START:
		return "day"
	else:
		return "dawn"

# Check if it's daytime (for lighting purposes)
func is_daytime() -> bool:
	var period = get_current_period()
	return period == "day" or period == "dawn"

# Get a descriptive time of day string for LLM context
func get_time_description() -> String:
	var hour = get_hour()
	var period = get_current_period()
	
	match period:
		"dawn":
			return "early morning, just after sunrise"
		"day":
			if hour < 12:
				return "morning"
			elif hour == 12:
				return "midday"
			elif hour < 15:
				return "early afternoon"
			else:
				return "late afternoon"
		"dusk":
			return "evening, as the sun sets"
		"night":
			if hour < 23 and hour >= 20:
				return "night"
			elif hour >= 23 or hour < 2:
				return "late night"
			else:
				return "the small hours before dawn"
	
	return "daytime"

# Set the time directly
func set_time(hour: int, minute: int = 0):
	game_hour = float(hour) + float(minute) / 60.0
	_last_hour = hour
	_last_minute = minute
	_last_period = get_current_period()
	time_changed.emit(hour, minute)
	hour_changed.emit(hour)
	period_changed.emit(_last_period)

# Pause/resume time
func pause():
	_paused = true

func resume():
	_paused = false

func is_paused() -> bool:
	return _paused

# Advance time by a specified number of game hours
func advance_time(hours: float):
	game_hour += hours
	while game_hour >= 24.0:
		game_hour -= 24.0
	while game_hour < 0:
		game_hour += 24.0

