class_name TextDisplay
extends Control

## TextDisplay component that handles text rendering, cursor display, and visual feedback


signal text_updated()
signal cursor_moved()

@export var show_cursor: bool = true
@export var cursor_blink_speed: float = 1.0
@export var highlight_errors: bool = true
@export var show_progress: bool = true

# UI components
@onready var sample_label: RichTextLabel = $VBoxContainer/SampleContainer/SampleLabel
@onready var cursor_container: Control = $VBoxContainer/SampleContainer/CursorContainer
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var stats_container: HBoxContainer = $VBoxContainer/StatsContainer
@onready var wpm_label: Label = $VBoxContainer/StatsContainer/WPMLabel
@onready var accuracy_label: Label = $VBoxContainer/StatsContainer/AccuracyLabel
@onready var mistakes_label: Label = $VBoxContainer/StatsContainer/MistakesLabel

# Cursor component
var typing_cursor: TypingCursor
var cursor_timer: Timer

# Display state
var current_text: String = ""
var current_input: String = ""
var current_index: int = 0
var mistakes_count: int = 0

# Theme and styling
var correct_color: Color = Color.WHITE
var incorrect_color: Color = Color.RED
var pending_color: Color = Color.GRAY
var background_color: Color = Color.BLACK

# Configuration
var config_service: ConfigService


func _ready() -> void:
	_setup_cursor()
	_setup_timer()
	_connect_signals()
	_apply_initial_styling()


## Initialize the display with text content
func initialize(text: String, config: ConfigService = null) -> void:
	config_service = config
	set_text(text)
	if config_service:
		_apply_config_settings()


## Set the text to be displayed
func set_text(text: String) -> void:
	current_text = text
	current_input = ""
	current_index = 0
	mistakes_count = 0
	_update_display()
	text_updated.emit()


## Update display with current typing progress
func update_progress(user_input: String, char_index: int, mistakes: int) -> void:
	current_input = user_input
	current_index = char_index
	mistakes_count = mistakes
	_update_display()


## Update statistics display
func update_stats(wpm: float, accuracy: float, mistakes: int) -> void:
	if wpm_label:
		wpm_label.text = "WPM: %.0f" % wpm

	if accuracy_label:
		accuracy_label.text = "Accuracy: %.1f%%" % accuracy

	if mistakes_label:
		mistakes_label.text = "Mistakes: %d" % mistakes


## Show visual feedback for correct typing
func show_correct_feedback() -> void:
	_flash_background(Color.GREEN.lerp(background_color, 0.7), 0.1)


## Show visual feedback for incorrect typing
func show_incorrect_feedback() -> void:
	_flash_background(Color.RED.lerp(background_color, 0.7), 0.2)


## Set cursor visibility
func set_cursor_active(active: bool) -> void:
	show_cursor = active
	if typing_cursor:
		typing_cursor.set_active(active)


## Apply theme settings from configuration
func apply_theme_settings() -> void:
	if config_service:
		_apply_config_settings()


## Set custom colors for text display
func set_colors(correct: Color, incorrect: Color, pending: Color, bg: Color) -> void:
	correct_color = correct
	incorrect_color = incorrect
	pending_color = pending
	background_color = bg
	_update_display()


# Private methods

func _setup_cursor() -> void:
	typing_cursor = TypingCursor.new()
	typing_cursor.name = "TypingCursor"
	cursor_container.add_child(typing_cursor)
	typing_cursor.cursor_moved.connect(_on_cursor_moved)


func _setup_timer() -> void:
	cursor_timer = Timer.new()
	cursor_timer.wait_time = 1.0 / cursor_blink_speed
	cursor_timer.autostart = true
	cursor_timer.timeout.connect(_on_cursor_blink)
	add_child(cursor_timer)


func _connect_signals() -> void:
	if config_service:
		config_service.setting_changed.connect(_on_config_changed)


func _apply_initial_styling() -> void:
	# Set up default styling
	if sample_label:
		# Handle potential compatibility issues with properties
		if sample_label.has_method("set_fit_content"):
			sample_label.fit_content = true
		if sample_label.has_method("set_scroll_active"):
			sample_label.scroll_active = false
		sample_label.bbcode_enabled = true
		sample_label.add_theme_color_override("default_color", correct_color)


func _apply_config_settings() -> void:
	if not config_service:
		return

	# Apply cursor style
	var cursor_style = config_service.get_setting("cursor_style", "block")
	if typing_cursor:
		typing_cursor.set_style(cursor_style)

	# Apply font size
	var font_size = config_service.get_setting("font_size", 16)
	_apply_font_size(font_size)

	# Apply theme colors
	var current_theme = config_service.get_setting("theme", "dark")
	_apply_theme_colors(current_theme)


func _apply_font_size(p_font_size: int) -> void:
	if sample_label:
		sample_label.add_theme_font_size_override("normal_font_size", p_font_size)

	# Update cursor with EXACT same font and size as text
	if typing_cursor and sample_label:
		var text_font = sample_label.get_theme_font("normal_font")
		var text_size = sample_label.get_theme_font_size("normal_font_size")
		typing_cursor.set_font_and_size(text_font, text_size)

	# Update stats labels with smaller font
	for label in [wpm_label, accuracy_label, mistakes_label]:
		if label:
			label.add_theme_font_size_override("font_size", max(12, p_font_size - 4))


func _apply_theme_colors(theme_name: String) -> void:
	match theme_name:
		"dark":
			correct_color = Color.WHITE
			incorrect_color = Color.RED
			pending_color = Color.GRAY
			background_color = Color.BLACK
		"light":
			correct_color = Color.BLACK
			incorrect_color = Color.RED
			pending_color = Color.DARK_GRAY
			background_color = Color.WHITE
		"high_contrast":
			correct_color = Color.WHITE
			incorrect_color = Color.YELLOW
			pending_color = Color.LIGHT_GRAY
			background_color = Color.BLACK

	_update_display_colors()


func _update_display() -> void:
	if not sample_label:
		return

	var display_text = _build_rich_text()
	sample_label.text = display_text

	_update_cursor_position()
	_update_progress_bar()


func _build_rich_text() -> String:
	if current_text.is_empty():
		return ""

	var result = ""

	# Process each character in the text
	for i in range(current_text.length()):
		var character = current_text[i]

		if i < current_input.length():
			# Character has been typed
			if current_input[i] == character:
				# Correct character
				result += "[color=%s]%s[/color]" % [correct_color.to_html(), character]
			else:
				# Incorrect character
				result += "[color=%s][bgcolor=%s]%s[/bgcolor][/color]" % [
					Color.WHITE.to_html(),
					incorrect_color.to_html(),
					character
				]
		elif i == current_index:
			# Current character to be typed
			result += "[bgcolor=%s]%s[/bgcolor]" % [pending_color.to_html(), character]
		else:
			# Not yet typed
			result += "[color=%s]%s[/color]" % [pending_color.to_html(), character]

	return result


func _update_cursor_position() -> void:
	if not typing_cursor or not show_cursor:
		return
		# Update cursor character to show current character that needs to be typed

	if current_index < current_text.length():
		var current_char = current_text[current_index]
		typing_cursor.character = current_char
		Log.info("[TextDisplay][_update_cursor_position] Updated cursor character to: '%s'" % current_char)
	else:
		# At end of text, could show a completion indicator or space
		typing_cursor.character = " "
		Log.info("[TextDisplay][_update_cursor_position] At end of text, cursor shows space")

	# Calculate cursor position by measuring actual text width up to current position
	var cursor_x = _calculate_accurate_cursor_position()

	# Ensure cursor position is valid
	if cursor_x >= 0:
		typing_cursor.position = Vector2(cursor_x, 0)
		cursor_moved.emit()


func _update_progress_bar() -> void:
	if not progress_bar or not show_progress:
		return

	if current_text.length() > 0:
		var progress = float(current_index) / float(current_text.length()) * 100.0
		progress_bar.value = progress


func _update_display_colors() -> void:
	if sample_label:
		sample_label.add_theme_color_override("default_color", correct_color)

	modulate = Color.WHITE
	_update_display()


func _estimate_character_size() -> Vector2:
	if not sample_label:
		return Vector2(10, 20)  # Default fallback

	# Get font metrics for character size estimation
	var font = sample_label.get_theme_font("normal_font")
	var font_size = sample_label.get_theme_font_size("normal_font_size")

	if font and font_size > 0:
		# Use get_string_size for Godot 4 compatibility
		var char_size = font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		# Ensure we have valid dimensions
		if char_size.x > 0 and char_size.y > 0:
			return char_size
		else:
			# Fallback calculation based on font size
			return Vector2(font_size * 0.6, font_size * 1.2)
	else:
		return Vector2(10, 20)


func _calculate_accurate_cursor_position() -> float:
	if not sample_label or current_index <= 0:
		return 0.0

	# Get the font used by the sample label
	var font = sample_label.get_theme_font("normal_font")
	var font_size = sample_label.get_theme_font_size("normal_font_size")

	if not font:
		# Fallback to estimated position
		var char_size = _estimate_character_size()
		return current_index * char_size.x

	# For monospace fonts, calculate position using consistent character width
	# Use 'A' as reference character for consistent spacing (matches cursor sizing)
	# Professional typing app approach: fixed monospace positioning
	var monospace_width = font.get_string_size("A", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var cursor_position = current_index * monospace_width

	Log.info("[TextDisplay][_calculate_accurate_cursor_position] Terminal-style position: index %d * width %f = %f" % [current_index, monospace_width, cursor_position])

	return cursor_position


func _flash_background(color: Color, duration: float) -> void:
	var original_modulate = modulate
	modulate = color

	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, duration)


func _on_cursor_moved() -> void:
	cursor_moved.emit()


func _on_cursor_blink() -> void:
	if typing_cursor and show_cursor:
		# TypingCursor handles blinking automatically through its _process method
		pass


func _on_config_changed(setting_name: String, _new_value) -> void:
	match setting_name:
		"cursor_style":
			if typing_cursor:
				typing_cursor.set_style(config_service.get_setting("cursor_style", "block"))
		"font_size":
			_apply_font_size(config_service.get_setting("font_size", 16))
		"theme":
			_apply_theme_colors(config_service.get_setting("theme", "dark"))
