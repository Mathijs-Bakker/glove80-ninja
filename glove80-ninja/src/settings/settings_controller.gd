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
	Log.info("[SettingsController][_ready] Settings controller ready")
	_setup_ui()


## Initialize the settings controller with config service
func initialize(p_config_service: ConfigService) -> void:
	Log.info("[SettingsController][initialize] Initializing settings controller")
	config_service = p_config_service
	if config_service:
		config_service.setting_changed.connect(_on_setting_changed)
		Log.info("[SettingsController][initialize] Connected to config service signals")
	else:
		Log.error("[SettingsController][initialize] Config service is null")
	_load_current_settings()
	Log.info("[SettingsController][initialize] Settings controller initialized successfully")


## Load current settings from config service
func _load_current_settings() -> void:
	Log.info("[SettingsController][_load_current_settings] Loading current settings")
	if not config_service:
		Log.error("[SettingsController][_load_current_settings] Config service is null")
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

	Log.info("[SettingsController][_load_current_settings] Loaded %d settings from config service" % original_settings.size())

	# Apply settings to UI
	_apply_settings_to_ui()
	has_unsaved_changes = false
	_update_button_states()


## Apply current settings to UI controls
func _apply_settings_to_ui() -> void:
	Log.info("[SettingsController][_apply_settings_to_ui] Applying settings to UI controls")

	if cursor_style_option:
		var cursor_style = original_settings.get("cursor_style", "block")
		cursor_style_option.select(_get_cursor_style_index(cursor_style))
		Log.info("[SettingsController][_apply_settings_to_ui] Set cursor style to: %s" % cursor_style)

	if theme_option:
		var theme_name = original_settings.get("theme", "dark")
		theme_option.select(_get_theme_index(theme_name))
		Log.info("[SettingsController][_apply_settings_to_ui] Set theme to: %s" % theme_name)

	if font_size_spinbox:
		var font_size = original_settings.get("font_size", 16)
		font_size_spinbox.value = font_size
		Log.info("[SettingsController][_apply_settings_to_ui] Set font size to: %d" % font_size)

	if sound_volume_slider:
		var sound_volume = original_settings.get("sound_volume", 80)
		sound_volume_slider.value = sound_volume
		Log.info("[SettingsController][_apply_settings_to_ui] Set sound volume to: %d" % sound_volume)

	if typing_sounds_checkbox:
		var typing_sounds = original_settings.get("typing_sounds", true)
		typing_sounds_checkbox.button_pressed = typing_sounds
		Log.info("[SettingsController][_apply_settings_to_ui] Set typing sounds to: %s" % typing_sounds)

	if language_option:
		var language = original_settings.get("language", "en")
		language_option.select(_get_language_index(language))
		Log.info("[SettingsController][_apply_settings_to_ui] Set language to: %s" % language)

	Log.info("[SettingsController][_apply_settings_to_ui] All settings applied to UI successfully")


## Save current settings
func save_settings() -> void:
	Log.info("[SettingsController][save_settings] Saving current settings")
	if not config_service:
		Log.error("[SettingsController][save_settings] Config service is null")
		return

	var settings_saved = 0

	# Apply all UI values to config service
	if cursor_style_option:
		var cursor_styles = ["block", "line", "underline"]
		var selected_style = cursor_styles[cursor_style_option.selected]
		config_service.set_user_setting("cursor_style", selected_style)
		Log.info("[SettingsController][save_settings] Saved cursor style: %s" % selected_style)
		settings_saved += 1

	if theme_option:
		var themes = ["dark", "light", "high_contrast"]
		var selected_theme = themes[theme_option.selected]
		config_service.set_user_setting("theme", selected_theme)
		Log.info("[SettingsController][save_settings] Saved theme: %s" % selected_theme)
		settings_saved += 1

	if font_size_spinbox:
		var font_size = int(font_size_spinbox.value)
		config_service.set_user_setting("font_size", font_size)
		Log.info("[SettingsController][save_settings] Saved font size: %d" % font_size)
		settings_saved += 1

	if sound_volume_slider:
		var sound_volume = int(sound_volume_slider.value)
		config_service.set_user_setting("sound_volume", sound_volume)
		Log.info("[SettingsController][save_settings] Saved sound volume: %d" % sound_volume)
		settings_saved += 1

	if typing_sounds_checkbox:
		var typing_sounds = typing_sounds_checkbox.button_pressed
		config_service.set_user_setting("typing_sounds", typing_sounds)
		Log.info("[SettingsController][save_settings] Saved typing sounds: %s" % typing_sounds)
		settings_saved += 1

	if language_option:
		var languages = ["en", "es", "fr", "de"]
		var selected_language = languages[language_option.selected]
		config_service.set_user_setting("language", selected_language)
		Log.info("[SettingsController][save_settings] Saved language: %s" % selected_language)
		settings_saved += 1

	# Save to file
	var save_success = config_service.save_user_config()
	if save_success:
		Log.info("[SettingsController][save_settings] %d settings saved successfully to disk" % settings_saved)
	else:
		Log.error("[SettingsController][save_settings] Failed to save settings to disk")

	# Update state
	_load_current_settings()  # Refresh original settings


## Cancel changes and revert to original settings
func cancel_changes() -> void:
	Log.info("[SettingsController][cancel_changes] Cancelling settings changes")
	_apply_settings_to_ui()
	has_unsaved_changes = false
	_update_button_states()
	Log.info("[SettingsController][cancel_changes] Settings changes cancelled, UI reverted")


## Reset all settings to defaults
func reset_to_defaults() -> void:
	Log.info("[SettingsController][reset_to_defaults] Resetting all settings to defaults")
	if not config_service:
		Log.error("[SettingsController][reset_to_defaults] Config service is null")
		return

	# Show confirmation dialog
	Log.info("[SettingsController][reset_to_defaults] Showing reset confirmation dialog")
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Are you sure you want to reset all settings to defaults?"
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

	var confirmed = await confirm_dialog.confirmed
	confirm_dialog.queue_free()

	if confirmed:
		Log.info("[SettingsController][reset_to_defaults] Reset confirmed by user")
		config_service.reset_user_config_to_defaults(true)
		_load_current_settings()
		Log.info("[SettingsController][reset_to_defaults] Settings reset to defaults completed")
	else:
		Log.info("[SettingsController][reset_to_defaults] Reset cancelled by user")


## Close the settings panel
func close_settings() -> void:
	Log.info("[SettingsController][close_settings] Closing settings panel")

	if has_unsaved_changes:
		Log.info("[SettingsController][close_settings] Unsaved changes detected, showing confirmation dialog")
		var confirm_dialog = ConfirmationDialog.new()
		confirm_dialog.dialog_text = "You have unsaved changes. Do you want to save before closing?"
		confirm_dialog.add_button("Don't Save", false, "dont_save")
		add_child(confirm_dialog)
		confirm_dialog.popup_centered()

		var result = await confirm_dialog.custom_action
		confirm_dialog.queue_free()

		if result == "":  # OK button (save)
			Log.info("[SettingsController][close_settings] User chose to save before closing")
			save_settings()
		elif result == "dont_save":
			Log.info("[SettingsController][close_settings] User chose not to save changes")
			cancel_changes()
		else:  # Cancel button
			Log.info("[SettingsController][close_settings] User cancelled closing")
			return

	Log.info("[SettingsController][close_settings] Emitting settings_closed signal")
	settings_closed.emit()


# Private methods

func _setup_ui() -> void:
	Log.info("[SettingsController][_setup_ui] Setting up UI controls")

	# Setup cursor style options
	if cursor_style_option:
		cursor_style_option.add_item("Block Cursor")
		cursor_style_option.add_item("Line Cursor")
		cursor_style_option.add_item("Underline Cursor")
		cursor_style_option.item_selected.connect(_on_cursor_style_changed)
		Log.info("[SettingsController][_setup_ui] Cursor style options configured")

	# Setup theme options
	if theme_option:
		theme_option.add_item("Dark Theme")
		theme_option.add_item("Light Theme")
		theme_option.add_item("High Contrast")
		theme_option.item_selected.connect(_on_theme_changed)
		Log.info("[SettingsController][_setup_ui] Theme options configured")

	# Setup font size
	if font_size_spinbox:
		font_size_spinbox.min_value = 12
		font_size_spinbox.max_value = 24
		font_size_spinbox.step = 1
		font_size_spinbox.value_changed.connect(_on_font_size_changed)
		Log.info("[SettingsController][_setup_ui] Font size spinbox configured (12-24)")

	# Setup sound volume
	if sound_volume_slider:
		sound_volume_slider.min_value = 0
		sound_volume_slider.max_value = 100
		sound_volume_slider.step = 1
		sound_volume_slider.value_changed.connect(_on_sound_volume_changed)
		Log.info("[SettingsController][_setup_ui] Sound volume slider configured (0-100)")

	# Setup typing sounds checkbox
	if typing_sounds_checkbox:
		typing_sounds_checkbox.toggled.connect(_on_typing_sounds_toggled)
		Log.info("[SettingsController][_setup_ui] Typing sounds checkbox configured")

	# Setup language options
	if language_option:
		language_option.add_item("English")
		language_option.add_item("Spanish")
		language_option.add_item("French")
		language_option.add_item("German")
		language_option.item_selected.connect(_on_language_changed)
		Log.info("[SettingsController][_setup_ui] Language options configured")

	# Setup buttons
	if save_button:
		save_button.pressed.connect(save_settings)
		Log.info("[SettingsController][_setup_ui] Save button connected")

	if cancel_button:
		cancel_button.pressed.connect(cancel_changes)
		Log.info("[SettingsController][_setup_ui] Cancel button connected")

	if reset_button:
		reset_button.pressed.connect(reset_to_defaults)
		Log.info("[SettingsController][_setup_ui] Reset button connected")

	Log.info("[SettingsController][_setup_ui] UI setup completed successfully")


func _update_button_states() -> void:
	Log.info("[SettingsController][_update_button_states] Updating button states - unsaved changes: %s" % has_unsaved_changes)

	if save_button:
		save_button.disabled = not has_unsaved_changes

	if cancel_button:
		cancel_button.disabled = not has_unsaved_changes


func _get_cursor_style_index(p_style: String) -> int:
	Log.info("[SettingsController][_get_cursor_style_index] Getting index for cursor style: %s" % p_style)
	match p_style:
		"block": return 0
		"line": return 1
		"underline": return 2
		_:
			Log.warn("[SettingsController][_get_cursor_style_index] Unknown cursor style: %s, defaulting to block" % p_style)
			return 0


func _get_theme_index(p_theme_name: String) -> int:
	Log.info("[SettingsController][_get_theme_index] Getting index for theme: %s" % p_theme_name)
	match p_theme_name:
		"dark": return 0
		"light": return 1
		"high_contrast": return 2
		_:
			Log.warn("[SettingsController][_get_theme_index] Unknown theme: %s, defaulting to dark" % p_theme_name)
			return 0


func _get_language_index(p_language: String) -> int:
	Log.info("[SettingsController][_get_language_index] Getting index for language: %s" % p_language)
	match p_language:
		"en": return 0
		"es": return 1
		"fr": return 2
		"de": return 3
		_:
			Log.warn("[SettingsController][_get_language_index] Unknown language: %s, defaulting to English" % p_language)
			return 0


# Signal handlers

func _on_cursor_style_changed(p_index: int) -> void:
	Log.info("[SettingsController][_on_cursor_style_changed] Cursor style changed to index: %d" % p_index)
	has_unsaved_changes = true
	_update_button_states()


func _on_theme_changed(p_index: int) -> void:
	Log.info("[SettingsController][_on_theme_changed] Theme changed to index: %d" % p_index)
	has_unsaved_changes = true
	_update_button_states()


func _on_font_size_changed(p_value: float) -> void:
	Log.info("[SettingsController][_on_font_size_changed] Font size changed to: %.1f" % p_value)
	has_unsaved_changes = true
	_update_button_states()


func _on_sound_volume_changed(p_value: float) -> void:
	Log.info("[SettingsController][_on_sound_volume_changed] Sound volume changed to: %.1f" % p_value)
	has_unsaved_changes = true
	_update_button_states()


func _on_typing_sounds_toggled(p_pressed: bool) -> void:
	Log.info("[SettingsController][_on_typing_sounds_toggled] Typing sounds toggled to: %s" % p_pressed)
	has_unsaved_changes = true
	_update_button_states()


func _on_language_changed(p_index: int) -> void:
	Log.info("[SettingsController][_on_language_changed] Language changed to index: %d" % p_index)
	has_unsaved_changes = true
	_update_button_states()


func _on_setting_changed(p_setting_name: String, p_new_value) -> void:
	Log.info("[SettingsController][_on_setting_changed] External setting changed: %s = %s" % [p_setting_name, p_new_value])
	# Handle external setting changes if needed


# Input handling

func _input(p_event: InputEvent) -> void:
	if p_event is InputEventKey and p_event.pressed:
		var key_event = p_event as InputEventKey
		match key_event.keycode:
			KEY_ESCAPE:
				Log.info("[SettingsController][_input] Escape key pressed, closing settings")
				close_settings()
			KEY_ENTER:
				if has_unsaved_changes:
					Log.info("[SettingsController][_input] Enter key pressed with unsaved changes, saving settings")
					save_settings()
			KEY_S:
				if key_event.ctrl_pressed and has_unsaved_changes:
					Log.info("[SettingsController][_input] Ctrl+S pressed with unsaved changes, saving settings")
					save_settings()
