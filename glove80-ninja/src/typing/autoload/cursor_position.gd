extends Node


signal reset
signal moved


var _current_position: Vector2 # cols & rows
var _pos_idx: CursorIndex


func _ready() -> void:
    _setup_signals()
    _reset()


func _setup_signals() -> void:
    reset.connect(_reset)
    moved.connect(_set_pos)


func idx() -> CursorIndex:
    return _pos_idx


func get_pos() -> Vector2:
    return _current_position


func _set_pos(p_pos: Vector2) -> void:
    _current_position = p_pos
    

func _reset() -> void:
    _current_position = Vector2(0.0, 0.0)
    _pos_idx = CursorIndex.new()


class CursorIndex:
    var current: int
    var last: int

    func _init(p_current: int = 0, p_last: int = 0) -> void:
        current = p_current
        last = p_last

