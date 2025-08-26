class_name TextDisplay
extends Control

## TextDisplay component that handles text rendering, cursor display, and visual feedback
## Replaces the TextDisplayManager autoload with a proper UI component


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
		sample_label.fit_content = true
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
	var theme = config_service.get_setting("theme", "dark")
	_apply_theme_colors(theme)


func _apply_font_size(size: int) -> void:
	if sample_label:
		sample_label.add_theme_font_size_override("normal_font_size", size)

	var labels = [wpm_label, accuracy_label, mistakes_label]
	for label in labels:
		if label:
			label.add_theme_font_size_override("font_size", max(12, size - 4))


func _apply_theme_colors(theme: String) -> void:
	match theme:
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
		var char = current_text[i]

		if i < current_input.length():
			# Character has been typed
			if current_input[i] == char:
				# Correct character
				result += "[color=%s]%s[/color]" % [correct_color.to_html(), char]
			else:
				# Incorrect character
				result += "[color=%s][bgcolor=%s]%s[/bgcolor][/color]" % [
					Color.WHITE.to_html(),
					incorrect_color.to_html(),
					char
				]
		elif i == current_index:
			# Current character to be typed
			result += "[bgcolor=%s]%s[/bgcolor]" % [pending_color.to_html(), char]
		else:
			# Not yet typed
			result += "[color=%s]%s[/color]" % [pending_color.to_html(), char]

	return result


func _update_cursor_position() -> void:
	if not typing_cursor or not show_cursor:
		return

	# Calculate cursor position based on current character index
	var char_size = _estimate_character_size()
	var cursor_x = current_index * char_size.x

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

	if font:
		return Vector2(font.get_char_size(ord("M"), font_size).x, font.get_height(font_size))
	else:
		return Vector2(10, 20)


func _flash_background(color: Color, duration: float) -> void:
	var original_modulate = modulate
	modulate = color

	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, duration)


func _on_cursor_moved() -> void:
	cursor_moved.emit()


func _on_cursor_blink() -> void:
	if typing_cursor and show_cursor:
		typing_cursor.blink()


func _on_config_changed(setting_name: String, _new_value) -> void:
	match setting_name:
		"cursor_style":
			if typing_cursor:
				typing_cursor.set_style(config_service.get_setting("cursor_style", "block"))
		"font_size":
			_apply_font_size(config_service.get_setting("font_size", 16))
		"theme":
			_apply_theme_colors(config_service.get_setting("theme", "dark"))
