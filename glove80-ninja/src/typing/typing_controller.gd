class_name TypingController
extends Node


@onready var _text_layer: Control = $TextLayer
# @onready var _cursor_layer: Control = $CursorLayer

# var _config_service: ConfigService
var _text: String
var _font: Font
var theme: Theme


func _ready() -> void:
	var max_width := _text_layer.size.x
	_render_text(max_width)

func initialize(p_text: String) -> void:
	_text = p_text
	_text = "abc defgh ij klm nopq rstuvw xyz ab cdefghijklmnop qr stvwuxyz abc defgh ij klm nopq rstuvw xyz ab cdefghijklmnop qr stvwuxyz"

func _render_text(p_max_width: float) -> void:
	if _text.is_empty():
		return

	var font_size := 60
	_font = preload("res://assets/fonts/Ubuntu_Mono/UbuntuMono-Regular.ttf")
	var line_height := _font.get_height(font_size)

	var cursor_x := 0.0
	var cursor_y := 0.0

	# First handle manual newlines
	var lines := _text.split("\n", false)

	for line in lines:
		var words := line.split(" ", false)

		for word_index in words.size():
			var word := words[word_index]

			# measure full word width (including punctuation etc.)
			var word_width := 0.0
			for c in word:
				word_width += _font.get_char_size(c.unicode_at(0), font_size).x

			var space_width := _font.get_char_size(" ".unicode_at(0), font_size).x
			if word_index < words.size() - 1:
				word_width += space_width

			# wrap if needed
			if cursor_x + word_width > p_max_width:
				cursor_x = 0.0
				cursor_y += line_height

			# render word
			for c in word:
				var label := Label.new()
				label.text = c
				label.add_theme_font_override("font", _font)
				label.add_theme_font_size_override("font_size", font_size)
				label.set_anchors_preset(Control.PRESET_TOP_LEFT)

				var char_width := _font.get_char_size(c.unicode_at(0), font_size).x
				label.position = Vector2(cursor_x, cursor_y)
				label.custom_minimum_size = Vector2(char_width, line_height)

				_text_layer.add_child(label)
				cursor_x += char_width

			# add space
			if word_index < words.size() - 1:
				cursor_x += space_width

		# manual line break -> reset x and move y down
		cursor_x = 0.0
		cursor_y += line_height


func get_font_metrics(p_label: Label, p_character: String) -> Vector2:
	var font: Font = p_label.get_theme_font("font")
	var font_size: int = p_label.get_theme_font_size("font_size")

	var width := font.get_char_size(p_character.unicode_at(0), font_size).x
	var height := font.get_height(font_size)

	return Vector2(width, height)
