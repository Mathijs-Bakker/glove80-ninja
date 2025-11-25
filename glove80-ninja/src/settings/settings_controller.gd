class_name SettingsController
extends Control

# Typing Options
@export var stop_cursor_on_error: Button
@export var forgive_errors: Button
@export var space_skips_words: Button

# Font
@export var whitespace_show: Button
@export var whitespace_bar: Button
@export var whitespace_bullet: Button

@export var cursor_shape_block: Button
@export var cursor_shape_box: Button
@export var cursor_shape_line: Button
@export var cursor_shape_underline: Button

# methods


func _ready() -> void:
    ConfigService.
