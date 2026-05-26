extends Control

## Focused service for managing user profiles, progress, and statistics

signal profile_loaded
signal profile_saved
signal stats_updated
signal achievement_unlocked(p_achievement_id: String)

# @export var DataManager: DataManager

var _user_dir: String
var _profile_path: String
var _current_user_id: int
var _current_profile: Dictionary = {}
var _session_stats: SessionStats
# var _profile_stats: ProfileStats


## Initialize the user service
func initialize() -> void:
	Log.info("≥≥≥ [UserService][initialize] :: START :: Initialization of the USER SERVICE")
	_session_stats = SessionStats.new()
	_current_user_id = _get_id_last_logged_in_user()
	_user_dir = get_user_dir()
	load_profile(_current_user_id)
	Log.info("≤≤≤ [UserService][initialize] :: FINISH :: USER SERVICE initialization.")


func users_file_exist() -> bool:
	var users_file = DataManager.load_json(User.USERS_PATH)
	if users_file.is_empty():
		Log.info("[UserService][users_file_exist] No userfile found.")
		return false
	return true


func _get_id_last_logged_in_user() -> int:
	Log.info("[UserService][get_last_logged_in_user] Getting last logged in user from users.json.")
	var users = DataManager.load_json(User.USERS_PATH, User.INIT_USERS_DATA)

	var _last_logged_in = users.get(User.USERS.LAST_LOGGED_IN)
	return _last_logged_in


func get_user_dir() -> String:
	return User.USER_PROFILE_PREPEND_PATH + str(_current_user_id)


# ## Returns the path of the current logged in user, for other services
# func get_user_dir_path() -> Dictionary:
# 	return {"user_dir": _user_dir, "user_id": _current_user_id}


func _format_profile_path(p_user_id) -> String:
	var user_profile_path = (
		User.USER_PROFILE_PREPEND_PATH + str(p_user_id) + "/" + User.FILE_PROFILE
	)
	return user_profile_path


func load_profile(p_user_id) -> void:
	_profile_path = _format_profile_path(p_user_id)
	Log.info("[UserService][load_profile] Loading user profile from: %s" % _profile_path)
	_current_profile = DataManager.load_json(_profile_path, User.DEFAULT_PROFILE)

	# Set creation date if not exists (new user)
	if _current_profile[User.PROFILE.CREATED_DATE].is_empty():
		_current_profile[User.PROFILE.CREATED_DATE] = Time.get_date_string_from_system()
		Log.info("[UserService][load_profile] Set creation date for new profile")
		save_profile()

	Log.info(
		(
			"[UserService][load_profile] Profile loaded for user: %s"
			% _current_profile[User.PROFILE.USERNAME]
		)
	)
	profile_loaded.emit()


## Save user profile to file
func save_profile() -> bool:
	Log.info("[UserService][save_profile] Saving user profile")
	_current_profile[User.PROFILE.LAST_LOGIN_DATE] = Time.get_date_string_from_system()
	# _profile_stats.save_to_profile(_current_profile)

	var success = DataManager.save_json(_profile_path, _current_profile)
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


## Get user profile data
func get_profile() -> Dictionary:
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

	# _profile_stats.update_with_session(p_session_results)


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
