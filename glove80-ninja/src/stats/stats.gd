extends Control

@export var _all_time_time: Label
@export var _all_time_lessons: Label
@export var _all_time_top_speed: Label
@export var _all_time_avg_speed: Label
@export var _all_time_top_accuracy: Label
@export var _all_time_avg_accuracy: Label
@export var _today_time: Label
@export var _today_lessons: Label
@export var _today_top_speed: Label
@export var _today_avg_speed: Label
@export var _today_top_accuracy: Label
@export var _today_avg_accuracy: Label


func _ready() -> void:
	AppManager.app_initialized.connect(set_stats)


func set_stats() -> void:
	var user_prf: Dictionary = UserService.get_profile()

	if user_prf == null:
		Log.Error("[stats][set_stats] Error fetching stats")
	else:
		var total_sessions_completed = user_prf.get(UserService.Stats.ALL_TIME_SESSIONS_COMPLETED)

		if total_sessions_completed == 0:
			return

		_set_all_time_stats(user_prf)
		_set_today_stats(user_prf)


func _set_all_time_stats(p_user_prf: Dictionary) -> void:
	_all_time_time.text = format_duration(p_user_prf.get(UserService.Stats.ALL_TIME_TIME_TYPED))
	_all_time_lessons.text = str(int(p_user_prf.get(UserService.Stats.ALL_TIME_SESSIONS_COMPLETED)))
	_all_time_top_speed.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.ALL_TIME_BEST_WPM), 1)
	)
	_all_time_avg_speed.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.ALL_TIME_AVERAGE_WPM), 1)
	)
	_all_time_top_accuracy.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.ALL_TIME_BEST_ACCURACY), 1)
	)
	_all_time_avg_accuracy.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.ALL_TIME_AVERAGE_ACCURACY), 1)
	)


func _set_today_stats(p_user_prf: Dictionary) -> void:
	_today_time.text = format_duration(p_user_prf.get(UserService.Stats.TODAY_TIME_TYPED))
	_today_lessons.text = str(int(p_user_prf.get(UserService.Stats.TODAY_SESSIONS_COMPLETED)))
	_today_top_speed.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.TODAY_BEST_WPM), 1)
	)
	_today_avg_speed.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.TODAY_AVERAGE_WPM), 1)
	)
	_today_top_accuracy.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.TODAY_BEST_ACCURACY), 1)
	)
	_today_avg_accuracy.text = (
		"%swpm" % String.num(p_user_prf.get(UserService.Stats.TODAY_AVERAGE_ACCURACY), 1)
	)


func format_duration(seconds: int) -> String:
	var h: int = seconds / 3600
	var m: int = (seconds % 3600) / 60
	var s: int = seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]
