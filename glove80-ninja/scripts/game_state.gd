class_name GameState
extends RefCounted

var current_text: String = ""
var user_input: String = ""
var current_index: int = 0
var mistakes: int = 0
var is_typing: bool = false
var start_time: int = 0
var wpm: float = 0.0

func reset() -> void:
	current_text = ""
	user_input = ""
	current_index = 0
	mistakes = 0
	is_typing = false
	start_time = 0
	wpm = 0.0
