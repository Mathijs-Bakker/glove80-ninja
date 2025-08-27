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

	# # Use the EXACT same font and size as the main text
	var monospace_width = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size).x
	var char_height = font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size).y

	# Set consistent terminal-style cursor size
	size = Vector2(monospace_width, char_height)


func _draw():
	if not is_active or not font:
		return

	# Draw cursor background
	var rect = Rect2(Vector2(0, 0), size)
	var cursor_color = Color(0.3, 0.5, 1.0, 1.0)
	draw_rect(rect, cursor_color)

	# Draw character using EXACT same font and size as text
	var text_pos = Vector2(0, font.get_ascent(text_font_size))
	draw_string(font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, Color.WHITE)

func set_font_size(p_new_size: int) -> void:
	font_size = p_new_size
	if font:
		_update_cursor_size()


func move_to(p_new_position: Vector2, p_animate: bool = true) -> void:
	position = p_new_position
	cursor_moved.emit()

func set_active(p_active: bool) -> void:
	is_active = p_active
	queue_redraw()

func set_style(p_style: String) -> void:
	cursor_style = p_style
	queue_redraw()
