extends Control

@export var _all_time_time: Label
@export var _all_time_lessons: Label
@export var _all_time_top_speed: Label
@export var _all_time_avg_speed: Label
@export var _all_time_top_accuracy: Label
@export var _all_time_avg_accuracy: Label


func _ready() -> void:
	AppManager.app_initialized.connect(set_stats)


func set_stats() -> void:
	print("SET STATS")

	var dict = UserService.get_profile()

	if dict == null:
		Log.Error("[profile][set_stats] Error fetching stats")
	else:
		_all_time_time.text = format_duration(dict.get("total_time_typed"))
		_all_time_lessons.text = str(int(dict.get("total_sessions")))
		_all_time_top_speed.text = ("%s wpm" % String.num(dict.get("best_wpm"), 1))
		_all_time_avg_speed.text = ("%s wpm" % String.num(dict.get("average_wpm"), 1))
		_all_time_top_accuracy.text = ("%s wpm" % String.num(dict.get("best_accuracy"), 1))
		_all_time_avg_accuracy.text = ("%s wpm" % String.num(dict.get("average_accuracy"), 1))

		for key_value in dict:  # shorthand
			print(key_value, ":", dict[key_value])


func format_duration(seconds: int) -> String:
	var h: int = seconds / 3600
	var m: int = (seconds % 3600) / 60
	var s: int = seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]
