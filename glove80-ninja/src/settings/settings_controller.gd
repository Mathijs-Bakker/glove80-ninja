class_name SettingsController
extends Control

## Settings controller that works with the new refactored architecture
## Uses ConfigService for all configuration management

signal settings_closed()

# Services
var config_service: ConfigService

# UI References
@onready var cursor_style_option: OptionButton = $VBoxContainer/SettingsContainer/CursorStyleContainer/CursorStyleOption
@onready var theme_option: OptionButton = $VBoxContainer/SettingsContainer/ThemeContainer/ThemeOption
@onready var font_size_spinbox: SpinBox = $VBoxContainer/SettingsContainer/FontSizeContainer/FontSizeSpinBox
@onready var sound_volume_slider: HSlider = $VBoxContainer/SettingsContainer/SoundVolumeContainer/SoundVolumeSlider
@onready var typing_sounds_checkbox: CheckBox = $VBoxContainer/SettingsContainer/TypingSoundsContainer/TypingSoundsCheckBox
@onready var language_option: OptionButton = $VBoxContainer/SettingsContainer/LanguageContainer/LanguageOption

@onready var save_button: Button = $VBoxContainer/ButtonContainer/SaveButton
@onready var cancel_button: Button = $VBoxContainer/ButtonContainer/CancelButton
@onready var reset_button: Button = $VBoxContainer/ButtonContainer/ResetButton

# State tracking
var has_unsaved_changes: bool = false
var original_settings: Dictionary = {}


func _ready() -> void:
	_setup_ui()


## Initialize the settings controller with config service
func initialize(p_config_service: ConfigService) -> void:
	config_service = p_config_service
	if config_service:
		config_service.setting_changed.connect(_on_setting_changed)
	_load_current_settings()


## Load current settings from config service
func _load_current_settings() -> void:
	if not config_service:
		return

	# Store original settings for comparison
	original_settings = {
		"cursor_style": config_service.get_setting("cursor_style", "block"),
		"theme": config_service.get_setting("theme", "dark"),
		"font_size": config_service.get_setting("font_size", 16),
		"sound_volume": config_service.get_setting("sound_volume", 80),
		"typing_sounds": config_service.get_setting("typing_sounds", true),
		"language": config_service.get_setting("language", "en")
	}

	# Apply settings to UI
	_apply_settings_to_ui()
	has_unsaved_changes = false
	_update_button_states()


## Apply current settings to UI controls
func _apply_settings_to_ui() -> void:
	if cursor_style_option:
		var cursor_style = original_settings.get("cursor_style", "block")
		cursor_style_option.select(_get_cursor_style_index(cursor_style))

	if theme_option:
		var theme_name = original_settings.get("theme", "dark")
		theme_option.select(_get_theme_index(theme_name))

	if font_size_spinbox:
		font_size_spinbox.value = original_settings.get("font_size", 16)

	if sound_volume_slider:
		sound_volume_slider.value = original_settings.get("sound_volume", 80)

	if typing_sounds_checkbox:
		typing_sounds_checkbox.button_pressed = original_settings.get("typing_sounds", true)

	if language_option:
		var language = original_settings.get("language", "en")
		language_option.select(_get_language_index(language))


## Save current settings
func save_settings() -> void:
	if not config_service:
		return

	# Apply all UI values to config service
	if cursor_style_option:
		var cursor_styles = ["block", "line", "underline"]
		var selected_style = cursor_styles[cursor_style_option.selected]
		config_service.set_user_setting("cursor_style", selected_style)

	if theme_option:
		var themes = ["dark", "light", "high_contrast"]
		var selected_theme = themes[theme_option.selected]
		config_service.set_user_setting("theme", selected_theme)

	if font_size_spinbox:
		config_service.set_user_setting("font_size", int(font_size_spinbox.value))

	if sound_volume_slider:
		config_service.set_user_setting("sound_volume", int(sound_volume_slider.value))

	if typing_sounds_checkbox:
		config_service.set_user_setting("typing_sounds", typing_sounds_checkbox.button_pressed)

	if language_option:
		var languages = ["en", "es", "fr", "de"]
		var selected_language = languages[language_option.selected]
		config_service.set_user_setting("language", selected_language)

	# Save to file
	config_service.save_user_config()

	# Update state
	_load_current_settings()  # Refresh original settings
	print("Settings saved successfully")


## Cancel changes and revert to original settings
func cancel_changes() -> void:
	_apply_settings_to_ui()
	has_unsaved_changes = false
	_update_button_states()
	print("Settings changes cancelled")


## Reset all settings to defaults
func reset_to_defaults() -> void:
	if not config_service:
		return

	# Show confirmation dialog
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to reset all settings to defaults?"
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

	var confirmed = await confirm_dialog.confirmed
	confirm_dialog.queue_free()

	if confirmed:
		config_service.reset_user_config_to_defaults(true)
		_load_current_settings()
		print("Settings reset to defaults")


## Close the settings panel
func close_settings() -> void:
	if has_unsaved_changes:
		var confirm_dialog = ConfirmationDialog.new()
		confirm_dialog.dialog_text = "You have unsaved changes. Do you want to save before closing?"
		confirm_dialog.add_button("Don't Save", false, "dont_save")
		add_child(confirm_dialog)
		confirm_dialog.popup_centered()

		var result = await confirm_dialog.custom_action
		confirm_dialog.queue_free()

		if result == "":  # OK button (save)
			save_settings()
		elif result == "dont_save":
			cancel_changes()
		else:  # Cancel button
			return

	settings_closed.emit()


# Private methods

func _setup_ui() -> void:
	# Setup cursor style options
	if cursor_style_option:
		cursor_style_option.add_item("Block Cursor")
		cursor_style_option.add_item("Line Cursor")
		cursor_style_option.add_item("Underline Cursor")
		cursor_style_option.item_selected.connect(_on_cursor_style_changed)

	# Setup theme options
	if theme_option:
		theme_option.add_item("Dark Theme")
		theme_option.add_item("Light Theme")
		theme_option.add_item("High Contrast")
		theme_option.item_selected.connect(_on_theme_changed)

	# Setup font size
	if font_size_spinbox:
		font_size_spinbox.min_value = 12
		font_size_spinbox.max_value = 24
		font_size_spinbox.step = 1
		font_size_spinbox.value_changed.connect(_on_font_size_changed)

	# Setup sound volume
	if sound_volume_slider:
		sound_volume_slider.min_value = 0
		sound_volume_slider.max_value = 100
		sound_volume_slider.step = 1
		sound_volume_slider.value_changed.connect(_on_sound_volume_changed)

	# Setup typing sounds checkbox
	if typing_sounds_checkbox:
		typing_sounds_checkbox.toggled.connect(_on_typing_sounds_toggled)

	# Setup language options
	if language_option:
		language_option.add_item("English")
		language_option.add_item("Spanish")
		language_option.add_item("French")
		language_option.add_item("German")
		language_option.item_selected.connect(_on_language_changed)

	# Setup buttons
	if save_button:
		save_button.pressed.connect(save_settings)

	if cancel_button:
		cancel_button.pressed.connect(cancel_changes)

	if reset_button:
		reset_button.pressed.connect(reset_to_defaults)


func _update_button_states() -> void:
	if save_button:
		save_button.disabled = not has_unsaved_changes

	if cancel_button:
		cancel_button.disabled = not has_unsaved_changes


func _get_cursor_style_index(style: String) -> int:
	match style:
		"block": return 0
		"line": return 1
		"underline": return 2
		_: return 0


func _get_theme_index(p_theme_name: String) -> int:
	match p_theme_name:
		"dark": return 0
		"light": return 1
		"high_contrast": return 2
		_: return 0


func _get_language_index(language: String) -> int:
	match language:
		"en": return 0
		"es": return 1
		"fr": return 2
		"de": return 3
		_: return 0


# Signal handlers

func _on_cursor_style_changed(_index: int) -> void:
	has_unsaved_changes = true
	_update_button_states()


func _on_theme_changed(_index: int) -> void:
	has_unsaved_changes = true
	_update_button_states()


func _on_font_size_changed(_value: float) -> void:
	has_unsaved_changes = true
	_update_button_states()


func _on_sound_volume_changed(_value: float) -> void:
	has_unsaved_changes = true
	_update_button_states()


func _on_typing_sounds_toggled(_pressed: bool) -> void:
	has_unsaved_changes = true
	_update_button_states()


func _on_language_changed(_index: int) -> void:
	has_unsaved_changes = true
	_update_button_states()


func _on_setting_changed(setting_name: String, _new_value) -> void:
	# Handle external setting changes if needed
	print("External setting changed: %s" % setting_name)


# Input handling

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event = event as InputEventKey
		match key_event.keycode:
			KEY_ESCAPE:
				close_settings()
			KEY_ENTER:
				if has_unsaved_changes:
					save_settings()
			KEY_S:
				if key_event.ctrl_pressed and has_unsaved_changes:
					save_settings()
