class_name TextDisplayManager
extends RefCounted

var sample_label: RichTextLabel
var config_manager: Node

func setup(label_node: RichTextLabel, config_node: Node) -> void:
	sample_label = label_node
	config_manager = config_node

func update_display(typing_data: Dictionary) -> void:
	if not sample_label:
		push_error("SampleLabel not set up!")
		return
	
	var cursor_style = config_manager.get_setting("cursor_style", "block") if config_manager else "block"
	var display_text := ""
	var current_text: String = typing_data.get("current_text", "")
	var user_input: String = typing_data.get("user_input", "")
	var current_index: int = typing_data.get("current_index", 0)
	
	for i in range(current_text.length()):
		if i < user_input.length():
			if user_input[i] == current_text[i]:
				display_text += "[color=green]" + current_text[i] + "[/color]"
			else:
				display_text += "[color=red]" + current_text[i] + "[/color]"
		else:
			if i == current_index:
				display_text += get_cursor_format(current_text[i], cursor_style)
			else:
				display_text += current_text[i]
	
	sample_label.text = display_text

func get_cursor_format(character: String, style: String) -> String:
	match style:
		"block":
			return "[bgcolor=#555555][color=white]" + character + "[/color][/bgcolor]"
		"box":
			return "[border=2][color=#FF9900]" + character + "[/color][/border]"
		"line":
			return "[u][color=#FF9900]" + character + "[/color][/u]"
		"underline":
			return "[u][color=white]" + character + "[/color][/u]"
		_:
			return "[bgcolor=#444444][u]" + character + "[/u][/bgcolor]"

func update_stats_display(stats: Dictionary, stats_label: Label) -> void:
	if stats_label:
		stats_label.text = "WPM: %.1f | Accuracy: %.1f%% | Mistakes: %d" % [
			stats.get("wpm", 0.0), 
			stats.get("accuracy", 0.0), 
			stats.get("mistakes", 0)
		]
