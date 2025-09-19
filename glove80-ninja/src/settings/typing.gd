class_name TypingSettings
extends Control

@export var stop_cursor_on_error_btn: CheckBox
@export var forgive_errors_btn: CheckBox
@export var space_skips_words_btn: CheckBox
@export var whitespace_btn: ButtonGroup
@export var cursor_shape_btn: ButtonGroup

var stop_cursor_on_error: bool
var forgive_errors: bool
var space_skips_words: bool
var whitespace: TypingSettingsData.Whitespace
var cursor_shape: TypingSettingsData.CursorShape


func _set_default() -> void:
	stop_cursor_on_error = true
	forgive_errors = true
	space_skips_words = false
	whitespace = TypingSettingsData.Whitespace.SHOW
	cursor_shape = TypingSettingsData.CursorShape.BLOCK


class TypingSettingsData:
	var stop_cursor_on_error: bool
	var forgive_errors: bool
	var space_skips_words: bool
	var font: Font
	var font_size: int
	var whitespace: Whitespace
	var cursor_shape: CursorShape

	enum Whitespace { SHOW, BAR, BULLET }
	enum CursorShape { BLOCK, BOX, LINE, UNDERLINE }
