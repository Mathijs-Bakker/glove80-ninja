extends Control
class_name TypingCursor

## Custom cursor node that supports various styles and animations


signal cursor_moved
signal cursor_style_changed

@export var character: String = "A":
	set(value):
		character = value
		queue_redraw()

@export var cursor_style: String = "block":
	set(value):
		cursor_style = value
		queue_redraw()
		cursor_style_changed.emit(value)

@export var is_active: bool = true:
	set(value):
		is_active = value
		queue_redraw()

@export var blink_rate: float = 0.5  # Blinks per second
var blink_timer: float = 0.0
var visible_state: bool = true

# Colors for different cursor styles
const CURSOR_COLORS = {
	"block": Color("#555555"),
	"box": Color("#FF9900"), 
	"line": Color("#FF9900"),
	"underline": Color("#FFFFFF")
}

# Font for character display
var font: Font


func _ready():
	font = get_theme_default_font()
	# Start blinking animation
	set_process(true)


func _process(delta):
	# Handle blinking animation
	blink_timer += delta
	if blink_timer >= blink_rate:
		blink_timer = 0.0
		visible_state = !visible_state
		queue_redraw()


func _draw():
	if not is_active or not visible_state:
		return
	
	var char_size = font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var cursor_pos = Vector2(0, 0)
	
	match cursor_style:
		"block":
			# Draw background block
			draw_rect(Rect2(cursor_pos, Vector2(char_size.x + 8, size.y)), CURSOR_COLORS.block)
			# Draw character
			draw_string(font, cursor_pos + Vector2(4, size.y - 4), character, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		
		"box":
			# Draw box border
			# draw_rect(Rect2(cursor_pos, Vector2(char_size.x + 8, size.y)), Color.TRANSPARENT, false, CURSOR_COLORS.box, 2)
			draw_rect(Rect2(cursor_pos, Vector2(char_size.x + 8, size.y)), Color.TRANSPARENT, false, 1.0)
			# Draw character
			draw_string(font, cursor_pos + Vector2(4, size.y - 4), character, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, CURSOR_COLORS.box)
		
		"line":
			# Draw vertical line on left side
			draw_line(cursor_pos, cursor_pos + Vector2(0, size.y), CURSOR_COLORS.line, 2)
			# Draw character
			draw_string(font, cursor_pos + Vector2(8, size.y - 4), character, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, CURSOR_COLORS.line)
		
		"underline":
			# Draw underline
			draw_line(cursor_pos + Vector2(0, size.y - 2), cursor_pos + Vector2(char_size.x + 8, size.y - 2), CURSOR_COLORS.underline, 2)
			# Draw character
			draw_string(font, cursor_pos + Vector2(4, size.y - 4), character, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


# Animation methods
func move_to(new_position: Vector2, animate: bool = true) -> void:
	if animate:
		# Animated movement
		var tween = create_tween()
		tween.tween_property(self, "position", new_position, 0.1)
		tween.tween_callback(_on_move_complete)
	else:
		# Instant movement
		position = new_position
		_on_move_complete()


func _on_move_complete() -> void:
	cursor_moved.emit()


func set_blink_rate(rate: float) -> void:
	blink_rate = rate


func set_active(active: bool) -> void:
	is_active = active
	visible_state = true
	blink_timer = 0.0
	queue_redraw()


# Visual feedback animations
func pulse() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)


func shake() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(-3, 0), 0.05)
	tween.tween_property(self, "position", position + Vector2(6, 0), 0.05)
	tween.tween_property(self, "position", position + Vector2(-3, 0), 0.05)


func highlight() -> void:
	var tween = create_tween()
	var original_modulate = modulate
	tween.tween_property(self, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(self, "modulate", original_modulate, 0.3)
