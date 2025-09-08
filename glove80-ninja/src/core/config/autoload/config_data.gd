extends Node


var theme = preload("res://themes/dark.tres")
var font: FontFile
var font_size: int

func _ready() -> void:
	font = load("res://assets/fonts/Ubuntu_Mono/UbuntuMono-Regular.ttf")
