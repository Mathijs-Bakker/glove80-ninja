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
@onready var sample_label: Label = $VBoxContainer/SampleContainer/SampleLabel
@onready var color_overlay_container: Control = $VBoxContainer/SampleContainer/ColorOverlayContainer
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

# Character overlay system for colors (eliminates flashing)
var character_overlays: Array[Label] = []
var font: Font
var character_width: float = 0.0
var character_height: float = 0.0

# Horizontal scrolling variables
var scroll_offset: float = 0.0
var visible_width: float = 0.0

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

	# Reset any positioning
	_reset_container_positions()

	_update_display()
	text_updated.emit()


## Update display with current typing progress
func update_progress(user_input: String, char_index: int, mistakes: int) -> void:
	current_input = user_input
	current_index = char_index
	mistakes_count = mistakes

	# No special handling needed for wrapped text

	# Update colors instantly without flashing
	_update_character_colors()
	_update_cursor_position()
	_update_progress_bar()


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
	if sample_label:
		# Setup plain text label with explicit white text
		sample_label.add_theme_color_override("font_color", Color.WHITE)
		sample_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		sample_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		sample_label.add_theme_constant_override("line_spacing", 0)
		sample_label.visible = true
		sample_label.modulate = Color.WHITE

		_setup_character_overlays()


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
		# Set font size on the Label
		sample_label.add_theme_font_size_override("font_size", p_font_size)

	# Force immediate update and wait for Label to process the font change
	if sample_label:
		await get_tree().process_frame

	# Font will be synchronized in _setup_character_overlays
	# This ensures both cursor and text use the exact same font reference

	# Wait another frame to ensure cursor is updated
	await get_tree().process_frame

	# Recalculate character dimensions for overlays
	_setup_character_overlays()

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

	# Set text and ensure visibility
	sample_label.text = current_text
	sample_label.add_theme_color_override("font_color", Color.WHITE)
	sample_label.visible = true

	if sample_label.text.is_empty():
		sample_label.text = "Sample text will appear here..."

	_update_character_colors()
	_update_cursor_position()
	_update_progress_bar()

func _setup_character_overlays() -> void:
	if not color_overlay_container or not sample_label:
		return

	# Ensure we have the monospace font from theme
	font = null
	var font_size = 16

	# Try to get the font from theme first - prioritize Label font since we added it
	var current_theme = get_theme()
	if current_theme:
		# First try to get Label font we added to theme
		var label_font = current_theme.get_font("font", "Label")
		var label_size = current_theme.get_font_size("font_size", "Label")
		if label_font and label_size > 0:
			font = label_font
			font_size = label_size
		else:
			# Fallback to RichTextLabel monospace font
			var mono_font = current_theme.get_font("mono_font", "RichTextLabel")
			if mono_font:
				font = mono_font
				font_size = current_theme.get_font_size("mono_font_size", "RichTextLabel")

	# If no theme font, get from label
	if not font:
		font = sample_label.get_theme_font("font")
		font_size = sample_label.get_theme_font_size("font_size")

	# Apply the font to the label to ensure consistency
	if font:
		sample_label.add_theme_font_override("font", font)
		sample_label.add_theme_font_size_override("font_size", font_size)

	# Final fallback
	if not font:
		font = get_theme_default_font()
		font_size = 16

	# Always ensure text is white and visible
	sample_label.add_theme_color_override("font_color", Color.WHITE)

	# Use same character reference as cursor for consistency
	character_width = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	character_height = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).y


	# Update cursor with the exact same font
	if typing_cursor:
		typing_cursor.set_font_and_size(font, font_size)

	# No additional setup needed for wrapped text

func _update_character_colors() -> void:
	if not color_overlay_container:
		return

	# Clear existing overlays
	for overlay in character_overlays:
		overlay.queue_free()
	character_overlays.clear()

	# Create overlays for typed characters
	for i in range(min(current_input.length(), current_text.length())):
		if current_input[i] != current_text[i]:
			# Create red character label for incorrect character
			var overlay = Label.new()
			overlay.text = current_text[i]  # Show the expected character
			overlay.add_theme_color_override("font_color", incorrect_color)

			# Calculate position for wrapped text
			var char_pos = _calculate_character_position_wrapped(i)
			overlay.position = Vector2(char_pos.x, char_pos.y)  # Remove the offset, let it align naturally
			overlay.size = Vector2(character_width, character_height)

			# Use the same cached font as the main text and cursor
			if font:
				overlay.add_theme_font_override("font", font)
				var text_size = sample_label.get_theme_font_size("font_size") if sample_label else 16
				if text_size > 0:
					overlay.add_theme_font_size_override("font_size", text_size)

			# Match main label alignment
			overlay.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			overlay.add_theme_constant_override("line_spacing", 0)

			color_overlay_container.add_child(overlay)
			character_overlays.append(overlay)


func _update_cursor_position() -> void:
	if not typing_cursor or not show_cursor:
		return

	if current_index < current_text.length():
		var current_char = current_text[current_index]
		typing_cursor.character = current_char
	else:
		# At end of text, could show a completion indicator or space
		typing_cursor.character = " "

	# Calculate cursor position for wrapped text (both X and Y)
	var cursor_pos = _calculate_wrapped_cursor_position()

	# Update horizontal scrolling to keep cursor visible
	_update_horizontal_scroll(cursor_pos.x)

	# Position cursor at the calculated wrapped position
	if typing_cursor:
		typing_cursor.position = cursor_pos
		cursor_moved.emit()


func _update_progress_bar() -> void:
	if not progress_bar or not show_progress:
		return

	if current_text.length() > 0:
		var progress = float(current_index) / float(current_text.length()) * 100.0
		progress_bar.value = progress


func _update_display_colors() -> void:
	if sample_label:
		sample_label.add_theme_color_override("font_color", pending_color)

	modulate = Color.WHITE
	_update_display()


func _estimate_character_size() -> Vector2:
	if not sample_label:
		return Vector2(10, 20)  # Default fallback

	# Get font metrics for character size estimation
	var label_font = sample_label.get_theme_font("font")
	var font_size = sample_label.get_theme_font_size("font_size")

	if label_font and font_size > 0:
		# Use get_string_size for Godot 4 compatibility
		var char_size = label_font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		# Ensure we have valid dimensions
		if char_size.x > 0 and char_size.y > 0:
			return char_size
		else:
			# Fallback calculation based on font size
			return Vector2(font_size * 0.6, font_size * 1.2)
	else:
		return Vector2(10, 20)


func _calculate_accurate_cursor_position() -> float:
	if current_index <= 0:
		return 0.0

	# For wrapped text, we need to calculate which line we're on
	if not sample_label or not font:
		return 0.0

	var cursor_pos = _calculate_wrapped_cursor_position()
	return cursor_pos.x


func _update_horizontal_scroll(_cursor_x: float) -> void:
	# No scrolling needed with text wrapping
	pass


func _reset_container_positions() -> void:
	# Reset all container positions and ensure visibility
	if sample_label:
		sample_label.position = Vector2.ZERO
		sample_label.visible = true
	if color_overlay_container:
		color_overlay_container.position = Vector2.ZERO
	if cursor_container:
		cursor_container.position = Vector2.ZERO


func _initialize_scrolling() -> void:
	# No scrolling initialization needed with text wrapping
	pass


func _calculate_wrapped_cursor_position() -> Vector2:
	# Use the exact same logic as character positioning since that works correctly
	return _calculate_character_position_wrapped(current_index)


func _calculate_character_position_wrapped(char_index: int) -> Vector2:
	if not sample_label or not font or char_index < 0:
		return Vector2.ZERO

	var font_size = sample_label.get_theme_font_size("font_size")
	var line_height = font.get_height(font_size)
	var label_width = sample_label.size.x

	# Ensure we have a valid width for wrapping calculations
	if label_width <= 0:
		label_width = 400  # Fallback width

	# Get text up to character position
	var text_before = current_text.substr(0, char_index)

	# Simulate text wrapping to find exact position
	var current_line = 0
	var current_x = 0.0
	var line_text = ""

	for i in range(text_before.length()):
		var ch = text_before[i]

		# Handle line breaks
		if ch == "\n":
			current_line += 1
			current_x = 0.0
			line_text = ""
			continue

		# Try adding this character to current line
		var test_line = line_text + ch
		var test_width = font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

		# Check if we need to wrap
		if test_width > label_width and line_text.length() > 0:
			# Wrap to next line
			current_line += 1
			current_x = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			line_text = ch
		else:
			# Fits on current line
			current_x = test_width
			line_text = test_line

	return Vector2(current_x, current_line * line_height)


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
