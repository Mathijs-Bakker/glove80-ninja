extends Node

signal user_stats_loaded
signal user_stats_saved

var _user_stats: UserStats
var _stats_path: String
var _stats: Dictionary
var _is_initialized: bool = false


func _ready() -> void:
	initialize()


func initialize() -> void:
	if _is_initialized:
		return

	if not UserService.profile_loaded.is_connected(_load_stats):
		UserService.profile_loaded.connect(_load_stats)

	_user_stats = UserStats.new()
	_is_initialized = true


func get_stats() -> UserStats:
	return _user_stats


func _create_stats_path(p_user_id) -> String:
	var prepend_path = "user://data/user_"
	return prepend_path + str(p_user_id) + "/stats.json"


func _load_stats() -> void:
	var user_data = UserService.get_user_dir_path()
	_stats_path = _create_stats_path(user_data.get("user_id"))
	Log.info("[StatsService][load_stats] Loading user stats from: %s" % _stats_path)
	_stats = DataManager.load_json(_stats_path, User.DEFAULT_STATS)

	if _stats[User.STATS.ALL_TIME_TIME_TYPED] == 0.0:
		Log.info("[StatsService][load_profile] Set stats for new user")
		# save_stats()
		DataManager.save_json(_stats_path, User.DEFAULT_STATS)

	# _stats[User.PROFILE.LAST_LOGIN_DATE] = Time.get_date_string_from_system()
	# Log.info("[StatsService][load_stats] Updated last login date")

	_user_stats.from_dict(_stats)
	Log.info(
		(
			"[StatsService][load_stats] Stats loaded successfully for user: %s"
			% UserService.get_profile()[User.PROFILE.USERNAME]
		)
	)
	user_stats_loaded.emit()


## Save user profile to file
func save_stats() -> bool:
	Log.info("[StatsService][save_stats] Saving user profile")
	_stats[User.PROFILE.LAST_LOGIN_DATE] = Time.get_date_string_from_system()
	_user_stats.to_dict(_stats)

	var success = DataManager.save_json(_stats_path, _stats)
	if success:
		Log.info("[StatsService][save_stats] User stats saved successfully")
		user_stats_saved.emit()
	else:
		Log.error("[StatsService][save_stats] Failed to save user stats")

	return success


class UserStats:
	var sts = User.STATS

	var all_time_time_typed: float
	var all_time_best_wpm: float
	var all_time_average_wpm: float
	var all_time_best_accuracy: float
	var all_time_average_accuracy: float
	var all_time_sessions_completed: float

	var today_time_typed: float
	var today_best_wpm: float
	var today_average_wpm: float
	var today_best_accuracy: float
	var today_average_accuracy: float
	var today_sessions_completed: float

	func from_dict(p_stats: Dictionary) -> void:
		all_time_time_typed = p_stats.get(User.STATS.ALL_TIME_TIME_TYPED, 0.0)
		all_time_best_wpm = p_stats.get(User.STATS.ALL_TIME_BEST_WPM, 0.0)
		all_time_average_wpm = p_stats.get(User.STATS.ALL_TIME_AVERAGE_WPM, 0.0)
		all_time_best_accuracy = p_stats.get(User.STATS.ALL_TIME_BEST_ACCURACY, 0.0)
		all_time_average_accuracy = p_stats.get(User.STATS.ALL_TIME_AVERAGE_ACCURACY, 0.0)
		all_time_sessions_completed = p_stats.get(User.STATS.ALL_TIME_SESSIONS_COMPLETED, 0.0)
		today_time_typed = p_stats.get(User.STATS.TODAY_TIME_TYPED, 0.0)
		today_best_wpm = p_stats.get(User.STATS.TODAY_BEST_WPM, 0.0)
		today_average_wpm = p_stats.get(User.STATS.TODAY_AVERAGE_WPM, 0.0)
		today_best_accuracy = p_stats.get(User.STATS.TODAY_BEST_ACCURACY, 0.0)
		today_average_accuracy = p_stats.get(User.STATS.TODAY_AVERAGE_ACCURACY, 0.0)
		today_sessions_completed = p_stats.get(User.STATS.TODAY_SESSIONS_COMPLETED, 0.0)
		Log.info("[StatsService.UserStats][from_dict] Stats loaded")

	func to_dict(p_stats: Dictionary) -> void:
		Log.info("[StatsService.ProfileStats][to_dict] Exporting statistics")
		p_stats[sts.ALL_TIME_TIME_TYPED] = all_time_time_typed
		p_stats[sts.ALL_TIME_BEST_WPM] = all_time_best_wpm
		p_stats[sts.ALL_TIME_AVERAGE_WPM] = all_time_average_wpm
		p_stats[sts.ALL_TIME_BEST_ACCURACY] = all_time_best_accuracy
		p_stats[sts.ALL_TIME_AVERAGE_ACCURACY] = all_time_average_accuracy
		p_stats[sts.ALL_TIME_SESSIONS_COMPLETED] = all_time_sessions_completed
		p_stats[sts.TODAY_TIME_TYPED] = today_time_typed
		p_stats[sts.TODAY_BEST_WPM] = today_best_wpm
		p_stats[sts.TODAY_AVERAGE_WPM] = today_average_wpm
		p_stats[sts.TODAY_BEST_ACCURACY] = today_best_accuracy
		p_stats[sts.TODAY_AVERAGE_ACCURACY] = today_average_accuracy
		p_stats[sts.TODAY_SESSIONS_COMPLETED] = today_sessions_completed

	func update_with_session(p_session_results: Dictionary) -> void:
		(
			Log
			. info(
				"[StatsService.ProfileStats][update_with_session] Updating profile sts with session data"
			)
		)

		# var session_wpm = p_session_results.get("wpm", 0.0)
		# var session_accuracy = p_session_results.get("accuracy", 0.0)
		# var session_characters = p_session_results.get("characters_typed", 0)
		# var session_mistakes = p_session_results.get("mistakes", 0)

		# total_characters_typed += session_characters
		# var word = 5.0
		# total_words_typed += int(session_characters / word)
		# total_mistakes += session_mistakes
		# sessions_completed += 1

		# # Update averages
		# if sessions_completed > 0:
		# 	average_wpm = (
		# 		(average_wpm * (sessions_completed - 1) + session_wpm) / sessions_completed
		# 	)
		# 	average_accuracy = (
		# 		(average_accuracy * (sessions_completed - 1) + session_accuracy)
		# 		/ sessions_completed
		# 	)

		# 	# Update bests
		# var new_best_wpm = false
		# var new_best_accuracy = false

		# if session_wpm > best_wpm:
		# 	best_wpm = session_wpm
		# 	new_best_wpm = true
		# if session_accuracy > best_accuracy:
		# 	best_accuracy = session_accuracy
		# 	new_best_accuracy = true
		# (
		# 	Log
		# 	. info(
		# 		(
		# 			"[StatsService.ProfileStats][update_with_session] STATS updated - New best WPM: %s (%.1f), New best accuracy: %s (%.1f%%)"
		# 			% [new_best_wpm, best_wpm, new_best_accuracy, best_accuracy]
		# 		)
		# 	)
		# )

	func get_stats() -> Dictionary:
		return {
			User.STATS.ALL_TIME_TIME_TYPED: all_time_time_typed,
			User.STATS.ALL_TIME_BEST_WPM: all_time_best_wpm,
			User.STATS.ALL_TIME_AVERAGE_WPM: all_time_average_wpm,
			User.STATS.ALL_TIME_BEST_ACCURACY: all_time_best_accuracy,
			User.STATS.ALL_TIME_AVERAGE_ACCURACY: all_time_average_accuracy,
			User.STATS.ALL_TIME_SESSIONS_COMPLETED: all_time_sessions_completed,
			User.STATS.TODAY_TIME_TYPED: today_time_typed,
			User.STATS.TODAY_BEST_WPM: today_best_wpm,
			User.STATS.TODAY_AVERAGE_WPM: today_average_wpm,
			User.STATS.TODAY_BEST_ACCURACY: today_best_accuracy,
			User.STATS.TODAY_AVERAGE_ACCURACY: today_average_accuracy,
			User.STATS.TODAY_SESSIONS_COMPLETED: today_sessions_completed,
		}
