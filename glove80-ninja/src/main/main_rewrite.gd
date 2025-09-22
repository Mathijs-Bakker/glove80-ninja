extends Node

@onready var content_container: Control = $MainContainer/ContentContainer


func _ready() -> void:
	# create_typing_controller()
	pass


func create_typing_controller() -> void:
	var typing_scene = load("res://src/typing/typing.tscn")

	# if not typing_scene:
	# return null

	var typing_controller = typing_scene.instantiate()
	# typing_controller.initialize("This is text")
	add_child(typing_controller)
