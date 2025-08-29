class_name RichTextDisplay
extends Control

## Alternative high-performance TextDisplay using RichTextLabel with BBCode
## This approach eliminates the need for character overlays entirely

signal text_updated()
signal cursor_moved()

@export var show_cursor: bool = true
@export var cursor_blink_speed: float = 1.0
@export var highlight_errors: bool = true
@export var show_progress: bool = true

# UI components
@onready var rich_text_label: RichTextLabel = $VBoxContainer/SampleContainer/RichTextLabel
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

# Performance optimizations
var update_timer: Timer
var pending_updates: bool = false
var stats_update_timer: Timer
var pending_stats_updates: bool = false

# Cached BBCode strings for performance
var cached_bbcode: String = ""
var last_input_length: int = 0
var last_cursor_pos: int = 0

# Theme and styling
var correct_color: String = "white"
var incorrect_color: String = "red"
var pending_color: String = "gray"
var background_color: Color = Color.BLACK

# Configuration
var config_service: ConfigService

# Stats caching
var _pending_wpm: float = 0.0
var _pending_accuracy: float = 0.0
var _pending_mistakes: int = 0


func _ready() -> void:
	_setup_cursor()
	_setup_timers()
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

	# Reset cached values
	cached_bbcode = ""
	last_input_length = 0
	last_cursor_pos = 0

	_update_display()
	text_updated.emit()


## Update display with current typing progress (optimized)
func update_progress(user_input: String, char_index: int, mistakes: int) -> void:
	current_input = user_input
	current_index = char_index
	mistakes_count = mistakes

	# Batch updates for performance
	if not pending_updates:
		pending_updates = true
		update_timer.start()


## Update statistics display with batching
func update_stats(wpm: float, accuracy: float, mistakes: int) -> void:
	_pending_wpm = wpm
	_pending_accuracy = accuracy
	_pending_mistakes = mistakes

	if not pending_stats_updates:
		pending_stats_updates = true
		stats_update_timer.start()


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
	correct_color = _color_to_bbcode(correct)
	incorrect_color = _color_to_bbcode(incorrect)
	pending_color = _color_to_bbcode(pending)
	background_color = bg

	# Force display update
	cached_bbcode = ""
	_update_display()


# Private methods - Setup

func _setup_cursor() -> void:
	typing_cursor = TypingCursor.new()
	typing_cursor.name = "TypingCursor"
	cursor_container.add_child(typing_cursor)
	typing_cursor.cursor_moved.connect(_on_cursor_moved)


func _setup_timers() -> void:
	# Cursor blink timer
	cursor_timer = Timer.new()
	cursor_timer.wait_time = 1.0 / cursor_blink_speed
	cursor_timer.autostart = true
	cursor_timer.timeout.connect(_on_cursor_blink)
	add_child(cursor_timer)

	# Batched update timer (~60fps)
	update_timer = Timer.new()
	update_timer.wait_time = 0.016
	update_timer.one_shot = true
	update_timer.timeout.connect(_perform_batched_updates)
	add_child(update_timer)

	# Stats update timer (lower frequency)
	stats_update_timer = Timer.new()
	stats_update_timer.wait_time = 0.1
	stats_update_timer.one_shot = true
	stats_update_timer.timeout.connect(_perform_stats_update)
	add_child(stats_update_timer)


func _connect_signals() -> void:
	if config_service:
		config_service.setting_changed.connect(_on_config_changed)


func _apply_initial_styling() -> void:
	if rich_text_label:
		rich_text_label.bbcode_enabled = true
		rich_text_label.fit_content = false
		rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rich_text_label.visible = true


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
	if rich_text_label:
		rich_text_label.add_theme_font_size_override("normal_font_size", p_font_size)
		rich_text_label.add_theme_font_size_override("mono_font_size", p_font_size)

	# Update cursor font
	if typing_cursor:
		var font = rich_text_label.get_theme_font("mono_font") if rich_text_label else null
		if font:
			typing_cursor.set_font_and_size(font, p_font_size)

	# Update stats labels
	for label in [wpm_label, accuracy_label, mistakes_label]:
		if label:
			label.add_theme_font_size_override("font_size", max(12, p_font_size - 4))

	# Force text update since font size affects layout
	cached_bbcode = ""
	await get_tree().process_frame
	_update_display()


func _apply_theme_colors(theme_name: String) -> void:
	match theme_name:
		"dark":
			correct_color = "white"
			incorrect_color = "red"
			pending_color = "gray"
			background_color = Color.BLACK
		"light":
			correct_color = "black"
			incorrect_color = "red"
			pending_color = "dark_gray"
			background_color = Color.WHITE
		"high_contrast":
			correct_color = "white"
			incorrect_color = "yellow"
			pending_color = "light_gray"
			background_color = Color.BLACK

	# Force display update
	cached_bbcode = ""
	_update_display()


func _update_display() -> void:
	if not rich_text_label:
		return

	if current_text.is_empty():
		rich_text_label.text = "[color=gray]Sample text will appear here...[/color]"
		return

	# Force immediate update for initial display
	_perform_batched_updates()


# Performance optimized update system

func _perform_batched_updates() -> void:
	_update_text_with_colors_optimized()
	_update_cursor_position()
	_update_progress_bar()
	pending_updates = false


func _perform_stats_update() -> void:
	if wpm_label:
		wpm_label.text = "WPM: %.0f" % _pending_wpm
	if accuracy_label:
		accuracy_label.text = "Accuracy: %.1f%%" % _pending_accuracy
	if mistakes_label:
		mistakes_label.text = "Mistakes: %d" % _pending_mistakes

	pending_stats_updates = false


func _update_text_with_colors_optimized() -> void:
	if not rich_text_label:
		return

	# Only rebuild BBCode if something actually changed
	if (_needs_bbcode_update()):
		_rebuild_bbcode()
		rich_text_label.text = cached_bbcode

		# Update cache tracking
		last_input_length = current_input.length()
		last_cursor_pos = current_index


func _needs_bbcode_update() -> bool:
	# Check if we need to update the BBCode text
	return (
		cached_bbcode.is_empty() or
		current_input.length() != last_input_length or
		current_index != last_cursor_pos
	)


func _rebuild_bbcode() -> void:
	var bbcode_parts: Array[String] = []

	# Process each character with appropriate coloring
	for i in range(current_text.length()):
		var char = current_text[i]

		# Escape BBCode special characters
		char = _escape_bbcode_char(char)

		if i < current_input.length():
			# Character has been typed
			if current_input[i] == current_text[i]:
				# Correct character
				bbcode_parts.append("[color=%s]%s[/color]" % [correct_color, char])
			else:
				# Incorrect character
				bbcode_parts.append("[color=%s]%s[/color]" % [incorrect_color, char])
		else:
			# Character not yet typed
			bbcode_parts.append("[color=%s]%s[/color]" % [pending_color, char])

	cached_bbcode = "".join(bbcode_parts)


func _escape_bbcode_char(char: String) -> String:
	# Escape special BBCode characters
	match char:
		"[":
			return "\\["
		"]":
			return "\\]"
		"\n":
			return "\n"  # Preserve newlines
		"\t":
			return "    "  # Convert tabs to spaces for consistent display
		_:
			return char


func _update_cursor_position() -> void:
	if not typing_cursor or not show_cursor or not rich_text_label:
		return

	# Set cursor character
	if current_index < current_text.length():
		typing_cursor.character = current_text[current_index]
	else:
		typing_cursor.character = " "

	# Get cursor position from RichTextLabel
	# Note: This is approximate since RichTextLabel doesn't provide exact character positions
	var font = rich_text_label.get_theme_font("mono_font")
	var font_size = rich_text_label.get_theme_font_size("mono_font_size")

	if font and font_size > 0:
		# Estimate position based on character count and line breaks
		var cursor_pos = _estimate_cursor_position(font, font_size)
		typing_cursor.position = cursor_pos
		cursor_moved.emit()


func _estimate_cursor_position(font: Font, font_size: int) -> Vector2:
	if current_index <= 0:
		return Vector2.ZERO

	# Get text up to cursor position
	var text_before_cursor = current_text.substr(0, current_index)
	var lines = text_before_cursor.split("\n")

	var line_height = font.get_height(font_size)
	var y_pos = (lines.size() - 1) * line_height

	# Estimate x position based on last line length
	var last_line = lines[-1] if lines.size() > 0 else ""
	var x_pos = font.get_string_size(last_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	return Vector2(x_pos, y_pos)


func _update_progress_bar() -> void:
	if not progress_bar or not show_progress:
		return

	if current_text.length() > 0:
		var progress = float(current_index) / float(current_text.length()) * 100.0
		progress_bar.value = progress


# Utility methods

func _color_to_bbcode(color: Color) -> String:
	# Convert Color to BBCode color name or hex
	if color == Color.WHITE:
		return "white"
	elif color == Color.RED:
		return "red"
	elif color == Color.GRAY:
		return "gray"
	elif color == Color.BLACK:
		return "black"
	elif color == Color.YELLOW:
		return "yellow"
	else:
		# Convert to hex for custom colors
		return "#%02x%02x%02x" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]


func _flash_background(color: Color, duration: float) -> void:
	var original_modulate = modulate
	modulate = color

	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, duration)


# Signal handlers

func _on_cursor_moved() -> void:
	cursor_moved.emit()


func _on_cursor_blink() -> void:
	if typing_cursor and show_cursor:
		# TypingCursor handles blinking automatically
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
