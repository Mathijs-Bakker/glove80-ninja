class_name SessionManager
extends RefCounted

## Manages typing sessions with statistics tracking and user service integration
## Handles session lifecycle, performance metrics, and achievement checking

signal session_started()
signal session_completed(results: Dictionary)
signal stats_updated(stats: Dictionary)
signal milestone_reached(milestone: String, value: float)

# Services
var user_service: UserService

# Session state
var is_session_active: bool = false
var session_start_time: int = 0
var session_end_time: int = 0
var session_id: String = ""

# Real-time statistics
var current_stats: SessionStats
var performance_tracker: PerformanceTracker

# Configuration
var update_interval: float = 0.5  # Update stats every 500ms
var stats_timer: Timer


## Initialize session manager with user service and parent node for timer
func initialize(p_user_service: UserService, p_parent_node: Node) -> void:
	user_service = p_user_service
	current_stats = SessionStats.new()
	performance_tracker = PerformanceTracker.new()
	_setup_stats_timer(p_parent_node)


## Start a new typing session
func start_session() -> void:
	if is_session_active:
		complete_session({})  # End previous session

	session_id = _generate_session_id()
	session_start_time = Time.get_ticks_msec()
	is_session_active = true

	current_stats.reset()
	performance_tracker.reset()

	if user_service:
		user_service.start_session()

	if stats_timer:
		stats_timer.start()

	session_started.emit()
	print("Session started: ", session_id)


## Complete current session and return results
func complete_session(exercise_results: Dictionary) -> Dictionary:
	if not is_session_active:
		return {}

	session_end_time = Time.get_ticks_msec()
	is_session_active = false

	if stats_timer:
		stats_timer.stop()

	# Calculate final session results
	var session_results = _calculate_final_results(exercise_results)

	# Update user service
	if user_service:
		user_service.end_session(session_results)

	session_completed.emit(session_results)
	print("Session completed: ", session_id, " Results: ", session_results)

	return session_results


## Restart current session (reset stats but keep session active)
func restart_session() -> void:
	if not is_session_active:
		start_session()
		return

	current_stats.reset()
	performance_tracker.reset()
	session_start_time = Time.get_ticks_msec()

	print("Session restarted: ", session_id)


## Update session with real-time input data
func update_with_input(character: String, is_correct: bool, position: int, total_text_length: int) -> void:
	if not is_session_active:
		return

	current_stats.record_keystroke(character, is_correct, position)
	performance_tracker.update_progress(position, total_text_length)

	# Check for milestones
	_check_milestones()


## Get current session statistics
func get_current_stats() -> Dictionary:
	if not is_session_active:
		return {}

	var elapsed_time = _get_elapsed_time()
	return current_stats.get_stats(elapsed_time)


## Get session duration in seconds
func get_session_duration() -> float:
	if not is_session_active:
		return (session_end_time - session_start_time) / 1000.0

	return _get_elapsed_time()


## Check if session is active
func is_active() -> bool:
	return is_session_active


# Private methods

func _setup_stats_timer(p_parent_node: Node) -> void:
	stats_timer = Timer.new()
	stats_timer.wait_time = update_interval
	stats_timer.timeout.connect(_on_stats_timer_timeout)
	stats_timer.autostart = false
	p_parent_node.add_child(stats_timer)


func _generate_session_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "session_%d_%d" % [timestamp, random_suffix]


func _get_elapsed_time() -> float:
	if not is_session_active:
		return 0.0
	return (Time.get_ticks_msec() - session_start_time) / 1000.0


func _calculate_final_results(exercise_results: Dictionary) -> Dictionary:
	var elapsed_time = _get_elapsed_time()
	var stats = current_stats.get_stats(elapsed_time)

	# Merge exercise results with session stats
	var final_results = stats.duplicate()
	for key in exercise_results:
		final_results[key] = exercise_results[key]

	# Add session-specific data
	final_results["session_id"] = session_id
	final_results["session_duration"] = elapsed_time
	final_results["timestamp"] = Time.get_unix_time_from_system()
	final_results["performance_curve"] = performance_tracker.get_performance_curve()

	return final_results


func _check_milestones() -> void:
	var stats = current_stats.get_stats(_get_elapsed_time())
	var wpm = stats.get("wpm", 0.0)
	var accuracy = stats.get("accuracy", 0.0)

	# Check WPM milestones
	for milestone_wpm in [10, 20, 30, 40, 50, 60, 70, 80]:
		if wpm >= milestone_wpm and not performance_tracker.has_reached_milestone("wpm_%d" % milestone_wpm):
			performance_tracker.mark_milestone("wpm_%d" % milestone_wpm)
			milestone_reached.emit("wpm", milestone_wpm)

	# Check accuracy milestones
	for milestone_acc in [90, 95, 98, 99]:
		if accuracy >= milestone_acc and not performance_tracker.has_reached_milestone("accuracy_%d" % milestone_acc):
			performance_tracker.mark_milestone("accuracy_%d" % milestone_acc)
			milestone_reached.emit("accuracy", milestone_acc)


func _on_stats_timer_timeout() -> void:
	if is_session_active:
		var stats = get_current_stats()
		stats_updated.emit(stats)


# Inner classes for better organization

class SessionStats:
	var total_keystrokes: int = 0
	var correct_keystrokes: int = 0
	var incorrect_keystrokes: int = 0
	var characters_typed: int = 0
	var words_typed: float = 0.0
	var backspaces: int = 0
	var keystroke_times: Array = []
	var error_positions: Array = []

	func reset() -> void:
		total_keystrokes = 0
		correct_keystrokes = 0
		incorrect_keystrokes = 0
		characters_typed = 0
		words_typed = 0.0
		backspaces = 0
		keystroke_times.clear()
		error_positions.clear()

	func record_keystroke(character: String, is_correct: bool, position: int) -> void:
		var current_time = Time.get_ticks_msec()
		keystroke_times.append(current_time)

		if character == "":  # Backspace
			backspaces += 1
			return

		total_keystrokes += 1
		characters_typed += 1
		words_typed = characters_typed / 5.0

		if is_correct:
			correct_keystrokes += 1
		else:
			incorrect_keystrokes += 1
			error_positions.append(position)

	func get_stats(elapsed_time: float) -> Dictionary:
		var wpm = 0.0
		var accuracy = 100.0

		if elapsed_time > 0:
			wpm = (words_typed / elapsed_time) * 60.0

		if total_keystrokes > 0:
			accuracy = (float(correct_keystrokes) / float(total_keystrokes)) * 100.0

		return {
			"wpm": wpm,
			"accuracy": accuracy,
			"characters_typed": characters_typed,
			"words_typed": words_typed,
			"mistakes": incorrect_keystrokes,
			"corrections": backspaces,
			"total_keystrokes": total_keystrokes,
			"elapsed_time": elapsed_time,
			"error_positions": error_positions.duplicate()
		}


class PerformanceTracker:
	var progress_points: Array = []
	var wpm_history: Array = []
	var accuracy_history: Array = []
	var milestones_reached: Dictionary = {}
	var sample_interval: float = 2.0  # Sample every 2 seconds
	var last_sample_time: float = 0.0

	func reset() -> void:
		progress_points.clear()
		wpm_history.clear()
		accuracy_history.clear()
		milestones_reached.clear()
		last_sample_time = 0.0

	func update_progress(position: int, total_length: int) -> void:
		var current_time = Time.get_ticks_msec() / 1000.0

		if current_time - last_sample_time >= sample_interval:
			var progress_percent = (float(position) / float(total_length)) * 100.0
			progress_points.append({
				"time": current_time,
				"progress": progress_percent,
				"position": position
			})
			last_sample_time = current_time

	func record_performance_sample(wpm: float, accuracy: float) -> void:
		wpm_history.append(wpm)
		accuracy_history.append(accuracy)

	func mark_milestone(milestone_id: String) -> void:
		milestones_reached[milestone_id] = Time.get_ticks_msec() / 1000.0

	func has_reached_milestone(milestone_id: String) -> bool:
		return milestones_reached.has(milestone_id)

	func get_performance_curve() -> Dictionary:
		return {
			"progress_points": progress_points.duplicate(),
			"wpm_history": wpm_history.duplicate(),
			"accuracy_history": accuracy_history.duplicate(),
			"milestones": milestones_reached.duplicate()
		}


## Cleanup resources (call when session manager is no longer needed)
func cleanup() -> void:
	if stats_timer and is_instance_valid(stats_timer):
		if stats_timer.is_inside_tree():
			stats_timer.get_parent().remove_child(stats_timer)
		stats_timer.queue_free()
		stats_timer = null
