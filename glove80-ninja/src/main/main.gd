extends Node

func _ready() -> void:
	Log.info("[main] Application started.")
	instantiate_practice_scene()
	


func instantiate_practice_scene():
	var practice_scene = preload("res://src/practice/practice.tscn")
	var practice_instance = practice_scene.instantiate()
	add_child(practice_instance)
	practice_instance.name = "Practice"
