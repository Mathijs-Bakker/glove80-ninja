extends Control
class_name TypingCursor

## Ultra-simple cursor for testing - always draws a blue block

signal cursor_moved
signal cursor_style_changed

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
	_update_cursor_size()
	queue_redraw()


func set_font_and_size(p_font: Font, p_size: int):
	"""Set the exact same font and size as the main text"""
	font = p_font
	text_font_size = p_size
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

	Log.info("[TypingCursor] Font: %s" % font)
	Log.info("[TypingCursor] Font size: %d" % text_font_size)
	Log.info("[TypingCursor] Character width: %f" % monospace_width)
	Log.info("[TypingCursor] Cursor size: %s" % size)
	Log.info("[TypingCursor] Cursor position: %s" % position)


func _draw():
	if not is_active or not font:
		return

	var cursor_pos = Vector2(0, 0)
	var text_pos = Vector2(0, font.get_ascent(text_font_size))

	# Define colors for different cursor styles
	var colors = {
		"block": Color(0.3, 0.5, 1.0, 1.0),  # Blue block
		"box": Color(1.0, 0.6, 0.0, 1.0),    # Orange box
		"line": Color(1.0, 0.6, 0.0, 1.0),   # Orange line
		"underline": Color(1.0, 1.0, 1.0, 1.0)  # White underline
	}

	match cursor_style:
		"block":
			# Solid filled block
			draw_rect(Rect2(cursor_pos, size), colors.block)
			draw_string(font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, Color.WHITE)

		"box":
			# Outlined box
			draw_rect(Rect2(cursor_pos, size), colors.box, false, 2)
			draw_string(font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, colors.box)

		"line":
			# Draw character at exact same position as block cursor (perfect alignment)
			draw_string(font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, colors.line)
			# Draw thin vertical line at the left edge of the character position
			draw_line(cursor_pos, cursor_pos + Vector2(0, size.y), colors.line, 1)  # Thinner line (width 1)

		"underline":
			# Underline at bottom
			draw_line(cursor_pos + Vector2(0, size.y - 2), cursor_pos + Vector2(size.x, size.y - 2), colors.underline, 2)
			draw_string(font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, Color.WHITE)

		_:
			# Default to block if unknown style
			draw_rect(Rect2(cursor_pos, size), colors.block)
			draw_string(font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, Color.WHITE)


func move_to(p_new_position: Vector2, p_animate: bool = true) -> void:
	position = p_new_position
	cursor_moved.emit()


func set_active(p_active: bool) -> void:
	is_active = p_active
	queue_redraw()


func set_style(p_style: String) -> void:
	cursor_style = p_style
	queue_redraw()
