extends Control
class_name PracticeController

## Handles all typing game logic and coordination


#region Dependencies
var typing_manager: TypingManager
var stats_manager: StatsManager
var text_display: TextDisplayManager
#endregion


#region Scene References  
@onready var sample_label: RichTextLabel = $VBoxContainer/CenterContainer/SampleLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var idle_timer: Timer = $IdleTimer
@onready var settings_btn: Button = $SettingsBtn
#endregion


#region Constants
const IDLE_TIMEOUT := 10.0
const RESULTS_DISPLAY_TIME := 2.0
#endregion


#region State
var settings_scene: Control
#endregion


func _ready() -> void:
	initialize_practice()


func initialize_practice() -> void:
	setup_managers()
	setup_ui()
	setup_timers()
	setup_connections()
	
	start_new_exercise()
	print("Typing game ready")


func setup_managers() -> void:
	typing_manager = TypingManager.new()
	stats_manager = StatsManager.new()
	
	# Initialize text_display properly
	text_display = TextDisplayManager
	
	var config_manager = get_node("/root/ConfigManager")
	text_display.setup($VBoxContainer/CenterContainer/SampleLabel, config_manager)  # Setup happens here
	text_display.apply_theme_settings()  # Apply themes here
	
	print("Managers setup complete")


func setup_ui() -> void:
	settings_btn.pressed.connect(open_settings)
	print("UI setup complete")


func setup_timers() -> void:
	idle_timer.wait_time = IDLE_TIMEOUT
	idle_timer.one_shot = true
	idle_timer.timeout.connect(_on_idle_timeout)
	print("Timers setup complete")


func setup_connections() -> void:
	# Typing manager connections
	typing_manager.typing_started.connect(_on_typing_started)
	typing_manager.typing_finished.connect(_on_typing_finished)
	typing_manager.character_typed.connect(_on_character_typed)
	typing_manager.progress_updated.connect(_on_progress_updated)
	
	# Stats manager connections
	stats_manager.stats_updated.connect(_on_stats_updated)
	print("Signal connections setup complete")


func start_new_exercise() -> void:
	var sample = TextProvider.get_random_sample()
	typing_manager.load_new_text(sample)
	stats_manager.stop_timing()
	
	# Force update display to show the new text and cursor
	update_display()
	
	TextDisplayManager.set_cursor_active(true)
	print("New exercise started: ", sample.left(50) + "..." if sample.length() > 50 else sample)


func update_display() -> void:
	# text_display.update_display(typing_manager.get_display_data())
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
	print("Settings opened")


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	
	if key_event.keycode == KEY_ESCAPE:
		toggle_settings()
		return
	
	if typing_manager.handle_input(key_event):
		reset_idle_timer()
		update_display()


func reset_idle_timer() -> void:
	if idle_timer.is_stopped():
		idle_timer.start()
	else:
		idle_timer.start(IDLE_TIMEOUT)


func toggle_settings() -> void:
	if settings_scene and settings_scene.visible:
		settings_scene.hide()
		print("Settings closed")
	else:
		open_settings()


func _on_typing_started() -> void:
	stats_manager.start_timing()
	idle_timer.start()
	print("Typing started")


func _on_typing_finished(_wpm: float, _accuracy: float, _time: float, _mistakes: int) -> void:
	complete_exercise()


func finish_typing() -> void:
	TextDisplayManager.set_cursor_active(false)


func complete_exercise() -> void:
	var final_stats = get_final_stats()
	show_results(final_stats)
	
	await get_tree().create_timer(RESULTS_DISPLAY_TIME).timeout
	start_new_exercise()


func get_final_stats() -> Dictionary:
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
	stats_label.text = results_text
	print("Exercise completed: ", results_text)


func _on_character_typed(p_correct: bool) -> void:
	stats_manager.update_wpm(typing_manager.user_input.length())
	update_display()
	
	# Visual feedback
	if p_correct:
		TextDisplayManager.show_correct_feedback()
	else:
		TextDisplayManager.show_incorrect_feedback()


func _on_progress_updated(_progress: float) -> void:
	update_display()


func _on_stats_updated(wpm: float, accuracy: float, mistakes: int) -> void:
	text_display.update_stats_display(
		{"wpm": wpm, "accuracy": accuracy, "mistakes": mistakes},
		stats_label
	)


func _on_idle_timeout() -> void:
	if typing_manager.is_typing and not typing_manager.user_input.is_empty():
		print("Resetting due to inactivity...")
		start_new_exercise()


func _on_config_changed(p_setting_name: String, _p_new_value) -> void:
	if p_setting_name == "cursor_style" or p_setting_name == "theme" or p_setting_name == "font_size":
		update_display()
		TextDisplayManager.apply_theme_settings()
