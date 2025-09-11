class_name TypingController
extends Control
# Should be renamed PracticeController

# Keep track of cursor position
# Theme
# Fontsize

signal start_new_practice
signal update

@export var _text_renderer: Control
@export var _key_input_handler: KeyInputHandler

# Practice Data
var _target_text: String = "Not initialized"
var cursor_idx: int
var chars_label_data: Array[CharacterData]

# State
var is_activated: bool = true  # Todo: Should be false


func _ready() -> void:
	# _setup()
	_setup_signals()
	var text = "Hello, this is a test. Wrapping should keep punctuation attached, like word, or 'word-up'. Hello, this is a test. Wrapping should keep punctuation attached, like word, or word-up."
	initalize(text)
	start_new_practice.emit()


func _setup_signals() -> void:
	_key_input_handler.character_typed.connect(_on_character_input)


func initalize(p_text: String) -> void:
	_target_text = p_text


func get_target_text() -> String:
	return _target_text


func _on_character_input(p_char: String, p_is_correct: bool, p_position: int) -> void:
	print("typing ctrl - on char input, is_correct: %s" % p_is_correct)
	print("typing ctrl - on char input, pos %s" % p_position)
	chars_label_data[p_position].is_correct = p_is_correct
	update.emit()
