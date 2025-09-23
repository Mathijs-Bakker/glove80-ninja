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
		# _all_time_time.text = str(dict.get("total_time_typed"))
		_all_time_time.text = format_duration(dict.get("total_time_typed"))
		for key_value in dict:  # shorthand
			print(key_value, ":", dict[key_value])


func format_duration(seconds: int) -> String:
	var h = seconds / 3600
	var m = (seconds % 3600) / 60
	var s = seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]
