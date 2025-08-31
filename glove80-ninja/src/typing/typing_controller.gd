class_name TypingController
extends Node


@onready var _text_layer: Control = $TextLayer
# @onready var _cursor_layer: Control = $CursorLayer

# var _config_service: ConfigService
var _text: String
# var theme: Theme


func _ready() -> void:
	# theme = load("res://themes/dark.tres")
	_render_text()


func initialize(p_text: String) -> void:
	_text = p_text
	_text = "abcd efg abcd xyz abcdefghij klm no p qrst uvw xyz abcd efg abcd xyz abcdefghij klm no p qrst uvw xyz abcd efg abcd xyz abcdefghij klm no p qrst uvw xyz"


func _render_text() -> void:
	if _text.is_empty():
		return
	
	var last_position: Vector2 = Vector2(0.0, 0.0)

	for i in _text.length():
		var c = _text[i]

		var label := Label.new()
		var font_metrics = get_font_metrics(label, c)

		if c == "\n":
			last_position.x = 0.0
			last_position.y += font_metrics.y
			continue

		label.text = c

		label.add_theme_font_size_override("font_metrics", 60)
		label.set_anchors_preset(Control.PRESET_TOP_LEFT)

		# positioning:
		label.position.x = last_position.x
		last_position.x += font_metrics.x
		label.custom_minimum_size = Vector2(font_metrics.x, font_metrics.y)

		_text_layer.add_child(label)  


func get_font_metrics(p_label: Label, p_character: String) -> Vector2:
	var font: Font = p_label.get_theme_font("font")
	var font_size: int = p_label.get_theme_font_size("font_size")

	var width := font.get_char_size(p_character.unicode_at(0), font_size).x
	var height := font.get_height(font_size)

	return Vector2(width, height)
