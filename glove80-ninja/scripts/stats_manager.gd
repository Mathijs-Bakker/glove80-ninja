class_name StatsManager
extends RefCounted

signal stats_updated(wpm: float, accuracy: float, mistakes: int)

var start_time := 0
var current_wpm := 0.0
var elapsed_time := 0.0

func start_timing() -> void:
	start_time = Time.get_ticks_msec()
	current_wpm = 0.0
	elapsed_time = 0.0

func stop_timing() -> void:
	if start_time > 0:
		elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0
		start_time = 0

func calculate_wpm(char_count: int, time_seconds: float) -> float:
	if time_seconds <= 0:
		return 0.0
	
	var words := char_count / 5.0
	var minutes := time_seconds / 60.0
	var wpm := words / minutes
	
	return min(wpm, 200.0)

func update_wpm(char_count: int) -> void:
	if start_time > 0:
		var current_time := (Time.get_ticks_msec() - start_time) / 1000.0
		current_wpm = calculate_wpm(char_count, current_time)
		stats_updated.emit(current_wpm, 0.0, 0)

func get_final_stats(char_count: int, accuracy: float, mistakes_count: int) -> Dictionary:
	stop_timing()
	return {
		"wpm": calculate_wpm(char_count, elapsed_time),
		"accuracy": accuracy,
		"time": elapsed_time,
		"mistakes": mistakes_count
	}
