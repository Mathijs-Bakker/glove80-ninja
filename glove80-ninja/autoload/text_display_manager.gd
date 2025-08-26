extends Node

## Handles text display with custom cursor node


@onready var sample_label: RichTextLabel
var cursor: Control
var config_manager: Node
var current_cursor_position: int = 0
var current_text: String = ""


func setup(p_label_node: RichTextLabel, p_config_node: Node) -> void:
	sample_label = p_label_node
	config_manager = p_config_node
	
	# Create new cursor instance
	var cursor_scene = preload("res://src/cursor/cursor.tscn")
	cursor = cursor_scene.instantiate()
	
	# Add cursor to the scene
	sample_label.add_child(cursor)
	cursor.visible = false
	print("TextDisplayManager setup with custom cursor")


func update_display(p_typing_data: Dictionary) -> void:
	if not sample_label:
		return
	
	current_text = p_typing_data.get("current_text", "")
	var user_input: String = p_typing_data.get("user_input", "")
	current_cursor_position = p_typing_data.get("current_index", 0)
	var mistakes: int = p_typing_data.get("mistakes", 0)
	
	# Update text display
	var display_text = generate_display_text(user_input, mistakes)
	sample_label.text = display_text
	
	# Update cursor position and visibility
	update_cursor_position()


func generate_display_text(p_user_input: String, p_mistakes: int) -> String:
	var display_text := ""
	
	for i in range(current_text.length()):
		if i < p_user_input.length():
			if p_user_input[i] == current_text[i]:
				display_text += "[color=green]" + current_text[i] + "[/color]"
			else:
				display_text += "[color=red]" + current_text[i] + "[/color]"
		else:
			display_text += current_text[i]
	
	return display_text


func update_cursor_position() -> void:
	if current_cursor_position >= current_text.length() or not cursor:
		if cursor:
			cursor.visible = false
		return
	
	if current_text.is_empty():
		cursor.visible = false
		return
	
	# Calculate cursor position based on character index
	var cursor_char = current_text[current_cursor_position]
	
	# Set character using direct property access
	if "character" in cursor:
		cursor.character = cursor_char
	
	cursor.visible = true
	
	# Get text measurements - use the same font settings as SampleLabel
	var text_before_cursor = current_text.substr(0, current_cursor_position)
	var font = sample_label.get_theme_default_font()
	var font_size = sample_label.get_theme_font_size("normal_font_size")
	
	# Use get_string_size for accurate measurement
	var text_size = font.get_string_size(text_before_cursor, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Account for RichTextLabel padding and alignment
	var x_position = text_size.x
	var y_position = 0
	
	# Set cursor size based on the SAME font settings as SampleLabel
	var char_size = font.get_string_size(cursor_char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var font_height = font.get_height(font_size)
	
	# Use consistent sizing - match the SampleLabel's font metrics exactly
	cursor.size = Vector2(char_size.x + 8, font_height)
	
	cursor.position = Vector2(x_position, y_position)


func update_cursor_style() -> void:
	if not cursor:
		return
		
	var cursor_style = UserConfigManager.get_setting("cursor_style", "block")
	
	# Set cursor style using direct property access
	if "cursor_style" in cursor:
		cursor.cursor_style = cursor_style


func show_correct_feedback() -> void:
	if cursor and "pulse" in cursor:
		cursor.pulse()


func show_incorrect_feedback() -> void:
	if cursor and "shake" in cursor:
		cursor.shake()


func set_cursor_active(p_active: bool) -> void:
	if cursor and "set_active" in cursor:
		cursor.set_active(p_active)


func update_stats_display(p_stats: Dictionary, p_stats_label: Label) -> void:
	if p_stats_label and p_stats:
		var wpm = p_stats.get("wpm", 0.0)
		var accuracy = p_stats.get("accuracy", 0.0)
		var mistakes = p_stats.get("mistakes", 0)
		
		p_stats_label.text = "WPM: %.1f | Accuracy: %.1f%% | Mistakes: %d" % [wpm, accuracy, mistakes]


# Apply theme settings to the display
func apply_theme_settings() -> void:
	if not sample_label:
		return
	
	var theme = UserConfigManager.get_setting("theme", "dark")
	var font_size = UserConfigManager.get_setting("font_size", 24)
	
	match theme:
		"dark":
			sample_label.add_theme_color_override("default_color", Color.WHITE)
		"light":
			sample_label.add_theme_color_override("default_color", Color.BLACK)
		"high_contrast":
			sample_label.add_theme_color_override("default_color", Color.YELLOW)
	
	sample_label.add_theme_font_size_override("normal_font_size", font_size)
	
	# Also update cursor with the same font size if it supports it
	if cursor and "set_font_size" in cursor:
		cursor.set_font_size(font_size)
	
	update_cursor_style()
