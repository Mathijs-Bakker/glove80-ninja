class_name TypingSettings
extends Control

@export var stop_cursor_on_error_btn: CheckBox
@export var forgive_errors_btn: CheckBox
@export var space_skips_words_btn: CheckBox

@export var whitespace_btn_group: ButtonGroup
@export var cursor_shape_btn_group: ButtonGroup

var _show_whitespace: String
var _cursor_shape: String
var _settings_changed: bool


func _ready() -> void:
	AppManager.app_initialized.connect(_set_data)


func _set_data() -> void:
	var user_prfl = UserService.get_profile()

	if user_prfl == null:
		Log.Error("[typing][_set_data] Error fetching settings")
	else:
		stop_cursor_on_error_btn.button_pressed = user_prfl.get(User.SETTINGS.STOP_CURSOR_ON_ERROR)
		forgive_errors_btn.button_pressed = user_prfl.get(User.SETTINGS.FORGIVE_ERRORS)
		space_skips_words_btn.button_pressed = user_prfl.get(User.SETTINGS.SPACE_SKIPS_WORDS)

	var settings_value = user_prfl.get(User.SETTINGS.SHOW_WHITESPACE)
	# Show whitespace
	for btn in whitespace_btn_group.get_buttons():
		btn.toggled.connect(_on_whitespace_toggled.bind(btn))
		# Valid string values are: 'show', 'bar', 'bullet'
		if btn.name == settings_value:
			btn.set_pressed_no_signal(true)

	settings_value = user_prfl.get(User.SETTINGS.CURSOR_SHAPE)
	# Cursor Shape
	for btn in cursor_shape_btn_group.get_buttons():
		btn.toggled.connect(_on_cursor_shape_toggled.bind(btn))
		# Valid string values are: 'block', 'box', 'line', 'underline'
		if btn.name == settings_value:
			btn.set_pressed_no_signal(true)


func _on_whitespace_toggled(p_pressed: bool, p_button: BaseButton) -> void:
	if p_pressed:
		Log.info("[Settings/Typing][_on_whitespace_toggled] Set whitespace to %s" % p_button.name)
		_show_whitespace = p_button.name
		_settings_changed = true


func _on_cursor_shape_toggled(p_pressed: bool, p_button: BaseButton) -> void:
	if p_pressed:
		Log.info(
			"[Settings/Typing][_on_cursor_shape_toggled] Set cursor shape to %s" % p_button.name
		)
		_cursor_shape = p_button.name
		_settings_changed = true
