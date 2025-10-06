extends Control

## Focused service for managing user profiles, progress, and statistics

signal profile_loaded
signal profile_saved
signal stats_updated
signal achievement_unlocked(p_achievement_id: String)

const PATH = "user://data/"
const USERS_PATH = "user://data/users.json"
const USER_PROFILE_PATH = "user://data/user_"
# const PROFILE_PATH = "user://data/profiles/default_profile.json"

# @export var DataManager: DataManager

var profile_path: String
var _current_user_id: int
var _current_profile: Dictionary = {}
var _session_stats: SessionStats
var _profile_stats: ProfileStats


## Initialize the user service
func initialize() -> void:
	Log.info("[UserService][initialize] Initializing user service")
	_session_stats = SessionStats.new()
	_profile_stats = ProfileStats.new()
	fetch_last_logged_in_user()
	load_profile(_current_user_id)
	Log.info("[UserService][initialize] User service initialized successfully")


func fetch_last_logged_in_user() -> void:
	Log.info("[UserService][fetch_last_logged_in_user]")
	var users = DataManager.load_json(USERS_PATH, User.DEFAULT_USERS)
	var _last_logged_in = users.get(User.USERS.LAST_LOGGED_IN)

	if _last_logged_in == null:
		Log.info("[UserService][fetch_last_logged_in_user] Found no existing users.")
		_current_user_id = 0
		DataManager.save_json(USERS_PATH, User.DEFAULT_USERS)
		return

	_current_user_id = _last_logged_in


func _create_profile_path(p_user_id) -> String:
	var prepend_path = "user://data/user_"
	return prepend_path + str(p_user_id) + "/user_profile.json"


## Load user profile from file
func load_profile(p_user_id) -> void:
	profile_path = _create_profile_path(p_user_id)
	Log.info("[UserService][load_profile] Loading user profile from: %s" % profile_path)
	_current_profile = DataManager.load_json(profile_path, User.DEFAULT_PROFILE)

	# Set creation date if not exists (new user)
	if _current_profile[User.PROFILE.CREATED_DATE].is_empty():
		_current_profile[User.PROFILE.CREATED_DATE] = Time.get_date_string_from_system()
		Log.info("[UserService][load_profile] Set creation date for new profile")
		save_profile()

	_current_profile[User.PROFILE.LAST_LOGIN_DATE] = Time.get_date_string_from_system()
	Log.info("[UserService][load_profile] Updated last login date")

	_profile_stats.load_from_profile(_current_profile)
	Log.info(
		(
			"[UserService][load_profile] Profile loaded successfully for user: %s"
			% _current_profile[User.PROFILE.USERNAME]
		)
	)
	profile_loaded.emit()


## Save user profile to file
func save_profile() -> bool:
	Log.info("[UserService][save_profile] Saving user profile")
	_current_profile[User.PROFILE.LAST_LOGIN_DATE] = Time.get_date_string_from_system()
	_profile_stats.save_to_profile(_current_profile)

	var success = DataManager.save_json(profile_path, _current_profile)
	if success:
		Log.info("[UserService][save_profile] User profile saved successfully")
		profile_saved.emit()
	else:
		Log.error("[UserService][save_profile] Failed to save user profile")

	return success


## Start a new typing session
func start_session() -> void:
	Log.info("[UserService][start_session] Starting new typing session")
	_session_stats.start_session()
	# _current_profile["total_sessions"] += 1
	# Log.info(
	#   (
	#       "[UserService][start_session] Session started, total sessions: %d"
	#       % _current_profile["total_sessions"]
	#   )
	# )


## End current typing session and update profile
func end_session(p_session_results: Dictionary) -> void:
	Log.info("[UserService][end_session] Ending typing session with results")
	_session_stats.end_session(p_session_results)
	_update_profile_from_session(p_session_results)
	_check_for_achievements(p_session_results)
	stats_updated.emit()
	save_profile()
	Log.info("[UserService][end_session] Session ended and profile updated")


## Get current session statistics
func get_session_stats() -> Dictionary:
	Log.info("[UserService][get_session_stats] Getting session statistics")
	return _session_stats.get_stats()


## Get profile statistics
func get_profile_stats() -> Dictionary:
	Log.info("[UserService][get_profile_stats] Getting profile statistics")
	return _profile_stats.get_stats()


## Get user profile data
func get_profile() -> Dictionary:
	Log.info("[UserService][get_profile] Getting user profile data")
	return _current_profile.duplicate(true)


## Update username
func set_username(p_new_username: String) -> void:
	Log.info("[UserService][set_username] Setting username to: %s" % p_new_username)
	var old_username = _current_profile[User.PROFILE.USERNAME]
	_current_profile[User.PROFILE.USERNAME] = p_new_username
	save_profile()
	Log.info(
		(
			"[UserService][set_username] Username changed from %s to %s"
			% [old_username, p_new_username]
		)
	)


## Add achievement to user profile
func unlock_achievement(p_achievement_id: String) -> bool:
	Log.info(
		"[UserService][unlock_achievement] Attempting to unlock achievement: %s" % p_achievement_id
	)

	if p_achievement_id in _current_profile["achievements"]:
		Log.info(
			"[UserService][unlock_achievement] Achievement already unlocked: %s" % p_achievement_id
		)
		return false  # Already unlocked

	_current_profile["achievements"].append(p_achievement_id)
	Log.info("[UserService][unlock_achievement] Achievement unlocked: %s" % p_achievement_id)
	achievement_unlocked.emit(p_achievement_id)
	save_profile()
	return true


## Check if achievement is unlocked
func has_achievement(p_achievement_id: String) -> bool:
	var has_it = p_achievement_id in _current_profile["achievements"]
	Log.info(
		"[UserService][has_achievement] Checking achievement %s: %s" % [p_achievement_id, has_it]
	)
	return has_it


## Get all unlocked achievements
func get_achievements() -> Array:
	Log.info(
		(
			"[UserService][get_achievements] Getting all achievements (%d total)"
			% _current_profile["achievements"].size()
		)
	)
	return _current_profile["achievements"].duplicate()


## Reset profile to defaults (for testing or new user)
func reset_profile() -> void:
	Log.info("[UserService][reset_profile] Resetting profile to defaults")
	var backup_created = DataManager.create_backup(profile_path)
	if backup_created:
		Log.info("[UserService][reset_profile] Profile backup created before reset")
	else:
		Log.warn("[UserService][reset_profile] Failed to create backup before reset")

	_current_profile = User.DEFAULT_PROFILE.duplicate(true)
	_current_profile[User.PROFILE.CREATED_DATE] = Time.get_date_string_from_system()
	_profile_stats = ProfileStats.new()
	save_profile()
	Log.info("[UserService][reset_profile] Profile reset complete")


## Export profile for backup
func export_profile(p_export_path: String) -> bool:
	Log.info("[UserService][export_profile] Exporting profile to: %s" % p_export_path)
	var success = DataManager.save_json(p_export_path, _current_profile)

	if success:
		Log.info("[UserService][export_profile] Profile exported successfully")
	else:
		Log.error("[UserService][export_profile] Failed to export profile")

	return success


## Import profile from backup
func import_profile(p_import_path: String) -> bool:
	Log.info("[UserService][import_profile] Importing profile from: %s" % p_import_path)

	if not FileAccess.file_exists(p_import_path):
		Log.error("[UserService][import_profile] Import file does not exist: %s" % p_import_path)
		return false

	var imported_profile = DataManager.load_json(p_import_path, {})
	if imported_profile.is_empty():
		Log.error("[UserService][import_profile] Failed to load import file or file is empty")
		return false

	# Validate required fields
	var required_fields = [User.PROFILE.USERNAME]
	if not DataManager.validate_json_schema(imported_profile, required_fields):
		Log.error("[UserService][import_profile] Import file missing required fields")
		return false

	_current_profile = imported_profile
	_profile_stats.load_from_profile(_current_profile)
	var success = save_profile()

	if success:
		Log.info(
			(
				"[UserService][import_profile] Profile imported successfully for user: %s"
				% _current_profile[User.PROFILE.USERNAME]
			)
		)
	else:
		Log.error("[UserService][import_profile] Failed to save imported profile")

	return success


# Private methods


func _update_profile_from_session(p_session_results: Dictionary) -> void:
	Log.info("[UserService][_update_profile_from_session] Updating profile with session results")

	var session_time = p_session_results.get("duration", 0.0)

	_current_profile["total_time_typed"] += session_time

	Log.info(
		(
			"[UserService][_update_profile_from_session] Session time: %.1fs, Experience gained: %d"
			% [session_time]
		)
	)

	_profile_stats.update_with_session(p_session_results)


func _calculate_experience_gain(p_session_results: Dictionary) -> int:
	var base_exp = 10
	var wpm_bonus = int(p_session_results.get("wpm", 0) * 0.5)
	var accuracy_bonus = int(p_session_results.get("accuracy", 0) * 0.2)
	var total_exp = base_exp + wpm_bonus + accuracy_bonus

	(
		Log
		. info(
			(
				"[UserService][_calculate_experience_gain] Base: %d, WPM bonus: %d, Accuracy bonus: %d, Total: %d"
				% [base_exp, wpm_bonus, accuracy_bonus, total_exp]
			)
		)
	)
	return total_exp


func _check_for_achievements(p_session_results: Dictionary) -> void:
	Log.info("[UserService][_check_for_achievements] Checking for new achievements")

	var wpm = p_session_results.get("wpm", 0.0)
	var accuracy = p_session_results.get("accuracy", 0.0)
	var achievements_unlocked = 0

	# Example achievements
	if wpm >= 30 and not has_achievement("speed_demon_30"):
		unlock_achievement("speed_demon_30")
		achievements_unlocked += 1

	if wpm >= 60 and not has_achievement("speed_demon_60"):
		unlock_achievement("speed_demon_60")
		achievements_unlocked += 1

	if accuracy >= 95 and not has_achievement("precision_master"):
		unlock_achievement("precision_master")
		achievements_unlocked += 1

	if _current_profile["total_sessions"] >= 10 and not has_achievement("dedicated_typist"):
		unlock_achievement("dedicated_typist")
		achievements_unlocked += 1

	(
		Log
		. info(
			(
				"[UserService][_check_for_achievements] Achievement check complete, %d new achievements unlocked"
				% achievements_unlocked
			)
		)
	)


# Inner classes for better organization


class SessionStats:
	var start_time: int = 0
	var current_wpm: float = 0.0
	var current_accuracy: float = 0.0
	var characters_typed: int = 0
	var mistakes: int = 0
	var is_active: bool = false

	func start_session() -> void:
		Log.info("[UserService.SessionStats][start_session] Starting session statistics tracking")
		start_time = Time.get_ticks_msec()
		current_wpm = 0.0
		current_accuracy = 100.0
		characters_typed = 0
		mistakes = 0
		is_active = true

	func end_session(p_results: Dictionary) -> void:
		Log.info("[UserService.SessionStats][end_session] Ending session statistics tracking")
		current_wpm = p_results.get("wpm", 0.0)
		current_accuracy = p_results.get("accuracy", 0.0)
		characters_typed = p_results.get("characters_typed", 0)
		mistakes = p_results.get("mistakes", 0)
		is_active = false
		(
			Log
			. info(
				(
					"[UserService.SessionStats][end_session] Final stats - WPM: %.1f, Accuracy: %.1f%%, Characters: %d, Mistakes: %d"
					% [current_wpm, current_accuracy, characters_typed, mistakes]
				)
			)
		)

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

	func load_from_profile(p_profile: Dictionary) -> void:
		# total_words_typed = p_profile.get(STATS.ALL_TIME_WORDS_TYPED, 0)
		# total_characters_typed = p_profile.get(STATS.ALL_TIME_CHARS_TYPED, 0)
		average_wpm = p_profile.get(User.STATS.ALL_TIME_AVERAGE_WPM, 0.0)
		best_wpm = p_profile.get(User.STATS.ALL_TIME_BEST_WPM, 0.0)
		average_accuracy = p_profile.get(User.STATS.ALL_TIME_AVERAGE_ACCURACY, 0.0)
		best_accuracy = p_profile.get(User.STATS.ALL_TIME_BEST_ACCURACY, 0.0)
		# total_mistakes = p_profile.get(STATS.ALL_TIME_MISTAKES, 0)
		sessions_completed = p_profile.get(User.STATS.ALL_TIME_SESSIONS_COMPLETED, 0)
		(
			Log
			. info(
				(
					"[UserService.ProfileStats][load_from_profile] Loaded stats - Sessions: %d, Best WPM: %.1f, Best Accuracy: %.1f%%"
					% [sessions_completed, best_wpm, best_accuracy]
				)
			)
		)

	func save_to_profile(p_profile: Dictionary) -> void:
		Log.info("[UserService.ProfileStats][save_to_profile] Saving profile statistics")
		p_profile["total_words_typed"] = total_words_typed
		p_profile["total_characters_typed"] = total_characters_typed
		p_profile["average_wpm"] = average_wpm
		p_profile["best_wpm"] = best_wpm
		p_profile["average_accuracy"] = average_accuracy
		p_profile["best_accuracy"] = best_accuracy
		p_profile["total_mistakes"] = total_mistakes
		p_profile["sessions_completed"] = sessions_completed

	func update_with_session(p_session_results: Dictionary) -> void:
		(
			Log
			. info(
				"[UserService.ProfileStats][update_with_session] Updating profile stats with session data"
			)
		)

		var session_wpm = p_session_results.get("wpm", 0.0)
		var session_accuracy = p_session_results.get("accuracy", 0.0)
		var session_characters = p_session_results.get("characters_typed", 0)
		var session_mistakes = p_session_results.get("mistakes", 0)

		total_characters_typed += session_characters
		var word = 5.0
		total_words_typed += int(session_characters / word)
		total_mistakes += session_mistakes
		sessions_completed += 1

		# Update averages
		if sessions_completed > 0:
			average_wpm = (
				(average_wpm * (sessions_completed - 1) + session_wpm) / sessions_completed
			)
			average_accuracy = (
				(average_accuracy * (sessions_completed - 1) + session_accuracy)
				/ sessions_completed
			)

		# Update bests
		var new_best_wpm = false
		var new_best_accuracy = false

		if session_wpm > best_wpm:
			best_wpm = session_wpm
			new_best_wpm = true

		if session_accuracy > best_accuracy:
			best_accuracy = session_accuracy
			new_best_accuracy = true

		(
			Log
			. info(
				(
					"[UserService.ProfileStats][update_with_session] STATS updated - New best WPM: %s (%.1f), New best accuracy: %s (%.1f%%)"
					% [new_best_wpm, best_wpm, new_best_accuracy, best_accuracy]
				)
			)
		)

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
