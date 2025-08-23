class_name TypingManager
extends RefCounted

signal typing_started()
signal typing_finished(wpm: float, accuracy: float, time: float, mistakes: int)
signal character_typed(correct: bool)
signal progress_updated(progress: float)

var current_text := ""
var user_input := ""
var current_char_index := 0
var mistakes := 0
var is_typing := false

func load_new_text(text: String) -> void:
	current_text = text
	user_input = ""
	current_char_index = 0
	mistakes = 0
	is_typing = false
	progress_updated.emit(0.0)

func handle_input(event: InputEventKey) -> bool:
	if not event.pressed or event.echo:
		return false
	
	if event.keycode == KEY_BACKSPACE:
		handle_backspace()
		return true
	elif event.unicode > 31 and event.unicode != 127:
		handle_character(event.unicode)
		return true
	
	return false

func handle_backspace() -> void:
	if user_input.length() > 0:
		user_input = user_input.substr(0, user_input.length() - 1)
		current_char_index = max(0, current_char_index - 1)
		progress_updated.emit(calculate_progress())

func handle_character(unicode: int) -> void:
	if not is_typing:
		is_typing = true
		typing_started.emit()
	
	var typed_char := char(unicode)
	user_input += typed_char
	
	if current_char_index < current_text.length():
		var is_correct := typed_char == current_text[current_char_index]
		if not is_correct:
			mistakes += 1
		character_typed.emit(is_correct)
		current_char_index += 1
	
	progress_updated.emit(calculate_progress())
	
	if current_char_index >= current_text.length():
		is_typing = false
		typing_finished.emit(0.0, calculate_accuracy(), 0.0, mistakes)

func calculate_progress() -> float:
	if current_text.is_empty():
		return 0.0
	return float(current_char_index) / float(current_text.length())

func calculate_accuracy() -> float:
	if user_input.is_empty():
		return 100.0
	
	var correct_chars := 0
	for i in range(min(user_input.length(), current_text.length())):
		if user_input[i] == current_text[i]:
			correct_chars += 1
	
	return (correct_chars / float(user_input.length())) * 100.0

func get_display_data() -> Dictionary:
	return {
		"current_text": current_text,
		"user_input": user_input,
		"current_index": current_char_index,
		"mistakes": mistakes
	}
