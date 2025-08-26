extends Node

func _ready() -> void:
	print("[main] Application started.")
	
	# Load and add typing_game.tscn as a child
	var practice_scene = preload("res://src/practice/practice.tscn")
	var practice_instance = practice_scene.instantiate()
	add_child(practice_instance)
	practice_instance.name = "Practice"
