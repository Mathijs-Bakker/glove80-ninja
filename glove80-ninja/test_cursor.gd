extends Control

## Test script to verify cursor rendering works correctly

var test_cursor: TypingCursor

func _ready():
	print("=== CURSOR TEST STARTING ===")

	# Create cursor
	test_cursor = TypingCursor.new()
	test_cursor.name = "TestCursor"
	add_child(test_cursor)

	# Position cursor in center of screen
	test_cursor.position = Vector2(400, 300)

	# Set cursor properties
	test_cursor.character = "A"
	test_cursor.font_size = 24
	test_cursor.cursor_style = "block"  # Explicitly set to block
	test_cursor.is_active = true

	print("Cursor created with:")
	print("  Style: ", test_cursor.cursor_style)
	print("  Character: ", test_cursor.character)
	print("  Font Size: ", test_cursor.font_size)
	print("  Is Active: ", test_cursor.is_active)
	print("  Position: ", test_cursor.position)
	print("  Size: ", test_cursor.size)

	# Test different styles after 2 seconds
	await get_tree().create_timer(2.0).timeout
	print("\n=== TESTING DIFFERENT CURSOR STYLES ===")

	# Test block style
	test_cursor.set_style("block")
	test_cursor.character = "B"
	print("Set to BLOCK style with character 'B'")

	await get_tree().create_timer(2.0).timeout

	# Test box style
	test_cursor.set_style("box")
	test_cursor.character = "C"
	print("Set to BOX style with character 'C'")

	await get_tree().create_timer(2.0).timeout

	# Test line style
	test_cursor.set_style("line")
	test_cursor.character = "D"
	print("Set to LINE style with character 'D'")

	await get_tree().create_timer(2.0).timeout

	# Test underline style
	test_cursor.set_style("underline")
	test_cursor.character = "E"
	print("Set to UNDERLINE style with character 'E'")

	await get_tree().create_timer(2.0).timeout

	# Back to block
	test_cursor.set_style("block")
	test_cursor.character = "F"
	print("Back to BLOCK style with character 'F'")

	print("\n=== CURSOR TEST COMPLETED ===")
	print("If you see a vertical line instead of a block, there's a rendering issue.")
	print("Check the console for debug messages from the cursor.")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_SPACE:
			# Cycle through characters
			var chars = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
			var current_char = test_cursor.character
			var index = chars.find(current_char)
			var next_index = (index + 1) % chars.size()
			test_cursor.character = chars[next_index]
			print("Changed character to: ", test_cursor.character)
