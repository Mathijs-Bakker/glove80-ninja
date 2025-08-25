extends Node

## Handles text display and cursor visualization based on user settings


# Color constants for cursor styles
const CURSOR_COLORS = {
    "block": {
        "background": "#555555",
        "text": "#FFFFFF",
        "border": ""
    },
    "box": {
        "background": "",
        "text": "#FF9900", 
        "border": "2,#FF9900"
    },
    "line": {
        "background": "",
        "text": "#FF9900",
        "border": ""
    },
    "underline": {
        "background": "",
        "text": "#FFFFFF", 
        "border": ""
    }
}

@onready var sample_label: RichTextLabel
var config_manager: Node


func setup(p_label_node: RichTextLabel, p_config_node: Node) -> void:
    sample_label = p_label_node
    config_manager = p_config_node
    print("TextDisplayManager setup complete")


func update_display(p_typing_data: Dictionary) -> void:
    if not sample_label:
        push_error("SampleLabel not set up!")
        return
    
    var cursor_style = UserConfigManager.get_setting("cursor_style", "block")
    var display_text = generate_display_text(p_typing_data, cursor_style)
    sample_label.text = display_text


func generate_display_text(p_typing_data: Dictionary, p_cursor_style: String) -> String:
    var display_text := ""
    var current_text: String = p_typing_data.get("current_text", "")
    var user_input: String = p_typing_data.get("user_input", "")
    var current_index: int = p_typing_data.get("current_index", 0)
    var mistakes: int = p_typing_data.get("mistakes", 0)
    
    for i in range(current_text.length()):
        if i < user_input.length():
            # Already typed characters
            if user_input[i] == current_text[i]:
                display_text += format_correct_character(current_text[i])
            else:
                display_text += format_incorrect_character(current_text[i])
        else:
            # Future characters
            if i == current_index:
                # Current cursor position
                display_text += format_cursor_character(current_text[i], p_cursor_style)
            else:
                # Not yet reached
                display_text += format_upcoming_character(current_text[i])
    
    return display_text


func format_correct_character(p_char: String) -> String:
    return "[color=green]%s[/color]" % p_char


func format_incorrect_character(p_char: String) -> String:
    return "[color=red]%s[/color]" % p_char


func format_upcoming_character(p_char: String) -> String:
    return p_char


func format_cursor_character(p_char: String, p_style: String) -> String:
    match p_style:
        "block":
            return format_block_cursor(p_char)
        "box":
            return format_box_cursor(p_char)
        "line":
            return format_line_cursor(p_char)
        "underline":
            return format_underline_cursor(p_char)
        _:
            return format_block_cursor(p_char)  # Default


func format_block_cursor(p_char: String) -> String:
    return "[bgcolor=%s][color=%s]%s[/color][/bgcolor]" % [
        CURSOR_COLORS.block.background,
        CURSOR_COLORS.block.text,
        p_char
    ]


func format_box_cursor(p_char: String) -> String:
    return "[border=%s][color=%s]%s[/color][/border]" % [
        CURSOR_COLORS.box.border,
        CURSOR_COLORS.box.text,
        p_char
    ]


func format_line_cursor(p_char: String) -> String:
    return "[u][color=%s]%s[/color][/u]" % [
        CURSOR_COLORS.line.text,
        p_char
    ]


func format_underline_cursor(p_char: String) -> String:
    return "[u][color=%s]%s[/color][/u]" % [
        CURSOR_COLORS.underline.text,
        p_char
    ]


func update_stats_display(p_stats: Dictionary, p_stats_label: Label) -> void:
    if p_stats_label:
        var wpm = p_stats.get("wpm", 0.0)
        var accuracy = p_stats.get("accuracy", 0.0)
        var mistakes = p_stats.get("mistakes", 0)
        
        p_stats_label.text = "WPM: %.1f | Accuracy: %.1f%% | Mistakes: %d" % [wpm, accuracy, mistakes]


# Visual feedback for typing events
func show_correct_feedback() -> void:
    # Could add animations or effects for correct typing
    pass


func show_incorrect_feedback() -> void:
    # Could add animations or effects for incorrect typing
    pass


# Apply theme settings to the display
func apply_theme_settings() -> void:
    if not sample_label:
        return
    
    var theme = UserConfigManager.get_setting("theme", "dark")
    var font_size = UserConfigManager.get_setting("font_size", 24)
    
    # Apply theme-based styling
    match theme:
        "dark":
            sample_label.add_theme_color_override("default_color", Color.WHITE)
        "light":
            sample_label.add_theme_color_override("default_color", Color.BLACK)
        "high_contrast":
            sample_label.add_theme_color_override("default_color", Color.YELLOW)
    
    # Apply font size
    sample_label.add_theme_font_size_override("normal_font_size", font_size)
