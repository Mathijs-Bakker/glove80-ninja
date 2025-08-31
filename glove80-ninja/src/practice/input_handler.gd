class_name InputHandler
extends Node

## Dedicated input handler for typing exercises
## Handles keyboard input, validation, and typing logic

signal character_typed(character: String, is_correct: bool, position: int)
signal input_completed()
signal input_error(error_type: String, details: Dictionary)
signal typing_started()
signal typing_paused()

# Configuration
var config_service: ConfigService
var allow_backspace: bool = true
var case_sensitive: bool = false
var ignore_whitespace_errors: bool = false

# Input state
var target_text: String = ""
var current_input: String = ""
var current_position: int = 0
var is_typing: bool = false
var start_time: int = 0
var last_input_time: int = 0

# Statistics tracking
var total_keystrokes: int = 0
var correct_keystrokes: int = 0
var mistakes_count: int = 0
var corrections_count: int = 0

# Special keys that should be ignored
var ignored_keys = [
	KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META,
	KEY_CAPSLOCK, KEY_NUMLOCK, KEY_SCROLLLOCK,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12
]


func initialize(p_config_service: ConfigService = null) -> void:
	config_service = p_config_service
	_apply_config_settings()


## Set the target text for typing
func set_target_text(p_text: String) -> void:
	target_text = p_text
	reset_input_state()


func reset_input_state() -> void:
	current_input = ""
	current_position = 0
	is_typing = false
	start_time = 0
	last_input_time = 0
	total_keystrokes = 0
	correct_keystrokes = 0
	mistakes_count = 0
	corrections_count = 0


func handle_keyboard_input(p_event: InputEvent) -> bool:
	if not p_event is InputEventKey:
		return false

	var key_event = p_event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false

	# Ignore special keys
	if key_event.keycode in ignored_keys:
		return false

	# Handle special keys
	if _handle_special_keys(key_event):
		return true

	# Handle character input
	if key_event.unicode > 0:
		return _handle_character_input(key_event)

	return false


# ## Get current input statistics
# func get_input_stats() -> Dictionary:
# 	var typing_time = (Time.get_ticks_msec() - start_time) / 1000.0 if is_typing else 0.0
# 	var accuracy = (float(correct_keystrokes) / float(total_keystrokes) * 100.0) if total_keystrokes > 0 else 100.0

# 	return {
# 		"input_length": current_input.length(),
# 		"position": current_position,
# 		"total_keystrokes": total_keystrokes,
# 		"correct_keystrokes": correct_keystrokes,
# 		"mistakes": mistakes_count,
# 		"corrections": corrections_count,
# 		"accuracy": accuracy,
# 		"typing_time": typing_time,
# 		"is_complete": _is_input_complete()
# 	}


# Private methods

func _apply_config_settings() -> void:
	if not config_service:
		return

	allow_backspace = config_service.get_setting("allow_backspace", true)
	case_sensitive = config_service.get_setting("case_sensitive", false)
	ignore_whitespace_errors = config_service.get_setting("ignore_whitespace_errors", false)


func _handle_special_keys(p_key_event: InputEventKey) -> bool:
	match p_key_event.keycode:
		KEY_BACKSPACE:
			return _handle_backspace()
		KEY_ENTER:
			return _handle_enter()
		KEY_TAB:
			return _handle_tab()
		KEY_ESCAPE:
			return _handle_escape()

	return false


func _handle_character_input(p_key_event: InputEventKey) -> bool:
	var character = char(p_key_event.unicode)

	if not is_typing:
		_start_typing()

	_update_last_input_time()
	total_keystrokes += 1

	# Check if we can accept more input
	if current_position >= target_text.length():
		input_error.emit("overflow", {"position": current_position, "character": character})
		return true

	# Get expected character
	var expected_char = target_text[current_position]
	var is_correct = _is_character_correct(character, expected_char)

	# Process the character
	if is_correct:
		correct_keystrokes += 1
		current_input += character

		# Check if input is complete
		var is_complete = _is_input_complete()
		print("_is_input_complete: ", is_complete)
		if is_complete:
			input_completed.emit()
		else:
			current_position += 1
	else:
		mistakes_count += 1
		# In replace mode, we still advance but mark as incorrect
		current_input += character
		current_position += 1

	# Emit character typed signal
	character_typed.emit(character, is_correct, current_position - 1)

	return true


func _handle_backspace() -> bool:
	if not allow_backspace or current_position <= 0:
		return true

	_update_last_input_time()
	corrections_count += 1

	# Remove last character
	current_position -= 1
	current_input = current_input.substr(0, current_position)

	character_typed.emit("", false, current_position)  # Signal backspace
	return true


func _handle_enter() -> bool:
	# Only handle enter if the next expected character is a newline
	if current_position < target_text.length() and target_text[current_position] == "\n":
		return _handle_character_input_direct("\n")

	return false


func _handle_tab() -> bool:
	# Only handle tab if the next expected character is a tab
	if current_position < target_text.length() and target_text[current_position] == "\t":
		return _handle_character_input_direct("\t")

	return false


func _handle_escape() -> bool:
	# Pause typing or emit escape signal
	if is_typing:
		typing_paused.emit()
	return true


func _handle_character_input_direct(p_character: String) -> bool:
	if current_position >= target_text.length():
		return false

	var expected_char = target_text[current_position]
	var is_correct = _is_character_correct(p_character, expected_char)

	_update_last_input_time()
	total_keystrokes += 1

	if is_correct:
		correct_keystrokes += 1
		current_input += p_character
		current_position += 1

		if _is_input_complete():
			input_completed.emit()
	else:
		mistakes_count += 1
		current_input += p_character
		current_position += 1

	character_typed.emit(p_character, is_correct, current_position - 1)
	return true


func _is_character_correct(p_input_char: String, p_expected_char: String) -> bool:
	if not case_sensitive:
		p_input_char = p_input_char.to_lower()
		p_expected_char = p_expected_char.to_lower()

	# Handle whitespace error ignoring
	if ignore_whitespace_errors and (p_input_char.strip_edges().is_empty() or p_expected_char.strip_edges().is_empty()):
		return p_input_char.strip_edges() == p_expected_char.strip_edges()

	return p_input_char == p_expected_char


func _is_input_complete() -> bool:
	return current_position >= target_text.length()


func _start_typing() -> void:
	is_typing = true
	start_time = Time.get_ticks_msec()
	last_input_time = start_time
	typing_started.emit()


func _update_last_input_time() -> void:
	last_input_time = Time.get_ticks_msec()


func _get_typing_duration() -> float:
	if not is_typing:
		return 0.0
	return (Time.get_ticks_msec() - start_time) / 1000.0


func _get_idle_time() -> float:
	if not is_typing:
		return 0.0
	return (Time.get_ticks_msec() - last_input_time) / 1000.0
