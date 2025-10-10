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

var s := User.STATS


func _ready() -> void:
	AppManager.app_initialized.connect(_update_stats)


func _update_stats() -> void:
	var user_stats: Dictionary = StatsService.get_stats().get_stats()

	if user_stats == null:
		Log.Error("[stats][_update_stats] Error fetching stats")
	else:
		_set_all_time_stats(user_stats)
		_set_today_stats(user_stats)


func _set_all_time_stats(p_stats: Dictionary) -> void:
	_all_time_time.text = format_duration(p_stats.get(s.ALL_TIME_TIME_TYPED))
	_all_time_lessons.text = str(int(p_stats.get(s.ALL_TIME_SESSIONS_COMPLETED)))
	_all_time_top_speed.text = ("%swpm" % String.num(p_stats.get(s.ALL_TIME_BEST_WPM), 1))
	_all_time_avg_speed.text = ("%swpm" % String.num(p_stats.get(s.ALL_TIME_AVERAGE_WPM), 1))
	_all_time_top_accuracy.text = ("%swpm" % String.num(p_stats.get(s.ALL_TIME_BEST_ACCURACY), 1))
	_all_time_avg_accuracy.text = (
		"%swpm" % String.num(p_stats.get(s.ALL_TIME_AVERAGE_ACCURACY), 1)
	)


func _set_today_stats(p_stats: Dictionary) -> void:
	_today_time.text = format_duration(p_stats.get(s.TODAY_TIME_TYPED))
	_today_lessons.text = str(int(p_stats.get(s.TODAY_SESSIONS_COMPLETED)))
	_today_top_speed.text = ("%swpm" % String.num(p_stats.get(s.TODAY_BEST_WPM), 1))
	_today_avg_speed.text = ("%swpm" % String.num(p_stats.get(s.TODAY_AVERAGE_WPM), 1))
	_today_top_accuracy.text = ("%swpm" % String.num(p_stats.get(s.TODAY_BEST_ACCURACY), 1))
	_today_avg_accuracy.text = ("%swpm" % String.num(p_stats.get(s.TODAY_AVERAGE_ACCURACY), 1))


func format_duration(seconds: int) -> String:
	var h: int = seconds / 3600
	var m: int = (seconds % 3600) / 60
	var s: int = seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]
