class_name TypingController
extends Control
# Should be renamed PracticeController

# Keep track of cursor position
# Theme
# Fontsize

signal start_new_practice


@onready var _text_renderer: Control = $TextRenderer 

var _key_input: KeyInputHandler

# Practice Data
var _target_text: String = "Not initialized"
var chars_data: Array[CharacterData]

# var _cursor_position: CursorPosition


# State
var is_activated: bool = true # Todo: Should be false


func _ready() -> void:
    _setup()
    var text = "Hello, this is a test. Wrapping should keep punctuation attached, like word, or 'word-up'. Hello, this is a test. Wrapping should keep punctuation attached, like word, or word-up."
    initalize(text)
    start_new_practice.emit()



func _setup() -> void:    
    _key_input = KeyInputHandler.new(self)
    _key_input.name = "KeyInputHandler"
    add_child(_key_input)


func initalize(p_text: String) -> void:
    _target_text = p_text


func get_target_text() -> String:
    return _target_text
