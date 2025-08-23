extends Control

# Text samples for typing practice
var text_samples = [
	"The quick brown fox jumps over the lazy dog.",
	"Programming is the process of creating a set of instructions that tell a computer how to perform a task.",
	"Touch typing is typing without using the sense of sight to find the keys.",
	"Practice makes perfect. The more you type, the better you will become.",
	"A good programmer is someone who looks both ways before crossing a one-way street."
]

# Current practice text
var current_text = ""
var user_input = ""
var current_char_index = 0
var start_time = 0
var elapsed_time = 0
var mistakes = 0
var is_typing = false
var last_wpm_update_time = 0
var current_wpm = 0.0
var last_activity_time = 0

# Nodes
@onready var sample_label: RichTextLabel = $VBoxContainer/CenterContainer/SampleLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var timer: Timer = $Timer
@onready var background: ColorRect = $Background
@onready var idle_timer: Timer = $IdleTimer
@onready var settings_btn: Button = $SettingsBtn

# Config manager reference
@onready var config_manager = get_node("/root/ConfigManager")

# Scene references
var settings_scene: Control

func _ready():
	# Load settings scene
	settings_scene = preload("res://scenes/settings/settings.tscn").instantiate()
	add_child(settings_scene)
	settings_scene.hide()
	
	settings_btn.pressed.connect(open_settings)
	
	setup_background()
	configure_richtext_labels()
	setup_timers()
	load_new_sample()
	update_display()
	
	# Apply saved cursor style
	apply_cursor_style()

func configure_richtext_labels():
	if sample_label:
		sample_label.scroll_active = false
		sample_label.fit_content = true
		sample_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sample_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var center_container = sample_label.get_parent()
		if center_container is CenterContainer:
			center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		sample_label.add_theme_font_size_override("normal_font_size", 24)
		sample_label.add_theme_constant_override("margin_left", 30)
		sample_label.add_theme_constant_override("margin_right", 30)

func setup_timers():
	timer.wait_time = 0.1
	timer.timeout.connect(_on_timer_timeout)
	
	idle_timer.wait_time = 10.0
	idle_timer.timeout.connect(_on_idle_timer_timeout)
	idle_timer.one_shot = true

func setup_background():
	if background:
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.color = Color(0.1, 0.1, 0.1)

func open_settings():
	settings_scene.show()

func apply_cursor_style():
	if config_manager:
		var cursor_style = config_manager.get_setting("cursor_style", "block")
		update_cursor_visuals(cursor_style)

func update_cursor_visuals(style):
	# This will update how the cursor is displayed
	print("Applying cursor style: ", style)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		# Handle ESC key for settings
		if event.keycode == KEY_ESCAPE:
			if settings_scene and settings_scene.visible:
				settings_scene.hide()
			else:
				open_settings()
			return  # Don't process ESC as typing input
		
		# Reset idle timer on any keypress
		reset_idle_timer()
		
		if not is_typing:
			start_typing()
		
		# Handle backspace
		if event.keycode == KEY_BACKSPACE:
			if user_input.length() > 0:
				user_input = user_input.substr(0, user_input.length() - 1)
				current_char_index = max(0, current_char_index - 1)
		# Handle regular characters
		elif event.unicode > 31 and event.unicode != 127:
			var typed_char = char(event.unicode)
			user_input += typed_char
			
			if current_char_index < current_text.length():
				if typed_char != current_text[current_char_index]:
					mistakes += 1
				current_char_index += 1
			
			# UPDATE WPM AFTER EACH CHARACTER TYPED
			update_wpm_after_character()
			
			# Check if completed
			if current_char_index >= current_text.length():
				finish_typing()
		
		update_display()

func reset_idle_timer():
	last_activity_time = Time.get_ticks_msec()
	if idle_timer.is_stopped():
		idle_timer.start()
	else:
		idle_timer.start(idle_timer.wait_time)

func update_wpm_after_character():
	if user_input.length() > 0:
		var current_time = Time.get_ticks_msec()
		var time_since_start = (current_time - start_time) / 1000.0
		current_wpm = calculate_wpm(user_input.length(), time_since_start)
		last_wpm_update_time = current_time

func start_typing():
	is_typing = true
	start_time = Time.get_ticks_msec()
	last_wpm_update_time = start_time
	last_activity_time = start_time
	current_wpm = 0.0
	timer.start()
	idle_timer.start()

func finish_typing():
	is_typing = false
	elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0
	timer.stop()
	idle_timer.stop()
	
	current_wpm = calculate_wpm(user_input.length(), elapsed_time)
	show_results()
	
	await get_tree().create_timer(2.0).timeout
	load_new_sample()
	update_display()

func load_new_sample():
	current_text = text_samples.pick_random()
	user_input = ""
	current_char_index = 0
	mistakes = 0
	is_typing = false
	current_wpm = 0.0
	idle_timer.stop()

func reset_on_idle():
	if is_typing and user_input.length() > 0:
		print("Resetting due to inactivity...")
		load_new_sample()
		update_display()

func update_display():
	if not sample_label:
		return
		
	var display_text = ""
	var cursor_style = "block"
	if config_manager:
		cursor_style = config_manager.get_setting("cursor_style", "block")
	
	for i in range(current_text.length()):
		if i < user_input.length():
			if user_input[i] == current_text[i]:
				display_text += "[color=green]" + current_text[i] + "[/color]"
			else:
				display_text += "[color=red]" + current_text[i] + "[/color]"
		else:
			if i == user_input.length():
				# Apply different formatting based on cursor style
				match cursor_style:
					"block":
						display_text += "[bgcolor=#555555][color=white]" + current_text[i] + "[/color][/bgcolor]"
					"box":
						display_text += "[border=2][color=#FF9900]" + current_text[i] + "[/color][/border]"
					"line":
						display_text += "[u][color=#FF9900]" + current_text[i] + "[/color][/u]"
					"underline":
						display_text += "[u][color=white]" + current_text[i] + "[/color][/u]"
					_:
						display_text += "[bgcolor=#444444][u]" + current_text[i] + "[/u][/bgcolor]"
			else:
				display_text += current_text[i]
	
	sample_label.text = display_text
	
	if is_typing and stats_label:
		var accuracy = calculate_accuracy()
		stats_label.text = "WPM: %.1f | Accuracy: %.1f%% | Mistakes: %d" % [current_wpm, accuracy, mistakes]

func calculate_wpm(chars_typed: int, time_seconds: float) -> float:
	if time_seconds == 0:
		return 0.0
	var words = chars_typed / 5.0
	var minutes = time_seconds / 60.0
	if minutes <= 0:
		return 0.0
	var wpm = words / minutes
	if wpm > 200:
		wpm = 200.0
	return wpm

func calculate_accuracy() -> float:
	if user_input.length() == 0:
		return 100.0
	var correct_chars = 0
	for i in range(min(user_input.length(), current_text.length())):
		if user_input[i] == current_text[i]:
			correct_chars += 1
	return (correct_chars / float(user_input.length())) * 100

func show_results():
	if stats_label:
		var accuracy = calculate_accuracy()
		stats_label.text = "Completed! WPM: %.1f | Accuracy: %.1f%% | Time: %.1fs" % [current_wpm, accuracy, elapsed_time]

func _on_timer_timeout():
	update_display()

func _on_idle_timer_timeout():
	reset_on_idle()
