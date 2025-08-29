class_name TextDisplay
extends Control

## Optimized TextDisplay component that handles text rendering, cursor display, and visual feedback
## Fixed performance issues with character overlays and position calculations


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

# OPTIMIZATION: Character overlay system with pooling (eliminates node creation/destruction)
var overlay_pool: Array[Label] = []
var active_overlays: Dictionary = {}  # position -> overlay
var font: Font
var character_width: float = 0.0
var character_height: float = 0.0

# OPTIMIZATION: Position caching system (eliminates O(n) calculations)
var position_cache: Dictionary = {}  # char_index -> Vector2
var cache_valid: bool = false
var cached_line_breaks: Array[int] = []  # Pre-calculated line break positions
var cached_line_height: float = 0.0

# OPTIMIZATION: Batched updates system (reduces update frequency)
var update_timer: Timer
var pending_updates: bool = false
var stats_update_timer: Timer
var pending_stats_updates: bool = false

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

	# Reset positions and clear overlays
	_reset_container_positions()
	_clear_all_overlays()

	# Invalidate caches
	cache_valid = false

	_update_display()
	text_updated.emit()


## OPTIMIZED: Update display with current typing progress
func update_progress(user_input: String, char_index: int, mistakes: int) -> void:
	current_input = user_input
	current_index = char_index
	mistakes_count = mistakes

	# OPTIMIZATION: Batch updates instead of immediate processing
	if not pending_updates:
		pending_updates = true
		update_timer.start()


## OPTIMIZED: Update statistics display with batching
func update_stats(wpm: float, accuracy: float, mistakes: int) -> void:
	# Store stats for batched update
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
	correct_color = correct
	incorrect_color = incorrect
	pending_color = pending
	background_color = bg
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

	# OPTIMIZATION: Batched update timer (~60fps)
	update_timer = Timer.new()
	update_timer.wait_time = 0.016  # ~60fps
	update_timer.one_shot = true
	update_timer.timeout.connect(_perform_batched_updates)
	add_child(update_timer)

	# OPTIMIZATION: Stats update timer (lower frequency)
	stats_update_timer = Timer.new()
	stats_update_timer.wait_time = 0.1  # 10fps for stats
	stats_update_timer.one_shot = true
	stats_update_timer.timeout.connect(_perform_stats_update)
	add_child(stats_update_timer)


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
		sample_label.add_theme_font_size_override("font_size", p_font_size)

	# Force immediate update and wait for Label to process the font change
	if sample_label:
		await get_tree().process_frame

	await get_tree().process_frame

	# Recalculate character dimensions and invalidate cache
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

	# Invalidate position cache when text changes
	cache_valid = false

	# Force immediate update for initial display
	_perform_batched_updates()


func _setup_character_overlays() -> void:
	if not color_overlay_container or not sample_label:
		return

	# Get font information
	font = null
	var font_size = 16

	# Try to get the font from theme first
	var current_theme = get_theme()
	if current_theme:
		var label_font = current_theme.get_font("font", "Label")
		var label_size = current_theme.get_font_size("font_size", "Label")
		if label_font and label_size > 0:
			font = label_font
			font_size = label_size
		else:
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

	# Calculate character dimensions
	character_width = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	character_height = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).y
	cached_line_height = font.get_height(font_size)

	# Update cursor with the exact same font
	if typing_cursor:
		typing_cursor.set_font_and_size(font, font_size)

	# Invalidate position cache when font changes
	cache_valid = false


# OPTIMIZATION: Batched update system

var _pending_wpm: float = 0.0
var _pending_accuracy: float = 0.0
var _pending_mistakes: int = 0

func _perform_batched_updates() -> void:
	if not cache_valid:
		_rebuild_position_cache()

	_update_character_colors_optimized()
	_update_cursor_position_optimized()
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


# OPTIMIZATION: Position caching system

func _rebuild_position_cache() -> void:
	if not sample_label or not font:
		return

	position_cache.clear()
	cached_line_breaks.clear()

	var font_size = sample_label.get_theme_font_size("font_size")
	var label_width = sample_label.size.x

	if label_width <= 0:
		label_width = 400  # Fallback width

	# Pre-calculate all positions and line breaks
	var current_line = 0
	var current_x = 0.0
	var line_text = ""

	for i in range(current_text.length()):
		var ch = current_text[i]

		# Handle line breaks
		if ch == "\n":
			cached_line_breaks.append(i)
			position_cache[i] = Vector2(current_x, current_line * cached_line_height)
			current_line += 1
			current_x = 0.0
			line_text = ""
			continue

		# Try adding this character to current line
		var test_line = line_text + ch
		var test_width = font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

		# Check if we need to wrap
		if test_width > label_width and line_text.length() > 0:
			# Mark line break and wrap to next line
			if cached_line_breaks.is_empty() or cached_line_breaks[-1] != i - 1:
				cached_line_breaks.append(i - 1)
			current_line += 1
			current_x = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			line_text = ch
		else:
			# Fits on current line
			current_x = test_width
			line_text = test_line

		# Cache this position
		position_cache[i] = Vector2(current_x, current_line * cached_line_height)

	cache_valid = true


# OPTIMIZATION: Improved character overlay system with pooling

func _update_character_colors_optimized() -> void:
	if not color_overlay_container:
		return

	# Only update changed characters instead of recreating everything
	var changes_made = false

	# Check for new errors or corrections
	for i in range(min(current_input.length(), current_text.length())):
		var is_error = current_input[i] != current_text[i]
		var has_overlay = i in active_overlays

		if is_error and not has_overlay:
			# Add error overlay
			_add_error_overlay(i)
			changes_made = true
		elif not is_error and has_overlay:
			# Remove error overlay (character was corrected)
			_remove_error_overlay(i)
			changes_made = true

	# Remove overlays for positions beyond current input
	var positions_to_remove = []
	for pos in active_overlays.keys():
		if pos >= current_input.length():
			positions_to_remove.append(pos)

	for pos in positions_to_remove:
		_remove_error_overlay(pos)
		changes_made = true


func _add_error_overlay(pos: int) -> void:
	if pos in active_overlays or pos >= current_text.length():
		return

	var overlay = _get_overlay_from_pool()
	overlay.text = current_text[pos]
	overlay.add_theme_color_override("font_color", incorrect_color)

	# Use cached position
	if pos in position_cache:
		overlay.position = position_cache[pos]
	else:
		overlay.position = Vector2.ZERO  # Fallback

	overlay.size = Vector2(character_width, character_height)
	overlay.visible = true

	active_overlays[pos] = overlay
	color_overlay_container.add_child(overlay)


func _remove_error_overlay(pos: int) -> void:
	if pos not in active_overlays:
		return

	var overlay = active_overlays[pos]
	active_overlays.erase(pos)

	# Remove from scene and return to pool
	color_overlay_container.remove_child(overlay)
	overlay.visible = false
	overlay_pool.append(overlay)


func _get_overlay_from_pool() -> Label:
	if overlay_pool.size() > 0:
		return overlay_pool.pop_back()
	else:
		return _create_new_overlay()


func _create_new_overlay() -> Label:
	var overlay = Label.new()

	# Apply font settings
	if font:
		overlay.add_theme_font_override("font", font)
		var text_size = sample_label.get_theme_font_size("font_size") if sample_label else 16
		if text_size > 0:
			overlay.add_theme_font_size_override("font_size", text_size)

	# Match main label alignment
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	overlay.add_theme_constant_override("line_spacing", 0)

	return overlay


func _clear_all_overlays() -> void:
	# Return all active overlays to pool
	for overlay in active_overlays.values():
		color_overlay_container.remove_child(overlay)
		overlay.visible = false
		overlay_pool.append(overlay)

	active_overlays.clear()


# OPTIMIZATION: Simplified cursor positioning

func _update_cursor_position_optimized() -> void:
	if not typing_cursor or not show_cursor:
		return

	# Set cursor character
	if current_index < current_text.length():
		typing_cursor.character = current_text[current_index]
	else:
		typing_cursor.character = " "

	# Use cached position
	var cursor_pos = Vector2.ZERO
	if current_index in position_cache:
		cursor_pos = position_cache[current_index]
	elif current_index == current_text.length() and current_index > 0:
		# End of text - position after last character
		var last_pos = position_cache.get(current_index - 1, Vector2.ZERO)
		cursor_pos = Vector2(last_pos.x + character_width, last_pos.y)

	# Update cursor position
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


func _reset_container_positions() -> void:
	# Reset all container positions and ensure visibility
	if sample_label:
		sample_label.position = Vector2.ZERO
		sample_label.visible = true
	if color_overlay_container:
		color_overlay_container.position = Vector2.ZERO
	if cursor_container:
		cursor_container.position = Vector2.ZERO


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
