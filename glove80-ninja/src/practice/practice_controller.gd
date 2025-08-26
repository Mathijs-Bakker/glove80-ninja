extends Control
class_name PracticeController

## Handles all typing logic and coordination


var typing_manager: TypingManager
var stats_manager: StatsManager
var text_display: TextDisplayManager

@onready var _stats_label: Label = $VBoxContainer/StatsLabel
@onready var _idle_timer: Timer = $IdleTimer
@onready var _settings_btn: Button = $SettingsBtn

const IDLE_TIMEOUT := 10.0
const RESULTS_DISPLAY_TIME := 2.0

var settings_scene: Control


func _ready() -> void:
	_initialize_practice()


func _initialize_practice() -> void:
	_setup_managers()
	_setup_ui()
	setup_timers()
	_setup_signal_connections()
	
	_start_new_exercise()


func _setup_managers() -> void:
	typing_manager = TypingManager.new()
	stats_manager = StatsManager.new()
	
	# Initialize text_display properly
	text_display = TextDisplayManager
	
	# var config_manager = get_node("/root/ConfigManager")
	text_display.setup($VBoxContainer/CenterContainer/SampleLabel, ConfigManager) 
	text_display.apply_theme_settings()  # Apply themes here
	

func _setup_ui() -> void:
	_settings_btn.pressed.connect(open_settings)


func setup_timers() -> void:
	_idle_timer.wait_time = IDLE_TIMEOUT
	_idle_timer.one_shot = true
	_idle_timer.timeout.connect(_on_idle_timeout)


func _setup_signal_connections() -> void:
	typing_manager.typing_started.connect(_on_typing_started)
	typing_manager.typing_finished.connect(_on_typing_finished)
	typing_manager.character_typed.connect(_on_character_typed)
	typing_manager.progress_updated.connect(_on_progress_updated)
	
	stats_manager.stats_updated.connect(_on_stats_updated)


func _start_new_exercise() -> void:
	var sample = TextProvider.get_random_sample()
	typing_manager.load_new_text(sample)
	stats_manager.stop_timing()
	
	_update_display()
	
	TextDisplayManager.set_cursor_active(true)


func _update_display() -> void:
	var display_data = {
		"current_text": typing_manager.current_text,
		"user_input": typing_manager.user_input,
		"current_index": typing_manager.current_char_index,
		"mistakes": typing_manager.mistakes
	}
	
	text_display.update_display(display_data)


func open_settings() -> void:
	if not settings_scene:
		settings_scene = preload("res://src/settings/settings.tscn").instantiate()
		add_child(settings_scene)
	
	settings_scene.show()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	
	if key_event.keycode == KEY_ESCAPE:
		_toggle_settings()
		return
	
	if typing_manager.handle_input(key_event):
		_reset_idle_timer()
		_update_display()


func _reset_idle_timer() -> void:
	if _idle_timer.is_stopped():
		_idle_timer.start()
	else:
		_idle_timer.start(IDLE_TIMEOUT)


func _toggle_settings() -> void:
	if settings_scene and settings_scene.visible:
		settings_scene.hide()
	else:
		open_settings()


func _on_typing_started() -> void:
	stats_manager.start_timing()
	_idle_timer.start()


func _on_typing_finished(_wpm: float, _accuracy: float, _time: float, _mistakes: int) -> void:
	_complete_exercise()


func _finish_typing() -> void:
	TextDisplayManager.set_cursor_active(false)


func _complete_exercise() -> void:
	var final_stats = _get_final_stats()
	show_results(final_stats)
	
	await get_tree().create_timer(RESULTS_DISPLAY_TIME).timeout
	_start_new_exercise()


func _get_final_stats() -> Dictionary:
	return stats_manager.get_final_stats(
		typing_manager.user_input.length(),
		typing_manager.calculate_accuracy(),
		typing_manager.mistakes
	)


func show_results(stats: Dictionary) -> void:
	var results_text = "Completed! WPM: %.1f | Accuracy: %.1f%% | Time: %.1fs | Mistakes: %d" % [
		stats.get("wpm", 0.0), 
		stats.get("accuracy", 0.0), 
		stats.get("time", 0.0),
		stats.get("mistakes", 0)
	]
	_stats_label.text = results_text


func _on_character_typed(p_correct: bool) -> void:
	stats_manager.update_wpm(typing_manager.user_input.length())
	_update_display()
	
	# Visual feedback
	if p_correct:
		TextDisplayManager.show_correct_feedback()
	else:
		TextDisplayManager.show_incorrect_feedback()


func _on_progress_updated(_progress: float) -> void:
	_update_display()


func _on_stats_updated(wpm: float, accuracy: float, mistakes: int) -> void:
	text_display.update_stats_display(
		{"wpm": wpm, "accuracy": accuracy, "mistakes": mistakes},
		_stats_label
	)


func _on_idle_timeout() -> void:
	if typing_manager.is_typing and not typing_manager.user_input.is_empty():
		_start_new_exercise()


func _on_config_changed(p_setting_name: String, _p_new_value) -> void:
	if p_setting_name == "cursor_style" or p_setting_name == "theme" or p_setting_name == "font_size":
		_update_display()
		TextDisplayManager.apply_theme_settings()
