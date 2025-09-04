class_name TextRenderer
extends Control

var _text: String
var _font: Font
var _font_size: int
var _has_validated: bool

var _cursor: Vector2

@export var _typing_controller: TypingController 



func _ready() -> void:
    # _text = _typing_controller.get_target_text() 
    # print("Text: %s" % _text)
    _typing_controller.start_new_practice.connect(on_start_practice)
    CursorPosition.moved.connect(_update_text)

    # _render_text()


func on_start_practice() -> void:
    _text = _typing_controller.get_target_text() 
    remove_labels()
    _render_text()


func _update_text() -> void:
    print("_update_text()")
    var pos = CursorPosition.get_pos()
        
    # for i in _typing_controller.char_data.size():
    #   await get_tree().create_timer(0.1).timeout
    #   _typing_controller.char_data[i].is_wrong = true

    #   _render_text()
    #   print(i)



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
                    _typing_controller.chars_data.append(CharacterData.new(c, Vector2(_cursor.x, _cursor.y), char_size, line_height))
                    _cursor.x += char_size.x

                # render space
                if word_idx < words.size() - 1:
                    var space_size := Vector2(space_width, line_height)
                    # _create_char_label(" ", Vector2(_cursor.x, _cursor.y), space_size, line_height)
                    _typing_controller.chars_data.append(CharacterData.new(" ", Vector2(_cursor.x, _cursor.y), space_size, line_height))
                    _cursor.x += space_width

        _has_validated = true


    for data in _typing_controller.chars_data:
        _create_char_label(data._value, data._position, data._label_size, data._line_height, data.is_wrong)



func _measure_word(p_word: String, p_font_size: int) -> float:
    var width := 0.0
    for c in p_word:
        width += _font.get_char_size(c.unicode_at(0), p_font_size).x
    return width


func _create_char_label(p_char: String, p_pos: Vector2, p_size: Vector2, p_line_height: float, p_is_wrong: bool) -> void:
    var label := Label.new()
    label.text = p_char
    label.add_theme_font_override("font", _font)
    label.add_theme_font_size_override("font_size", _font_size)
    if p_is_wrong:
        label.set_theme_type_variation("incorrect_char")
    label.set_anchors_preset(Control.PRESET_TOP_LEFT)
    label.position = p_pos
    label.custom_minimum_size = Vector2(p_size.x, p_line_height)
    add_child(label)


func remove_labels() -> void:
    for child in get_children():
        child.queue_free()
