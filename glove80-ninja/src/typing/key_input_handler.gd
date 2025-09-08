class_name KeyInputHandler
extends Node

signal character_typed(character: String, is_correct: bool, position: int)

@export var _typing_ctrl: TypingController

# Config:
var _stop_cursor_on_error: bool = false
var _forgive_errors: bool = true  # allow backspace
var _space_skips_words: bool = false


func _input(event: InputEvent) -> void:
	# print(event)
	# if event is InputEventKey and event.pressed:
	# if event is InputEventKey:
	# if not _typing_ctrl.is_active:
	# return
	_handle_keyboard_input(event)


var ignored_keys = [
	KEY_SHIFT,
	KEY_CTRL,
	KEY_ALT,
	KEY_META,
	KEY_CAPSLOCK,
	KEY_NUMLOCK,
	KEY_SCROLLLOCK,
	KEY_F1,
	KEY_F2,
	KEY_F3,
	KEY_F4,
	KEY_F5,
	KEY_F6,
	KEY_F7,
	KEY_F8,
	KEY_F9,
	KEY_F10,
	KEY_F11,
	KEY_F12
]


func _handle_special_keys(p_key_event: InputEventKey) -> bool:
	match p_key_event.keycode:
		KEY_BACKSPACE:
			return _handle_backspace()
		# KEY_ENTER:
		#     return _handle_enter()
		# KEY_TAB:
		#     return _handle_tab()
		# KEY_ESCAPE:
		#     return _handle_escape()

	return false


func _handle_backspace() -> bool:
	var allow_backspace = _forgive_errors
	# if not allow_backspace or current_position <= 0:
	# if not allow_backspace or CursorPosition.get_idx().current <= 0:
	if not allow_backspace or _typing_ctrl.current_position <= 0:
		return true

	# _update_last_input_time()
	# corrections_count += 1

	# Remove last character
	# current_position -= 1
	# current_input = current_input.substr(0, current_position)

	# character_typed.emit("", false, current_position)  # Signal backspace
	return true


# func _handle_enter() -> bool:
#   # Only handle enter if the next expected character is a newline
#   if current_position < target_text.length() and target_text[current_position] == "\n":
#       return _handle_character_input_direct("\n")

#   return false

# func _handle_tab() -> bool:
#   # Only handle tab if the next expected character is a tab
#   if current_position < target_text.length() and target_text[current_position] == "\t":
#       return _handle_character_input_direct("\t")

#   return false

# func _handle_escape() -> bool:
#   # Pause typing or emit escape signal
#   if is_typing:
#       typing_paused.emit()
#   return true


func _handle_keyboard_input(p_event: InputEvent) -> bool:
	if not p_event is InputEventKey:
		return false

	var key_event = p_event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	if key_event.keycode in ignored_keys:
		return false

	if _handle_special_keys(key_event):
		return true

	if key_event.unicode > 0:
		return _handle_character_input(key_event)

	return false


func _handle_character_input(p_key_event: InputEventKey) -> bool:
	var character = char(p_key_event.unicode)

	# if not is_typing:
	# _start_typing()

	# _update_last_input_time()
	# total_keystrokes += 1

	# Check if we can accept more input
	if _typing_ctrl.current_position >= _typing_ctrl.get_target_text().length():
		# input_error.emit("overflow", {"position": current_position, "character": character})
		print("Overflow")
		return true

	# Get expected character
	var expected_char = _typing_ctrl.get_target_text()[_typing_ctrl.current_position]
	var is_correct = _is_character_correct(character, expected_char)

	# Process the character
	if is_correct:
		# correct_keystrokes += 1
		# current_input += character

		if _is_input_complete():
			# input_completed.emit()
			print("Input Completed")
		else:
			print("KeyInputHandler -> is_correct")
			_typing_ctrl.current_position += 1
	else:
		# mistakes_count += 1
		# In replace mode, we still advance but mark as incorrect
		# current_input += character
		_typing_ctrl.current_position += 1
		print("KeyInputHandler -> Mistake")

	# Emit character typed signal
	character_typed.emit(character, is_correct, _typing_ctrl.current_position - 1)
	_typing_ctrl.update_position.emit()
	print("input handler")

	return true


func _is_character_correct(p_input_char: String, p_expected_char: String) -> bool:
	# if not case_sensitive:
	# p_input_char = p_input_char.to_lower()
	# p_expected_char = p_expected_char.to_lower()

	# Handle whitespace error ignoring
	# if ignore_whitespace_errors and (p_input_char.strip_edges().is_empty() or p_expected_char.strip_edges().is_empty()):
	# return p_input_char.strip_edges() == p_expected_char.strip_edges()

	return p_input_char == p_expected_char


func _is_input_complete() -> bool:
	var text_length = _typing_ctrl.get_target_text().length()
	return _typing_ctrl.current_position >= text_length
