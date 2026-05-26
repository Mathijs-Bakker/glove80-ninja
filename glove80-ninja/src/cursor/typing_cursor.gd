class_name TypingCursor
extends Control

signal cursor_moved

var character: String = " ":
	set(value):
		character = value
		queue_redraw()

var is_active: bool = true:
	set(value):
		is_active = value
		visible = value
		queue_redraw()

var _cursor_style: String = "block"
var _font: Font
var _font_size: int = 16
var _text_color: Color = Color.WHITE
var _cursor_color: Color = Color(0.95, 0.95, 0.95, 0.9)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(p_what: int) -> void:
	if p_what == NOTIFICATION_RESIZED or p_what == NOTIFICATION_TRANSFORM_CHANGED:
		cursor_moved.emit()


func set_active(p_active: bool) -> void:
	is_active = p_active


func set_style(p_style: String) -> void:
	_cursor_style = p_style
	queue_redraw()


func set_font_and_size(p_font: Font, p_font_size: int) -> void:
	_font = p_font
	_font_size = p_font_size
	queue_redraw()


func _draw() -> void:
	if not is_active:
		return

	var draw_rect_size = size
	if draw_rect_size.x <= 0:
		draw_rect_size.x = 10
	if draw_rect_size.y <= 0:
		draw_rect_size.y = 20

	match _cursor_style:
		"line":
			draw_line(Vector2.ZERO, Vector2(0, draw_rect_size.y), _cursor_color, 2.0)
		"underline":
			draw_line(
				Vector2(0, draw_rect_size.y - 2),
				Vector2(draw_rect_size.x, draw_rect_size.y - 2),
				_cursor_color,
				2.0
			)
		"box":
			draw_rect(Rect2(Vector2.ZERO, draw_rect_size), _cursor_color, false, 2.0)
		_:
			draw_rect(Rect2(Vector2.ZERO, draw_rect_size), _cursor_color)

	if _font and not character.is_empty():
		var baseline = _font.get_ascent(_font_size)
		var text_color = _text_color if _cursor_style != "block" else Color.BLACK
		draw_string(
			_font,
			Vector2(0, baseline),
			character,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			_font_size,
			text_color
		)
