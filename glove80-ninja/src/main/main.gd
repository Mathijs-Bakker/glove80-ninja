extends Node

func _ready() -> void:
    Log.info("[main] Application started.")
    
    # Load and add typing_game.tscn as a child
    var typing_game_scene = preload("res://src/practice/practice.tscn")
    var typing_game_instance = typing_game_scene.instantiate()
    add_child(typing_game_instance)
    typing_game_instance.name = "TypingGame"
