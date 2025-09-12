class_name Cursor
extends Control

@export var _typing_ctrl: TypingController
@export var _text_renderer: TextRenderer

var character: String = "X":
	set(value):
		character = value
		queue_redraw()

var cursor_shape = CursorShape.BLOCK:
	set(value):
		cursor_shape = value
		queue_redraw()

var font_size: int = 40:
	set(value):
		font_size = value
		queue_redraw()

var font_color: Color = Color.WHITE

var font: Font
var text_font_size: int

enum CursorShape { BLOCK, BOX, LINE, UNDERLINE }


func _ready():
	_typing_ctrl.update.connect(_update_cursor_position)
	_text_renderer.reset.connect(_update_cursor_position)
	font = _text_renderer._font
	text_font_size = _text_renderer._font_size
	queue_redraw()


func _draw():
	var cursor_pos = Vector2(0, 0)
	var text_pos = Vector2(0, font.get_ascent(text_font_size))

	var bg_color = ConfigData.theme.get_color("bg_color", "cursor")
	var font_col = ConfigData.theme.get_color("font_color", "cursor")
	var block_font_col = ConfigData.theme.get_color("block_font_color", "cursor")

	match cursor_shape:
		CursorShape.BLOCK:
			draw_rect(Rect2(cursor_pos, size), bg_color)
			draw_string(
				font,
				text_pos,
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				text_font_size,
				block_font_col
			)

		CursorShape.BOX:
			draw_rect(Rect2(cursor_pos, size), bg_color, false, 2)
			draw_string(
				font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, font_col
			)

		CursorShape.LINE:
			draw_string(
				font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, font_col
			)
			draw_line(cursor_pos, cursor_pos + Vector2(0, size.y), bg_color, 1)  # Thinner line (width 1)

		CursorShape.UNDERLINE:
			draw_line(
				cursor_pos + Vector2(0, size.y - 2),
				cursor_pos + Vector2(size.x, size.y - 2),
				bg_color,
				2
			)
			draw_string(
				font, text_pos, character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, font_col
			)

		_:
			# Default to block
			draw_rect(Rect2(cursor_pos, size), bg_color)
			draw_string(
				font,
				text_pos,
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				text_font_size,
				block_font_col
			)


# func move_to(p_new_position: Vector2, p_animate: bool = true) -> void:
#   position = p_new_position
#   cursor_moved.emit()


func _update_cursor_position() -> void:
	var text = _typing_ctrl.get_target_text()

	if _typing_ctrl.cursor_idx < text.length():
		var current_char = text[_typing_ctrl.cursor_idx]
		character = current_char
	else:
		# At end of text, could show a completion indicator or space
		character = " "

	var char_label = _typing_ctrl.chars_label_data[_typing_ctrl.cursor_idx]
	var offset_pos = _text_renderer.position
	position = char_label._position + offset_pos
	size = char_label._label_size
