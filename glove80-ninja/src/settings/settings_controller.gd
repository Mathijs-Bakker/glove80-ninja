class_name SettingsController
extends Control

signal settings_closed

var config_service
var has_unsaved_changes: bool = false
var original_settings: Dictionary = {}
var _pending_config_service
var _initialization_pending: bool = false

@onready var stop_cursor_on_error_checkbox: CheckBox = %StopCursorOnErrorCheckBox
@onready var forgive_errors_checkbox: CheckBox = %ForgiveErrorsCheckBox
@onready var space_skips_words_checkbox: CheckBox = %SpaceSkipsWordsCheckBox
@onready var whitespace_option: OptionButton = %WhitespaceOption
@onready var cursor_style_option: OptionButton = %CursorStyleOption
@onready var theme_option: OptionButton = %ThemeOption
@onready var font_size_spinbox: SpinBox = %FontSizeSpinBox
@onready var sound_volume_slider: HSlider = %SoundVolumeSlider
@onready var typing_sounds_checkbox: CheckBox = %TypingSoundsCheckBox
@onready var language_option: OptionButton = %LanguageOption
@onready var save_button: Button = %SaveButton
@onready var cancel_button: Button = %CancelButton
@onready var defaults_button: Button = %DefaultsButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_setup_ui()
	if _initialization_pending:
		_execute_initialization()


func initialize(p_config_service) -> void:
	_pending_config_service = p_config_service
	_initialization_pending = true

	if is_node_ready():
		_execute_initialization()


func _execute_initialization() -> void:
	config_service = _pending_config_service
	_initialization_pending = false

	if config_service and not config_service.setting_changed.is_connected(_on_setting_changed):
		config_service.setting_changed.connect(_on_setting_changed)

	_load_current_settings()


func save_settings() -> void:
	if not config_service:
		return

	var updated_settings = _get_settings_from_ui()
	for setting_name in updated_settings:
		config_service.set_user_setting(setting_name, updated_settings[setting_name])

	if config_service.save_user_config():
		original_settings = updated_settings
		has_unsaved_changes = false
		_update_button_states()


func cancel_changes() -> void:
	_apply_settings_to_ui(original_settings)
	has_unsaved_changes = false
	_update_button_states()


func reset_to_defaults() -> void:
	_apply_settings_to_ui(User.DEFAULT_USER_SETTINGS)
	has_unsaved_changes = true
	_update_button_states()


func close_settings() -> void:
	if has_unsaved_changes:
		cancel_changes()

	settings_closed.emit()


func _setup_ui() -> void:
	_configure_options()
	_connect_signals()
	_update_button_states()


func _configure_options() -> void:
	whitespace_option.clear()
	whitespace_option.add_item("Show", 0)
	whitespace_option.add_item("Bar", 1)
	whitespace_option.add_item("Bullet", 2)

	cursor_style_option.clear()
	cursor_style_option.add_item("Block", 0)
	cursor_style_option.add_item("Box", 1)
	cursor_style_option.add_item("Line", 2)
	cursor_style_option.add_item("Underline", 3)

	theme_option.clear()
	theme_option.add_item("Dark", 0)
	theme_option.add_item("Light", 1)
	theme_option.add_item("High Contrast", 2)

	language_option.clear()
	language_option.add_item("English", 0)
	language_option.add_item("Spanish", 1)
	language_option.add_item("French", 2)
	language_option.add_item("German", 3)

	font_size_spinbox.min_value = 16
	font_size_spinbox.max_value = 48
	font_size_spinbox.step = 1

	sound_volume_slider.min_value = 0
	sound_volume_slider.max_value = 100
	sound_volume_slider.step = 1


func _connect_signals() -> void:
	stop_cursor_on_error_checkbox.toggled.connect(_on_ui_changed)
	forgive_errors_checkbox.toggled.connect(_on_ui_changed)
	space_skips_words_checkbox.toggled.connect(_on_ui_changed)
	typing_sounds_checkbox.toggled.connect(_on_ui_changed)
	whitespace_option.item_selected.connect(_on_option_changed)
	cursor_style_option.item_selected.connect(_on_option_changed)
	theme_option.item_selected.connect(_on_option_changed)
	language_option.item_selected.connect(_on_option_changed)
	font_size_spinbox.value_changed.connect(_on_value_changed)
	sound_volume_slider.value_changed.connect(_on_value_changed)
	save_button.pressed.connect(save_settings)
	cancel_button.pressed.connect(cancel_changes)
	defaults_button.pressed.connect(reset_to_defaults)
	back_button.pressed.connect(close_settings)


func _load_current_settings() -> void:
	if not config_service:
		return

	original_settings = User.DEFAULT_USER_SETTINGS.duplicate(true)
	for setting_name in original_settings:
		original_settings[setting_name] = config_service.get_setting(
			setting_name,
			original_settings[setting_name]
		)

	_apply_settings_to_ui(original_settings)
	has_unsaved_changes = false
	_update_button_states()


func _apply_settings_to_ui(p_settings: Dictionary) -> void:
	stop_cursor_on_error_checkbox.button_pressed = p_settings.get(
		User.SETTINGS.STOP_CURSOR_ON_ERROR,
		true
	)
	forgive_errors_checkbox.button_pressed = p_settings.get(User.SETTINGS.FORGIVE_ERRORS, false)
	space_skips_words_checkbox.button_pressed = p_settings.get(
		User.SETTINGS.SPACE_SKIPS_WORDS,
		false
	)
	typing_sounds_checkbox.button_pressed = p_settings.get("typing_sounds", true)
	font_size_spinbox.value = p_settings.get("font_size", 28)
	sound_volume_slider.value = p_settings.get("sound_volume", 80)
	_select_option(whitespace_option, ["show", "bar", "bullet"], p_settings.get(User.SETTINGS.SHOW_WHITESPACE, "bullet"))
	_select_option(cursor_style_option, ["block", "box", "line", "underline"], p_settings.get(User.SETTINGS.CURSOR_SHAPE, "block"))
	_select_option(theme_option, ["dark", "light", "high_contrast"], p_settings.get("theme", "dark"))
	_select_option(language_option, ["en", "es", "fr", "de"], p_settings.get("language", "en"))


func _get_settings_from_ui() -> Dictionary:
	return {
		User.SETTINGS.STOP_CURSOR_ON_ERROR: stop_cursor_on_error_checkbox.button_pressed,
		User.SETTINGS.FORGIVE_ERRORS: forgive_errors_checkbox.button_pressed,
		User.SETTINGS.SPACE_SKIPS_WORDS: space_skips_words_checkbox.button_pressed,
		User.SETTINGS.SHOW_WHITESPACE: _get_selected_value(
			whitespace_option,
			["show", "bar", "bullet"]
		),
		User.SETTINGS.CURSOR_SHAPE: _get_selected_value(
			cursor_style_option,
			["block", "box", "line", "underline"]
		),
		"theme": _get_selected_value(theme_option, ["dark", "light", "high_contrast"]),
		"font_size": int(font_size_spinbox.value),
		"sound_volume": int(sound_volume_slider.value),
		"typing_sounds": typing_sounds_checkbox.button_pressed,
		"language": _get_selected_value(language_option, ["en", "es", "fr", "de"]),
	}


func _select_option(p_option: OptionButton, p_values: Array[String], p_value: String) -> void:
	var index = p_values.find(p_value)
	p_option.select(index if index >= 0 else 0)


func _get_selected_value(p_option: OptionButton, p_values: Array[String]) -> String:
	var selected_index = clampi(p_option.selected, 0, p_values.size() - 1)
	return p_values[selected_index]


func _mark_dirty() -> void:
	has_unsaved_changes = _get_settings_from_ui() != original_settings
	_update_button_states()


func _update_button_states() -> void:
	save_button.disabled = not has_unsaved_changes
	cancel_button.disabled = not has_unsaved_changes


func _on_ui_changed(_value) -> void:
	_mark_dirty()


func _on_option_changed(_index: int) -> void:
	_mark_dirty()


func _on_value_changed(_value: float) -> void:
	_mark_dirty()


func _on_setting_changed(_setting_name: String, _new_value) -> void:
	if has_unsaved_changes:
		return

	_load_current_settings()


func _input(p_event: InputEvent) -> void:
	if not p_event is InputEventKey:
		return

	var key_event = p_event as InputEventKey
	if not key_event.pressed:
		return

	match key_event.keycode:
		KEY_ESCAPE:
			close_settings()
		KEY_S:
			if key_event.ctrl_pressed and has_unsaved_changes:
				save_settings()
