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
var character_overlays: Array[ColorRect] = []
var font: Font
var character_width: float = 0.0
var character_height: float = 0.0

# Theme and styling
var correct_color: Color = Color.WHITE
var incorrect_color: Color = Color.RED
var pending_color: Color = Color.GRAY
var background_color: Color = Color.BLACK

# Configuration
var config_service: ConfigService


func _ready() -> void:
	Log.info("[TextDisplay] _ready() called")
	_setup_cursor()
	_setup_timer()
	_connect_signals()
	_apply_initial_styling()
	Log.info("[TextDisplay] _ready() complete")


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
	Log.info("[TextDisplay] Setting up cursor")
	typing_cursor = TypingCursor.new()
	typing_cursor.name = "TypingCursor"
	cursor_container.add_child(typing_cursor)
	typing_cursor.cursor_moved.connect(_on_cursor_moved)
	Log.info("[TextDisplay] Cursor setup complete")


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
		Log.info("[TextDisplay] Applying initial styling to sample_label")
		# Setup plain text label (no BBCode)
		sample_label.add_theme_color_override("font_color", pending_color)
		# Ensure label uses monospace font for alignment
		sample_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		sample_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Remove any text padding/margins that might affect alignment
		sample_label.add_theme_constant_override("line_spacing", 0)

		_setup_character_overlays()
		Log.info("[TextDisplay] Initial styling applied")


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
	Log.info("[TextDisplay] Applying font size: %d" % p_font_size)

	if sample_label:
		# Set font size on the Label
		sample_label.add_theme_font_size_override("font_size", p_font_size)
		Log.info("[TextDisplay] Font size set on Label")

	# Force immediate update and wait for Label to process the font change
	if sample_label:
		await get_tree().process_frame

	# Update cursor font size to match text - ensure EXACT same font
	if typing_cursor and sample_label:
		var text_font = sample_label.get_theme_font("font")
		var text_size = sample_label.get_theme_font_size("font_size")

		# Fallback to default font if needed
		if not text_font:
			text_font = get_theme_default_font()

		Log.info("[TextDisplay] Setting cursor font - Font: %s, Size: %d" % [text_font, text_size])
		typing_cursor.set_font_and_size(text_font, text_size)

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

	# Set plain text once (no flashing)
	sample_label.text = current_text
	_update_character_colors()
	_update_cursor_position()
	_update_progress_bar()

func _setup_character_overlays() -> void:
	Log.info("[TextDisplay] _setup_character_overlays() called")
	Log.info("[TextDisplay] color_overlay_container exists: %s" % (color_overlay_container != null))
	Log.info("[TextDisplay] sample_label exists: %s" % (sample_label != null))

	if not color_overlay_container or not sample_label:
		Log.info("[TextDisplay] Missing components, exiting setup")
		return

	# Get EXACT same font metrics as the label - ensure it's up to date
	font = sample_label.get_theme_font("font")
	var font_size = sample_label.get_theme_font_size("font_size")

	# Verify we got the updated font size
	if font_size <= 0:
		font_size = 16  # Fallback

	Log.info("[TextDisplay] Got font from label: %s" % font)
	Log.info("[TextDisplay] Font size from label: %d" % font_size)

	if not font:
		font = get_theme_default_font()
		Log.info("[TextDisplay] Using default font: %s" % font)

	# Use same character reference as cursor for consistency
	character_width = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	character_height = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).y

	Log.info("[TextDisplay] Final character metrics: width=%f, height=%f (font_size=%d)" % [character_width, character_height, font_size])

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
			# Create red background for incorrect character
			var overlay = ColorRect.new()
			overlay.color = incorrect_color
			overlay.position = Vector2(i * character_width, 0)
			overlay.size = Vector2(character_width, character_height)
			color_overlay_container.add_child(overlay)
			character_overlays.append(overlay)


func _update_cursor_position() -> void:
	if not typing_cursor or not show_cursor:
		return

	if current_index < current_text.length():
		var current_char = current_text[current_index]
		typing_cursor.character = current_char
		Log.info("[TextDisplay][_update_cursor_position] Updated cursor character to: '%s'" % current_char)
	else:
		# At end of text, could show a completion indicator or space
		typing_cursor.character = " "
		Log.info("[TextDisplay][_update_cursor_position] At end of text, cursor shows space")

	# ALIGNMENT DEBUG - Add debug info here since we know this function runs
	Log.info("[TextDisplay][ALIGNMENT_DEBUG] Current index: %d" % current_index)
	Log.info("[TextDisplay][ALIGNMENT_DEBUG] Character width cached: %f" % character_width)
	Log.info("[TextDisplay][ALIGNMENT_DEBUG] Sample label exists: %s" % (sample_label != null))
	Log.info("[TextDisplay][ALIGNMENT_DEBUG] Typing cursor exists: %s" % (typing_cursor != null))
	Log.info("[TextDisplay][ALIGNMENT_DEBUG] Cursor size: %s" % typing_cursor.size)

	# Calculate cursor position by measuring actual text width up to current position
	var cursor_x = _calculate_accurate_cursor_position()
	Log.info("[TextDisplay][ALIGNMENT_DEBUG] Calculated cursor_x: %f" % cursor_x)

	# Get Label's text rendering position to match exactly
	var label_offset = Vector2.ZERO
	if sample_label:
		# Account for Label's internal text positioning
		var font_metrics = sample_label.get_theme_font("font")
		Log.info("[TextDisplay][ALIGNMENT_DEBUG] Label font: %s" % font_metrics)
		if font_metrics:
			# Add slight vertical offset to align baselines
			label_offset.y = 0  # Keep at top for now
			label_offset.x = 0  # No horizontal offset needed for left-aligned text

	# Ensure cursor position is valid and aligned with Label
	if cursor_x >= 0:
		typing_cursor.position = Vector2(cursor_x + label_offset.x, label_offset.y)
		cursor_moved.emit()
		Log.info("[TextDisplay] Cursor positioned at: %s (offset: %s)" % [typing_cursor.position, label_offset])


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
	if not sample_label or current_index <= 0:
		return 0.0

	# Ensure we have up-to-date character width
	if character_width <= 0:
		_setup_character_overlays()

	# Use exact same calculation as cursor internally uses
	if character_width > 0:
		var cursor_position = current_index * character_width
		Log.info("[TextDisplay][_calculate_accurate_cursor_position] Position: index %d * width %f = %f" % [current_index, character_width, cursor_position])
		return cursor_position

	# Fallback calculation
	var char_size = _estimate_character_size()
	return current_index * char_size.x


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
