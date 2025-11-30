extends RefCounted

# Playtime Tracker - tracks cumulative play time for the current session

var _session_start_time: float = 0.0
var _loaded_playtime: float = 0.0  # Playtime from loaded save

func _init():
	_session_start_time = Time.get_unix_time_from_system()

func start_session(previous_playtime: float = 0.0):
	_session_start_time = Time.get_unix_time_from_system()
	_loaded_playtime = previous_playtime

func get_total_playtime() -> float:
	var session_time = Time.get_unix_time_from_system() - _session_start_time
	return _loaded_playtime + session_time

func get_session_time() -> float:
	return Time.get_unix_time_from_system() - _session_start_time

