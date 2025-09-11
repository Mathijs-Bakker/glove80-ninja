class_name CharacterData
extends RefCounted

var _value: String
var _position: Vector2
var _label_size: Vector2
var _line_height: float
var is_correct: bool


func _init(
	p_value: String,
	p_pos: Vector2,
	p_size: Vector2,
	p_line_height: float,
	p_is_correct: bool = false
) -> void:
	_value = p_value
	_position = p_pos
	_label_size = p_size
	_line_height = p_line_height
	is_correct = p_is_correct
