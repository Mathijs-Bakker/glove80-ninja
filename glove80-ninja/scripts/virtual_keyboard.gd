# Create a separate scene for virtual keyboard
# VirtualKeyboard.gd
extends HBoxContainer

@onready var key_scene = preload("res://Key.tscn")  # Create a simple Key scene

func _ready():
    create_keyboard()

func create_keyboard():
    var rows = [
        "1234567890-=",
        "qwertyuiop[]",
        "asdfghjkl;'",
        "zxcvbnm,./"
    ]
    
    for row in rows:
        var row_container = HBoxContainer.new()
        for char in row:
            var key = key_scene.instantiate()
            key.get_node("Label").text = char
            row_container.add_child(key)
        add_child(row_container)xtends Control
