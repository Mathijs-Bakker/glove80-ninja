class_name TypingExercise
extends RefCounted

## Represents a typing exercise with text content, progress tracking, and results calculation
## Provides a clean interface for managing individual typing exercises

signal progress_updated(progress_data: Dictionary)
signal exercise_completed(results: Dictionary)

# Exercise configuration
var exercise_id: String = ""
var exercise_type: String = "random"  # random, lesson, custom
var difficulty_level: String = "beginner"
var target_wpm: float = 0.0
var target_accuracy: float = 90.0

# Text content
var original_text: String = ""
var processed_text: String = ""  # Text with any preprocessing applied
var text_metadata: Dictionary = {}

# Progress tracking
var user_input: String = ""
var current_position: int = 0
var start_time: int = 0
var end_time: int = 0
var is_started: bool = false
var is_completed: bool = false

# Statistics
var correct_characters: int = 0
var incorrect_characters: int = 0
var total_characters_typed: int = 0
var corrections_made: int = 0
var mistake_positions: Array = []
var keystroke_timings: Array = []

# Text providers
var text_provider: TextProvider


## Initialize exercise with optional parameters
func initialize(config: Dictionary = {}) -> void:
	exercise_id = config.get("id", _generate_exercise_id())
	exercise_type = config.get("type", "random")
	difficulty_level = config.get("difficulty", "beginner")
	target_wpm = config.get("target_wpm", 0.0)
	target_accuracy = config.get("target_accuracy", 90.0)

	text_provider = TextProvider.new()

	# Load text based on type
	match exercise_type:
		"random":
			load_random_text()
		"lesson":
			load_lesson_text(config.get("lesson_id", ""))
		"custom":
			load_custom_text(config.get("custom_text", ""))


## Load a random text sample
func load_random_text() -> void:
	original_text = text_provider.get_random_sample()
	_process_text()


## Load text from a specific lesson
func load_lesson_text(lesson_id: String) -> void:
	original_text = text_provider.get_lesson_text(lesson_id)
	if original_text.is_empty():
		load_random_text()  # Fallback to random
	else:
		_process_text()


## Load custom text provided by user
func load_custom_text(custom_text: String) -> void:
	if custom_text.is_empty():
		load_random_text()
		return

	original_text = custom_text
	_process_text()


## Get the text content for display
func get_text() -> String:
	return processed_text


## Get original unprocessed text
func get_original_text() -> String:
	return original_text


## Start the exercise (call when user starts typing)
func start_exercise() -> void:
	if is_started:
		return

	is_started = true
	start_time = Time.get_ticks_msec()
	print("Exercise started: ", exercise_id)


## Process a character input from the user
func process_character(character: String, is_correct: bool, position: int) -> void:
	if not is_started:
		start_exercise()

	if is_completed:
		return

	# Record keystroke timing
	var current_time = Time.get_ticks_msec()
	keystroke_timings.append({
		"character": character,
		"time": current_time,
		"position": position,
		"is_correct": is_correct
	})

	# Handle backspace
	if character == "":  # Backspace indicator
		if current_position > 0:
			corrections_made += 1
			current_position -= 1
			user_input = user_input.substr(0, current_position)
		_emit_progress_update()
		return

	# Process regular character
	total_characters_typed += 1
	user_input += character
	current_position = position + 1

	if is_correct:
		correct_characters += 1
	else:
		incorrect_characters += 1
		mistake_positions.append(position)

	# Check if exercise is complete
	if current_position >= processed_text.length():
		_complete_exercise()
	else:
		_emit_progress_update()


## Reset exercise to initial state
func reset() -> void:
	user_input = ""
	current_position = 0
	start_time = 0
	end_time = 0
	is_started = false
	is_completed = false
	correct_characters = 0
	incorrect_characters = 0
	total_characters_typed = 0
	corrections_made = 0
	mistake_positions.clear()
	keystroke_timings.clear()


## Get current progress data
func get_progress_data() -> Dictionary:
	return {
		"user_input": user_input,
		"current_index": current_position,
		"total_length": processed_text.length(),
		"progress_percent": (float(current_position) / float(processed_text.length())) * 100.0 if processed_text.length() > 0 else 0.0,
		"mistakes": incorrect_characters,
		"corrections": corrections_made,
		"is_complete": is_completed
	}


## Get final exercise results
func get_results() -> Dictionary:
	var typing_time = _get_typing_duration()
	var wpm = _calculate_wpm(typing_time)
	var accuracy = _calculate_accuracy()

	return {
		"exercise_id": exercise_id,
		"exercise_type": exercise_type,
		"difficulty_level": difficulty_level,
		"original_text": original_text,
		"user_input": user_input,
		"wpm": wpm,
		"accuracy": accuracy,
		"duration": typing_time,
		"characters_typed": total_characters_typed,
		"correct_characters": correct_characters,
		"incorrect_characters": incorrect_characters,
		"mistakes": mistake_positions.size(),
		"corrections": corrections_made,
		"target_wpm": target_wpm,
		"target_accuracy": target_accuracy,
		"wpm_achieved": wpm >= target_wpm if target_wpm > 0 else true,
		"accuracy_achieved": accuracy >= target_accuracy,
		"completion_percentage": (float(current_position) / float(processed_text.length())) * 100.0 if processed_text.length() > 0 else 0.0,
		"keystroke_data": _get_keystroke_analysis(),
		"performance_metrics": _get_performance_metrics()
	}


## Check if exercise meets completion criteria
func meets_completion_criteria() -> bool:
	if not is_completed:
		return false

	var results = get_results()
	var wpm_ok = target_wpm <= 0 or results.wpm >= target_wpm
	var accuracy_ok = results.accuracy >= target_accuracy

	return wpm_ok and accuracy_ok


## Get exercise metadata
func get_metadata() -> Dictionary:
	return {
		"id": exercise_id,
		"type": exercise_type,
		"difficulty": difficulty_level,
		"text_length": processed_text.length(),
		"word_count": _count_words(processed_text),
		"target_wpm": target_wpm,
		"target_accuracy": target_accuracy,
		"estimated_duration": _estimate_duration(),
		"text_metadata": text_metadata
	}


# Private methods

func _generate_exercise_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "exercise_%d_%d" % [timestamp, random_suffix]


func _process_text() -> void:
	if original_text.is_empty():
		return

	processed_text = original_text

	# Apply text processing based on difficulty level
	match difficulty_level:
		"beginner":
			processed_text = _simplify_text(processed_text)
		"intermediate":
			processed_text = _normalize_text(processed_text)
		"advanced":
			# Keep text as-is for advanced users
			pass

	# Store metadata about the text
	text_metadata = {
		"word_count": _count_words(processed_text),
		"character_count": processed_text.length(),
		"unique_characters": _count_unique_characters(processed_text),
		"complexity_score": _calculate_text_complexity(processed_text)
	}


func _simplify_text(text: String) -> String:
	# For beginners: lowercase, simple punctuation
	var simplified = text.to_lower()
	# Remove complex punctuation, keep basic ones
	var regex = RegEx.new()
	regex.compile("[^a-z0-9\\s.,!?'-]")
	simplified = regex.sub(simplified, "", true)
	return simplified.strip_edges()


func _normalize_text(text: String) -> String:
	# For intermediate: normalize spacing and line breaks
	var normalized = text.strip_edges()
	# Replace multiple spaces with single space
	var regex = RegEx.new()
	regex.compile("\\s+")
	normalized = regex.sub(normalized, " ", true)
	return normalized


func _complete_exercise() -> void:
	if is_completed:
		return

	is_completed = true
	end_time = Time.get_ticks_msec()

	var results = get_results()
	exercise_completed.emit(results)

	print("Exercise completed: ", exercise_id, " WPM: %.1f, Accuracy: %.1f%%" % [results.wpm, results.accuracy])


func _emit_progress_update() -> void:
	var progress_data = get_progress_data()
	progress_updated.emit(progress_data)


func _get_typing_duration() -> float:
	if not is_started:
		return 0.0

	var end_time_to_use = end_time if is_completed else Time.get_ticks_msec()
	return (end_time_to_use - start_time) / 1000.0


func _calculate_wpm(typing_time: float) -> float:
	if typing_time <= 0:
		return 0.0

	var words_typed = float(correct_characters) / 5.0  # Standard: 5 characters = 1 word
	return (words_typed / typing_time) * 60.0


func _calculate_accuracy() -> float:
	if total_characters_typed <= 0:
		return 100.0

	return (float(correct_characters) / float(total_characters_typed)) * 100.0


func _count_words(text: String) -> int:
	if text.is_empty():
		return 0

	var words = text.split(" ", false)
	return words.size()


func _count_unique_characters(text: String) -> int:
	var unique_chars = {}
	for i in range(text.length()):
		var char = text[i]
		unique_chars[char] = true
	return unique_chars.size()


func _calculate_text_complexity(text: String) -> float:
	# Simple complexity calculation based on character variety and punctuation
	var unique_chars = _count_unique_characters(text)
	var total_chars = text.length()
	var punctuation_count = 0

	for i in range(text.length()):
		var char = text[i]
		if char in ".,!?;:\"'()[]{}":
			punctuation_count += 1

	var complexity = 0.0
	if total_chars > 0:
		complexity = (float(unique_chars) / float(total_chars)) * 100.0
		complexity += (float(punctuation_count) / float(total_chars)) * 50.0

	return min(complexity, 100.0)  # Cap at 100


func _estimate_duration() -> float:
	# Estimate duration based on text length and target WPM
	if target_wpm <= 0:
		target_wpm = 30.0  # Default assumption

	var words = float(processed_text.length()) / 5.0
	return (words / target_wpm) * 60.0


func _get_keystroke_analysis() -> Dictionary:
	var analysis = {
		"total_keystrokes": keystroke_timings.size(),
		"keystroke_intervals": [],
		"problem_characters": {},
		"speed_variations": []
	}

	# Calculate intervals between keystrokes
	for i in range(1, keystroke_timings.size()):
		var interval = keystroke_timings[i].time - keystroke_timings[i-1].time
		analysis.keystroke_intervals.append(interval)

	# Identify problem characters (characters that are often mistyped)
	for timing in keystroke_timings:
		if not timing.is_correct:
			var char = timing.character
			if not analysis.problem_characters.has(char):
				analysis.problem_characters[char] = 0
			analysis.problem_characters[char] += 1

	return analysis


func _get_performance_metrics() -> Dictionary:
	var typing_time = _get_typing_duration()

	return {
		"consistency_score": _calculate_consistency_score(),
		"speed_stability": _calculate_speed_stability(),
		"error_distribution": _analyze_error_distribution(),
		"improvement_areas": _identify_improvement_areas(),
		"typing_rhythm": _analyze_typing_rhythm()
	}


func _calculate_consistency_score() -> float:
	if keystroke_timings.size() < 10:
		return 100.0  # Not enough data

	# Calculate variance in keystroke intervals
	var intervals = []
	for i in range(1, keystroke_timings.size()):
		var interval = keystroke_timings[i].time - keystroke_timings[i-1].time
		intervals.append(interval)

	if intervals.is_empty():
		return 100.0

	var mean_interval = 0.0
	for interval in intervals:
		mean_interval += interval
	mean_interval /= intervals.size()

	var variance = 0.0
	for interval in intervals:
		variance += (interval - mean_interval) * (interval - mean_interval)
	variance /= intervals.size()

	# Convert variance to consistency score (lower variance = higher consistency)
	var consistency = max(0, 100 - (variance / 1000))  # Normalize
	return min(consistency, 100.0)


func _calculate_speed_stability() -> float:
	# Measure how stable the WPM is throughout the exercise
	# This is a simplified calculation
	return 85.0  # Placeholder


func _analyze_error_distribution() -> Dictionary:
	return {
		"total_errors": mistake_positions.size(),
		"error_rate": float(mistake_positions.size()) / float(processed_text.length()) * 100.0 if processed_text.length() > 0 else 0.0,
		"error_clustering": "distributed"  # Could be "clustered", "distributed", "front-loaded", "back-loaded"
	}


func _identify_improvement_areas() -> Array:
	var areas = []

	var accuracy = _calculate_accuracy()
	if accuracy < 95:
		areas.append("accuracy")

	var wpm = _calculate_wpm(_get_typing_duration())
	if wpm < 40:
		areas.append("speed")

	if _calculate_consistency_score() < 70:
		areas.append("consistency")

	return areas


func _analyze_typing_rhythm() -> Dictionary:
	return {
		"rhythm_score": 75.0,  # Placeholder
		"rush_periods": [],
		"slow_periods": [],
		"optimal_pace_percentage": 80.0
	}
