extends Node
class_name Main

func _ready() -> void:
    print("🎯 Main scene loaded")
    
    # Load and add typing_game.tscn as a child
    var typing_game_scene = preload("res://scenes/typing game controller/typing_game.tscn")
    var typing_game_instance = typing_game_scene.instantiate()
    add_child(typing_game_instance)
    typing_game_instance.name = "TypingGame"
    
    print("✅ TypingGame instance added as child")
    
    # Verify ConfigManager exists
    if has_node("/root/ConfigManager"):
        print("✅ ConfigManager found")
    else:
        print("❌ ConfigManager NOT found")
