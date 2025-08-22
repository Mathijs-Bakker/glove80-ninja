extends Control

@export var text_to_type: String = "hello world this is a test"
var typed_text: String = ""
var caret_visible: bool = true

func _ready():
	$TypedText.text = ""
	$Progress.value = 0
	_update_display()

	# Timer for caret blinking
	var t := Timer.new()
	t.wait_time = 0.5
	t.autostart = true
	t.one_shot = false
	add_child(t)
	t.timeout.connect(_on_caret_blink)

func _on_caret_blink():
	caret_visible = !caret_visible
	_update_display()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key = OS.get_keycode_string(event.keycode).to_lower()

		# Handle space
		if event.keycode == KEY_SPACE:
			key = " "

		# Handle backspace
		if event.keycode == KEY_BACKSPACE:
			if typed_text.length() > 0:
				typed_text = typed_text.substr(0, typed_text.length() - 1)
			_update_display()
			return

		# Ignore modifier keys (Shift, Ctrl, etc.)
		if key.length() != 1:
			return

		typed_text += key
		_update_display()

func _update_display():
	var bbcode := ""
	var correct_until := 0

	# Already typed characters
	for i in range(typed_text.length()):
		if i < text_to_type.length():
			var typed_char := typed_text[i]
			var target_char := text_to_type[i]

			if typed_char == target_char:
				bbcode += "[color=white]" + typed_char + "[/color]"
				correct_until += 1
			else:
				bbcode += "[color=red]" + typed_char + "[/color]"
		else:
			bbcode += "[color=red]" + typed_text[i] + "[/color]"

	# Remaining text
	if typed_text.length() < text_to_type.length():
		var remaining := text_to_type.substr(typed_text.length())
		bbcode += "[color=gray]" + remaining + "[/color]"

	# Caret always after the typed part
	if caret_visible:
		bbcode = bbcode.insert(typed_text.length(), "[color=yellow]_[/color]")

	$TypedText.text = bbcode
	$Progress.value = float(correct_until) / text_to_type.length() * 100.0

	if correct_until == text_to_type.length():
		print("✅ Completed exercise!")
