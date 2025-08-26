class_name UserService
extends RefCounted

## Focused service for managing user profiles, progress, and statistics
## Replaces UserProfileManager with better separation of concerns


signal profile_loaded()
signal profile_saved()
signal stats_updated()
signal achievement_unlocked(achievement_id: String)

const PROFILE_PATH = "user://data/profiles/default_profile.json"

# Default profile structure
const DEFAULT_PROFILE = {
	"username": "Typist",
	"created_date": "",
	"last_login_date": "",
	"level": 1,
	"experience": 0,
	"total_sessions": 0,
	"total_time_typed": 0,
	"achievements": [],
	"preferences": {
		"preferred_lessons": [],
		"difficulty_level": "beginner"
	}
}

var _current_profile: Dictionary = {}
var _session_stats: SessionStats
var _profile_stats: ProfileStats


## Initialize the user service
func initialize() -> void:
	_session_stats = SessionStats.new()
	_profile_stats = ProfileStats.new()
	load_profile()


## Load user profile from file
func load_profile() -> void:
	_current_profile = DataManager.load_json(PROFILE_PATH, DEFAULT_PROFILE)

	# Set creation date if not exists
	if _current_profile["created_date"].is_empty():
		_current_profile["created_date"] = Time.get_date_string_from_system()

	_current_profile["last_login_date"] = Time.get_date_string_from_system()

	_profile_stats.load_from_profile(_current_profile)
	profile_loaded.emit()


## Save user profile to file
func save_profile() -> bool:
	_current_profile["last_login_date"] = Time.get_date_string_from_system()
	_profile_stats.save_to_profile(_current_profile)

	var success = DataManager.save_json(PROFILE_PATH, _current_profile)
	if success:
		profile_saved.emit()
	else:
		push_error("Failed to save user profile")

	return success


## Start a new typing session
func start_session() -> void:
	_session_stats.start_session()
	_current_profile["total_sessions"] += 1


## End current typing session and update profile
func end_session(session_results: Dictionary) -> void:
	_session_stats.end_session(session_results)
	_update_profile_from_session(session_results)
	_check_for_achievements(session_results)
	stats_updated.emit()
	save_profile()


## Get current session statistics
func get_session_stats() -> Dictionary:
	return _session_stats.get_stats()


## Get profile statistics
func get_profile_stats() -> Dictionary:
	return _profile_stats.get_stats()


## Get user profile data
func get_profile() -> Dictionary:
	return _current_profile.duplicate(true)


## Update username
func set_username(new_username: String) -> void:
	_current_profile["username"] = new_username
	save_profile()


## Add achievement to user profile
func unlock_achievement(achievement_id: String) -> bool:
	if achievement_id in _current_profile["achievements"]:
		return false  # Already unlocked

	_current_profile["achievements"].append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	save_profile()
	return true


## Check if achievement is unlocked
func has_achievement(achievement_id: String) -> bool:
	return achievement_id in _current_profile["achievements"]


## Get all unlocked achievements
func get_achievements() -> Array:
	return _current_profile["achievements"].duplicate()


## Reset profile to defaults (for testing or new user)
func reset_profile() -> void:
	var backup_created = DataManager.create_backup(PROFILE_PATH)
	if backup_created:
		print("Profile backup created before reset")

	_current_profile = DEFAULT_PROFILE.duplicate(true)
	_current_profile["created_date"] = Time.get_date_string_from_system()
	_profile_stats = ProfileStats.new()
	save_profile()


## Export profile for backup
func export_profile(export_path: String) -> bool:
	return DataManager.save_json(export_path, _current_profile)


## Import profile from backup
func import_profile(import_path: String) -> bool:
	if not FileAccess.file_exists(import_path):
		return false

	var imported_profile = DataManager.load_json(import_path, {})
	if imported_profile.is_empty():
		return false

	# Validate required fields
	var required_fields = ["username", "level", "experience"]
	if not DataManager.validate_json_schema(imported_profile, required_fields):
		return false

	_current_profile = imported_profile
	_profile_stats.load_from_profile(_current_profile)
	return save_profile()


# Private methods

func _update_profile_from_session(session_results: Dictionary) -> void:
	var session_time = session_results.get("duration", 0.0)
	var experience_gained = _calculate_experience_gain(session_results)

	_current_profile["total_time_typed"] += session_time
	_current_profile["experience"] += experience_gained

	# Update level based on experience
	var new_level = _calculate_level_from_experience(_current_profile["experience"])
	if new_level > _current_profile["level"]:
		_current_profile["level"] = new_level
		# Could trigger level up achievement here


func _calculate_experience_gain(session_results: Dictionary) -> int:
	var base_exp = 10
	var wpm_bonus = int(session_results.get("wpm", 0) * 0.5)
	var accuracy_bonus = int(session_results.get("accuracy", 0) * 0.2)

	return base_exp + wpm_bonus + accuracy_bonus


func _calculate_level_from_experience(experience: int) -> int:
	# Simple level calculation: every 1000 exp = 1 level
	return max(1, int(experience / 1000) + 1)


func _check_for_achievements(session_results: Dictionary) -> void:
	var wpm = session_results.get("wpm", 0.0)
	var accuracy = session_results.get("accuracy", 0.0)

	# Example achievements
	if wpm >= 30 and not has_achievement("speed_demon_30"):
		unlock_achievement("speed_demon_30")

	if wpm >= 60 and not has_achievement("speed_demon_60"):
		unlock_achievement("speed_demon_60")

	if accuracy >= 95 and not has_achievement("precision_master"):
		unlock_achievement("precision_master")

	if _current_profile["total_sessions"] >= 10 and not has_achievement("dedicated_typist"):
		unlock_achievement("dedicated_typist")


# Inner classes for better organization

class SessionStats:
	var start_time: int = 0
	var current_wpm: float = 0.0
	var current_accuracy: float = 0.0
	var characters_typed: int = 0
	var mistakes: int = 0
	var is_active: bool = false

	func start_session() -> void:
		start_time = Time.get_ticks_msec()
		current_wpm = 0.0
		current_accuracy = 100.0
		characters_typed = 0
		mistakes = 0
		is_active = true

	func end_session(results: Dictionary) -> void:
		current_wpm = results.get("wpm", 0.0)
		current_accuracy = results.get("accuracy", 0.0)
		characters_typed = results.get("characters_typed", 0)
		mistakes = results.get("mistakes", 0)
		is_active = false

	func get_stats() -> Dictionary:
		return {
			"wpm": current_wpm,
			"accuracy": current_accuracy,
			"characters_typed": characters_typed,
			"mistakes": mistakes,
			"is_active": is_active,
			"session_duration": (Time.get_ticks_msec() - start_time) / 1000.0 if is_active else 0.0
		}


class ProfileStats:
	var total_words_typed: int = 0
	var total_characters_typed: int = 0
	var average_wpm: float = 0.0
	var best_wpm: float = 0.0
	var average_accuracy: float = 0.0
	var best_accuracy: float = 0.0
	var total_mistakes: int = 0
	var sessions_completed: int = 0

	func load_from_profile(profile: Dictionary) -> void:
		total_words_typed = profile.get("total_words_typed", 0)
		total_characters_typed = profile.get("total_characters_typed", 0)
		average_wpm = profile.get("average_wpm", 0.0)
		best_wpm = profile.get("best_wpm", 0.0)
		average_accuracy = profile.get("average_accuracy", 0.0)
		best_accuracy = profile.get("best_accuracy", 0.0)
		total_mistakes = profile.get("total_mistakes", 0)
		sessions_completed = profile.get("sessions_completed", 0)

	func save_to_profile(profile: Dictionary) -> void:
		profile["total_words_typed"] = total_words_typed
		profile["total_characters_typed"] = total_characters_typed
		profile["average_wpm"] = average_wpm
		profile["best_wpm"] = best_wpm
		profile["average_accuracy"] = average_accuracy
		profile["best_accuracy"] = best_accuracy
		profile["total_mistakes"] = total_mistakes
		profile["sessions_completed"] = sessions_completed

	func update_with_session(session_results: Dictionary) -> void:
		var session_wpm = session_results.get("wpm", 0.0)
		var session_accuracy = session_results.get("accuracy", 0.0)
		var session_characters = session_results.get("characters_typed", 0)
		var session_mistakes = session_results.get("mistakes", 0)

		total_characters_typed += session_characters
		total_words_typed += int(session_characters / 5.0)
		total_mistakes += session_mistakes
		sessions_completed += 1

		# Update averages
		if sessions_completed > 0:
			average_wpm = (average_wpm * (sessions_completed - 1) + session_wpm) / sessions_completed
			average_accuracy = (average_accuracy * (sessions_completed - 1) + session_accuracy) / sessions_completed

		# Update bests
		if session_wpm > best_wpm:
			best_wpm = session_wpm
		if session_accuracy > best_accuracy:
			best_accuracy = session_accuracy

	func get_stats() -> Dictionary:
		return {
			"total_words_typed": total_words_typed,
			"total_characters_typed": total_characters_typed,
			"average_wpm": average_wpm,
			"best_wpm": best_wpm,
			"average_accuracy": average_accuracy,
			"best_accuracy": best_accuracy,
			"total_mistakes": total_mistakes,
			"sessions_completed": sessions_completed
		}
