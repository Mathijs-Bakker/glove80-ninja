class_name TextRenderer extends Control

signal reset

var _text: String
var _font: Font
var _font_size: int
var _has_validated: bool

var _cursor: Vector2
var char_label_names: Array[String]

@export var _typing_ctrl: TypingController


func _ready() -> void:
	_typing_ctrl.start_new_practice.connect(on_start_practice)
	_typing_ctrl.update.connect(_update_text)
	_font_size = 40
	_font = preload("res://assets/fonts/Ubuntu_Mono/UbuntuMono-Regular.ttf")


func on_start_practice() -> void:
	_text = _typing_ctrl.get_target_text()
	remove_labels()
	_render_text()


func _update_text() -> void:
	var cursor_idx = _typing_ctrl.cursor_idx - 1  # cursor index has been advanced. This can become an issue with backspace
	var char_data = _typing_ctrl.chars_label_data[cursor_idx]

	var label_name = char_label_names[cursor_idx]

	var label = get_node(label_name)

	if char_data.is_correct:
		label.set_theme_type_variation("correct_char")
	else:
		label.set_theme_type_variation("incorrect_char")


func _render_text() -> void:
	if _text.is_empty():
		return

	if not _has_validated:
		_font_size = 40
		_font = preload("res://assets/fonts/Ubuntu_Mono/UbuntuMono-Regular.ttf")
		var line_height := _font.get_height(_font_size)

		var max_width := size.x
		_cursor = Vector2(0.0, 0.0)

		var lines := _text.split("\n", false)
		for line in lines:
			var words := line.split(" ", false)

			for word_idx in range(words.size()):
				var word := words[word_idx]
				var word_width := _measure_word(word, _font_size)
				var space_width := _font.get_char_size(" ".unicode_at(0), _font_size).x

				# wrap if word doesn’t fit
				if _cursor.x + word_width > max_width:
					_cursor.x = 0.0
					_cursor.y += line_height

				# render word
				for c in word:
					var char_size := _font.get_char_size(c.unicode_at(0), _font_size)
					# _create_char_label(c, Vector2(_cursor.x, _cursor.y), char_size, line_height)
					_typing_ctrl.chars_label_data.append(
						CharacterData.new(c, Vector2(_cursor.x, _cursor.y), char_size, line_height)
					)
					_cursor.x += char_size.x

				# render space
				if word_idx < words.size() - 1:
					var space_size := Vector2(space_width, line_height)
					# _create_char_label(" ", Vector2(_cursor.x, _cursor.y), space_size, line_height)
					_typing_ctrl.chars_label_data.append(
						CharacterData.new(
							" ", Vector2(_cursor.x, _cursor.y), space_size, line_height
						)
					)
					_cursor.x += space_width

		_has_validated = true

	var count = 0
	var prefix_name = "CharLabel_"

	for data in _typing_ctrl.chars_label_data:
		var label_name = prefix_name + str(count)
		char_label_names.append(label_name)

		_create_char_label(
			label_name,
			data._value,
			data._position,
			data._label_size,
			data._line_height,
		)
		count += 1

	reset.emit()


func _measure_word(p_word: String, p_font_size: int) -> float:
	var width := 0.0
	for c in p_word:
		width += _font.get_char_size(c.unicode_at(0), p_font_size).x
	return width


func _create_char_label(
	p_name: String,
	p_char: String,
	p_pos: Vector2,
	p_size: Vector2,
	p_line_height: float,
) -> void:
	var label := Label.new()
	label.name = p_name
	label.text = p_char
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", _font_size)
	label.set_theme_type_variation("pending_char")
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = p_pos
	label.custom_minimum_size = Vector2(p_size.x, p_line_height)
	add_child(label)


func remove_labels() -> void:
	for child in get_children():
		child.queue_free()
