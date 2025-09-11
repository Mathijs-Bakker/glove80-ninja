class_name TypingCursor
extends Control

## Ultra-simple cursor for testing - always draws a blue block

signal cursor_moved

@export var _typing_ctrl: TypingController
@export var _text_renderer: TextRenderer

@export var character: String = "A":
	set(value):
		character = value
		if is_inside_tree() and font:
			_update_cursor_size()
		queue_redraw()

@export var cursor_style: String = "block":
	set(value):
		cursor_style = value
		queue_redraw()

@export var is_active: bool = true:
	set(value):
		is_active = value
		queue_redraw()

@export var font_size: int = 16:
	set(value):
		font_size = value
		if is_inside_tree() and font:
			_update_cursor_size()
		queue_redraw()

var font: Font
var text_font_size: int


func _ready():
	_typing_ctrl.update.connect(_update_cursor_position)
	_update_cursor_size()
	set_font_and_size(ConfigData.font, ConfigData.font_size)
	queue_redraw()


func set_font_and_size(p_font: Font, p_size: int):
	"""Set the exact same font and size as the main text"""
	font = p_font
	# text_font_size = p_size
	text_font_size = 50
	_update_cursor_size()
	queue_redraw()


func _update_cursor_size():
	if not font:
		return

	# Use the EXACT same font and size as the main text
	var monospace_width = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size).x
	var char_height = font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size).y

	# Set cursor size to consistent monospace width
	size = Vector2(monospace_width, char_height)


func _draw():
	print(_typing_ctrl.cursor_idx)
	if not is_active or not font:
		print("font is nil")
		return

	var cursor_pos = Vector2(0, 0)
	var text_pos = Vector2(0, font.get_ascent(text_font_size))

	# Define colors for different cursor styles
	var colors = {
		"block": Color(0.3, 0.5, 1.0, 1.0),  # Blue block
		"box": Color(1.0, 0.6, 0.0, 1.0),  # Orange box
		"line": Color(1.0, 0.6, 0.0, 1.0),  # Orange line
		"underline": Color(1.0, 1.0, 1.0, 1.0)  # White underline
	}

	match cursor_style:
		"block":
			draw_rect(Rect2(cursor_pos, size), colors.block)
			draw_string(
				font,
				text_pos,
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				text_font_size,
				Color.WHITE
			)

		"box":
			draw_rect(Rect2(cursor_pos, size), colors.box, false, 2)
			draw_string(
				font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, colors.box
			)

		"line":
			draw_string(
				font,
				text_pos,
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				text_font_size,
				colors.line
			)
			draw_line(cursor_pos, cursor_pos + Vector2(0, size.y), colors.line, 1)  # Thinner line (width 1)

		"underline":
			draw_line(
				cursor_pos + Vector2(0, size.y - 2),
				cursor_pos + Vector2(size.x, size.y - 2),
				colors.underline,
				2
			)
			draw_string(
				font,
				text_pos,
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				text_font_size,
				Color.WHITE
			)

		_:
			# Default to block
			draw_rect(Rect2(cursor_pos, size), colors.block)
			draw_string(
				font,
				text_pos,
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				text_font_size,
				Color.WHITE
			)


# func move_to(p_new_position: Vector2, p_animate: bool = true) -> void:
#   position = p_new_position
#   cursor_moved.emit()

# func set_active(p_active: bool) -> void:
#   is_active = p_active
#   queue_redraw()

# func set_style(p_style: String) -> void:
#   cursor_style = p_style
#   queue_redraw()


func _update_cursor_position() -> void:
	print("update_cursor_pos")
	# if not typing_cursor or not show_cursor:
	# return

	# if current_index < current_text.length():
	var text = _typing_ctrl.get_target_text()
	if _typing_ctrl.cursor_idx < text.length():
		var current_char = text[_typing_ctrl.cursor_idx]
		character = current_char
	else:
		# At end of text, could show a completion indicator or space
		character = " "

	# Calculate cursor position by measuring actual text width up to current position
	# var cursor_x = _calculate_accurate_cursor_position()
	var cursor_x = _typing_ctrl.chars_label_data[_typing_ctrl.cursor_idx]._label_size.x
	print("cursor_x: %s" % cursor_x)

	# Get Label's text rendering position to match exactly
	var control_offset = Vector2.ZERO
	# if sample_label:
	if _typing_ctrl:
		# Account for Label's internal text positioning
		var font_metrics = _typing_ctrl.get_theme_font("font")
		if font_metrics:
			# Add slight vertical offset to align baselines
			control_offset.y = 0  # Keep at top for now
			control_offset.x = 0  # No horizontal offset needed for left-aligned text

	# Ensure cursor position is valid and aligned with Label
	if cursor_x >= 0:
		position = Vector2(cursor_x + control_offset.x, control_offset.y)
		cursor_moved.emit()

# func _calculate_accurate_cursor_position() -> float:
#     if _typing_ctrl.current_position <= 0:
#         return 0.0

#     # Ensure we have up-to-date character width
#     # if character_width <= 0:
#         # _setup_character_overlays()

#     # Use exact same calculation as cursor internally uses
#     if character_width > 0:
#         var cursor_position = current_index * character_width
#         Log.info("[TextDisplay][_calculate_accurate_cursor_position] Position: index %d * width %f = %f" % [current_index, character_width, cursor_position])
#         return cursor_position

#     # Fallback calculation
#     var char_size = _estimate_character_size()
#     return current_index * char_size.x
