extends CanvasModulate
class_name DayNightCycle

# Day/Night Cycle - Visual lighting changes based on game time
# Attach this to a CanvasModulate node in your scene

# Configurable colors for each time period
@export var dawn_color: Color = Color(0.9, 0.75, 0.65, 1.0)    # Warm orange-pink
@export var day_color: Color = Color(1.0, 1.0, 1.0, 1.0)       # Full brightness
@export var dusk_color: Color = Color(0.95, 0.7, 0.5, 1.0)     # Orange sunset
@export var night_color: Color = Color(0.3, 0.35, 0.5, 1.0)    # Dark blue

# How smooth the transitions are
@export var transition_speed: float = 2.0

var _target_color: Color = Color.WHITE
var _game_clock  # GameClock reference

func _ready():
	# Get the game clock
	if DatabaseManager.game_clock:
		_game_clock = DatabaseManager.game_clock
		_game_clock.time_changed.connect(_on_time_changed)
		# Initialize color
		_update_target_color()
		color = _target_color

func _process(delta: float):
	# Smoothly lerp to target color
	color = color.lerp(_target_color, delta * transition_speed)

func _on_time_changed(_hour: int, _minute: int):
	_update_target_color()

func _update_target_color():
	if not _game_clock:
		return
	
	var hour = _game_clock.game_hour
	
	# Define transition points
	const DAWN_START = 5.0
	const DAWN_END = 7.0
	const DUSK_START = 18.0
	const DUSK_END = 20.0
	
	# Night (20:00 - 05:00)
	if hour >= DUSK_END or hour < DAWN_START:
		_target_color = night_color
	
	# Dawn transition (05:00 - 07:00)
	elif hour >= DAWN_START and hour < DAWN_END:
		var t = (hour - DAWN_START) / (DAWN_END - DAWN_START)
		if t < 0.5:
			# Night to dawn
			_target_color = night_color.lerp(dawn_color, t * 2)
		else:
			# Dawn to day
			_target_color = dawn_color.lerp(day_color, (t - 0.5) * 2)
	
	# Full daylight (07:00 - 18:00)
	elif hour >= DAWN_END and hour < DUSK_START:
		_target_color = day_color
	
	# Dusk transition (18:00 - 20:00)
	elif hour >= DUSK_START and hour < DUSK_END:
		var t = (hour - DUSK_START) / (DUSK_END - DUSK_START)
		if t < 0.5:
			# Day to dusk
			_target_color = day_color.lerp(dusk_color, t * 2)
		else:
			# Dusk to night
			_target_color = dusk_color.lerp(night_color, (t - 0.5) * 2)

# Allow manual time setting for testing
func set_time_of_day(hour: float):
	if _game_clock:
		_game_clock.game_hour = hour
		_update_target_color()

