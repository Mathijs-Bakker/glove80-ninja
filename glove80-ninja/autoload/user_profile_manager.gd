extends Node

## Manages user progress and statistics


signal profile_loaded()
signal profile_saved()
signal stats_updated()

const PROFILE_PATH = "user://profiles/default_profile.json"

# Default profile structure
const DEFAULT_PROFILE = {
	"username": "Typist",
	"level": 1,
	"experience": 0,
	"total_words_typed": 0,
	"total_characters_typed": 0,
	"total_time_typed": 0,
	"average_wpm": 0,
	"best_wpm": 0,
	"average_accuracy": 0,
	"best_accuracy": 0,
	"total_mistakes": 0,
	"lessons_completed": 0,
	"exercises_completed": 0,
	"current_streak": 0,
	"longest_streak": 0,
	"last_session_date": "",
	"achievements": {},
	"lesson_progress": {},
	"keyboard_proficiency": {},
	"session_history": []
}

var current_profile: Dictionary = {}


func _ready() -> void:
	load_profile()


# Load user profile
func load_profile() -> void:
	current_profile = JSONManager.load_data(PROFILE_PATH, DEFAULT_PROFILE)
	profile_loaded.emit()
	print("User profile loaded")


# Save user profile
func save_profile() -> bool:
	# Update last session date
	current_profile["last_session_date"] = Time.get_date_string_from_system()
	
	var success = JSONManager.save_to_file(PROFILE_PATH, current_profile)
	if success:
		profile_saved.emit()
		print("User profile saved")
	else:
		push_error("Failed to save user profile")
	
	return success


# Update statistics after typing session
func update_session_stats(p_wpm: float, p_accuracy: float, p_characters_typed: int, p_mistakes: int, p_lesson_id: String = "") -> void:
	var words_typed = p_characters_typed / 5.0
	
	# Update basic stats
	current_profile["total_words_typed"] += words_typed
	current_profile["total_characters_typed"] += p_characters_typed
	current_profile["total_mistakes"] += p_mistakes
	
	# Update WPM stats
	current_profile["average_wpm"] = calculate_running_average(
		current_profile["average_wpm"], 
		current_profile["exercises_completed"],
		p_wpm
	)
	
	if p_wpm > current_profile["best_wpm"]:
		current_profile["best_wpm"] = p_wpm
	
	# Update accuracy stats
	current_profile["average_accuracy"] = calculate_running_average(
		current_profile["average_accuracy"],
		current_profile["exercises_completed"],
		p_accuracy
	)
	
	if p_accuracy > current_profile["best_accuracy"]:
		current_profile["best_accuracy"] = p_accuracy
	
	# Update completion stats
	current_profile["exercises_completed"] += 1
	
	if p_lesson_id and not p_lesson_id.is_empty():
		update_lesson_progress(p_lesson_id, p_wpm, p_accuracy)
	
	# Add to session history
	add_session_to_history(p_wpm, p_accuracy, p_characters_typed, p_mistakes)
	
	stats_updated.emit()
	save_profile()


# Calculate running average
func calculate_running_average(p_current_avg: float, p_count: int, p_new_value: float) -> float:
	return (p_current_avg * p_count + p_new_value) / (p_count + 1)


# Update lesson progress
func update_lesson_progress(p_lesson_id: String, p_wpm: float, p_accuracy: float) -> void:
	if not current_profile["lesson_progress"].has(p_lesson_id):
		current_profile["lesson_progress"][p_lesson_id] = {
			"completed": false,
			"best_wpm": 0,
			"best_accuracy": 0,
			"attempts": 0,
			"completion_date": ""
		}
	
	var lesson = current_profile["lesson_progress"][p_lesson_id]
	lesson["attempts"] += 1
	
	if p_wpm > lesson["best_wpm"]:
		lesson["best_wpm"] = p_wpm
	
	if p_accuracy > lesson["best_accuracy"]:
		lesson["best_accuracy"] = p_accuracy
	
	# Mark as completed if criteria met (example: >30 WPM and >90% accuracy)
	if p_wpm >= 30 and p_accuracy >= 90 and not lesson["completed"]:
		lesson["completed"] = true
		lesson["completion_date"] = Time.get_date_string_from_system()
		current_profile["lessons_completed"] += 1


# Add session to history
func add_session_to_history(p_wpm: float, p_accuracy: float, p_characters: int, p_mistakes: int) -> void:
	# Calculate duration safely
	var duration: float
	if p_wpm > 0:
		duration = p_characters / (p_wpm * 5 / 60)
	else:
		duration = 0.0

	var session = {
		"timestamp": Time.get_unix_time_from_system(),
		"date": Time.get_date_string_from_system(),
		"time": Time.get_time_string_from_system(),
		"wpm": p_wpm,
		"accuracy": p_accuracy,
		"characters_typed": p_characters,
		"mistakes": p_mistakes,
		"duration": duration,
	}
	
	current_profile["session_history"].push_front(session)
	
	# Keep only last 100 sessions
	if current_profile["session_history"].size() > 100:
		current_profile["session_history"].pop_back()


# Get recent session history
func get_recent_sessions(p_count: int = 10) -> Array:
	return current_profile["session_history"].slice(0, min(p_count, current_profile["session_history"].size()))


# Reset profile (for testing or new game)
func reset_profile() -> void:
	current_profile = DEFAULT_PROFILE.duplicate(true)
	save_profile()
	print("Profile reset to defaults")
