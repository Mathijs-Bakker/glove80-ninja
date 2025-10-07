class_name PracticeControllerRefactored
extends Control


signal exercise_started()
signal exercise_completed(results: Dictionary)
signal settings_requested()

# Configuration - Set which display type to use
const USE_RICH_TEXT_DISPLAY: bool = false  # Set to true to use RichTextDisplay

# Services
var config_service: ConfigService
var user_service: UserService

# Components
var text_display: Control  # Can be TextDisplay or RichTextDisplay
var input_handler: InputHandler
var session_manager: SessionManager

# UI References
@onready var settings_button: Button = $HeaderContainer/SettingsButton
@onready var restart_button: Button = $HeaderContainer/RestartButton
@onready var text_display_container: Control = $MainContainer/TextDisplayContainer
@onready var results_popup: AcceptDialog = $ResultsPopup
@onready var results_label: RichTextLabel = $ResultsPopup/VBoxContainer/ResultsLabel

# State
var current_exercise: TypingExercise
var is_active: bool = false

# Deferred initialization
var _pending_config_service: ConfigService
var _pending_user_service: UserService
var _initialization_pending: bool = false


func _ready() -> void:
	Log.info("[PracticeController][_ready] Ready called")
	_setup_ui()
	await get_tree().process_frame  # Wait for scene to be fully ready
	_setup_components()

	# If initialization was called before _ready, execute it now
	if _initialization_pending:
		_execute_initialization()

	Log.info("[PracticeController][_ready] Ready complete")


func _exit_tree() -> void:
	Log.info("[PracticeController][_exit_tree] Cleaning up resources")
	# Clean up session manager resources
	if session_manager:
		session_manager.cleanup()


## Initialize with required services
func initialize(p_config_service: ConfigService, p_user_service: UserService) -> void:
	Log.info("[PracticeController][initialize] Initialize called with services")
	_pending_config_service = p_config_service
	_pending_user_service = p_user_service
	_initialization_pending = true

	# If components are already set up, initialize immediately
	if text_display != null:
		Log.info("[PracticeController][initialize] Components ready, executing immediately")
		_execute_initialization()


## Execute the actual initialization after components are ready
func _execute_initialization() -> void:
	Log.info("[PracticeController][_execute_initialization] Executing initialization")
	config_service = _pending_config_service
	user_service = _pending_user_service
	_initialization_pending = false

	Log.info("[PracticeController][_execute_initialization] Services assigned - config: %s, user: %s" % [config_service != null, user_service != null])
	Log.info("[PracticeController][_execute_initialization] Component states - text_display: %s, input_handler: %s" % [text_display != null, input_handler != null])

	if text_display == null:
		Log.error("[PracticeController][_execute_initialization] TextDisplay component is null - components not set up properly")
		return

	_initialize_components()
	_connect_services()
	_start_new_exercise()


## Start a new typing exercise
func start_new_exercise() -> void:
	if not _can_start_exercise():
		return

	_start_new_exercise()


## Handle manual restart request
func restart_current_exercise() -> void:
	if current_exercise:
		_restart_exercise()


# Private methods

func _setup_ui() -> void:
	print("PracticeController: _setup_ui() called")
	print("PracticeController: settings_button exists: ", settings_button != null)
	print("PracticeController: restart_button exists: ", restart_button != null)
	print("PracticeController: text_display_container exists: ", text_display_container != null)

	if settings_button:
		settings_button.pressed.connect(_on_settings_requested)

	if restart_button:
		restart_button.pressed.connect(_on_restart_requested)


func _setup_components() -> void:
	Log.info("[PracticeController][_setup_components] Setting up components")

	# Create text display component based on configuration
	Log.info("[PracticeController][_setup_components] Loading display scene")
	var text_display_scene = null
	var scene_type = "Unknown"
	var scene_path = ""

	if USE_RICH_TEXT_DISPLAY:
		scene_path = "res://src/ui/components/rich_text_display.tscn"
		scene_type = "RichTextDisplay"
	else:
		scene_path = "res://src/ui/components/text_display.tscn"
		scene_type = "TextDisplay"

	text_display_scene = load(scene_path)
	if text_display_scene:
		Log.info("[PracticeController][_setup_components] %s scene loaded successfully" % scene_type)
		text_display = text_display_scene.instantiate()
		Log.info("[PracticeController][_setup_components] %s instantiated: %s" % [scene_type, text_display != null])

		if text_display_container:
			text_display_container.add_child(text_display)
			Log.info("[PracticeController][_setup_components] %s added to container" % scene_type)
		else:
			Log.error("[PracticeController][_setup_components] TextDisplayContainer not found in scene")
	else:
		Log.error("[PracticeController][_setup_components] Failed to load %s scene from %s" % [scene_type, scene_path])

	# Create input handler
	Log.info("[PracticeController][_setup_components] Creating InputHandler")
	input_handler = InputHandler.new()
	add_child(input_handler)
	Log.info("[PracticeController][_setup_components] InputHandler created: %s" % (input_handler != null))

	# Create session manager
	Log.info("[PracticeController][_setup_components] Creating SessionManager")
	session_manager = SessionManager.new()
	Log.info("[PracticeController][_setup_components] SessionManager created: %s" % (session_manager != null))


func _initialize_components() -> void:
	Log.info("[PracticeController][_initialize_components] Initializing components")

	# Initialize text display with config service
	if text_display:
		text_display.initialize("", config_service)
		Log.info("[PracticeController][_initialize_components] TextDisplay initialized")
	else:
		Log.error("[PracticeController][_initialize_components] TextDisplay component is null during initialization")

	# Initialize input handler
	if input_handler:
		input_handler.initialize()
		Log.info("[PracticeController][_initialize_components] InputHandler initialized")
	else:
		Log.error("[PracticeController][_initialize_components] InputHandler is null during initialization")

	# Initialize session manager with user service
	if session_manager:
		session_manager.initialize(user_service, self)
		Log.info("[PracticeController][_initialize_components] SessionManager initialized")
	else:
		Log.error("[PracticeController][_initialize_components] SessionManager is null during initialization")


func _connect_services() -> void:
	# Connect input handler signals
	input_handler.character_typed.connect(_on_character_typed)
	input_handler.input_completed.connect(_on_input_completed)
	input_handler.input_error.connect(_on_input_error)

	# Connect session manager signals
	session_manager.session_started.connect(_on_session_started)
	session_manager.session_completed.connect(_on_session_completed)
	session_manager.stats_updated.connect(_on_stats_updated)

	# Connect config changes
	if config_service:
		config_service.setting_changed.connect(_on_config_changed)


func _start_new_exercise() -> void:
	# Create new exercise
	current_exercise = TypingExercise.new()
	current_exercise.load_random_text()

	# Setup components for new exercise
	_safe_call_display_method("set_text", [current_exercise.get_text()])
	input_handler.set_target_text(current_exercise.get_text())
	session_manager.start_session()

	# Update state
	is_active = true
	_update_ui_state()

	exercise_started.emit()


func _restart_exercise() -> void:
	if current_exercise:
		# Reset exercise state
		current_exercise.reset()

		# Reset components
		_safe_call_display_method("set_text", [current_exercise.get_text()])
		input_handler.reset()
		session_manager.restart_session()

		# Update state
		is_active = true
		_update_ui_state()


func _complete_exercise() -> void:
	is_active = false

	# Get final results
	var exercise_results = current_exercise.get_results()
	var session_results = session_manager.complete_session(exercise_results)

	# Show results
	_show_results(session_results)

	# Emit completion signal
	exercise_completed.emit(session_results)

	# Schedule next exercise
	_schedule_next_exercise()


func _show_results(results: Dictionary) -> void:
	if not results_label or not results_popup:
		return

	var wpm = results.get("wpm", 0.0)
	var accuracy = results.get("accuracy", 0.0)
	var time = results.get("duration", 0.0)
	var mistakes = results.get("mistakes", 0)
	var characters = results.get("characters_typed", 0)

	var results_text = "[center][b]Exercise Complete![/b][/center]\n\n"
	results_text += "⚡ WPM: [b]%.1f[/b]\n" % wpm
	results_text += "🎯 Accuracy: [b]%.1f%%[/b]\n" % accuracy
	results_text += "⏱️ Time: [b]%.1fs[/b]\n" % time
	results_text += "❌ Mistakes: [b]%d[/b]\n" % mistakes
	results_text += "📝 Characters: [b]%d[/b]" % characters

	# Add achievement notifications if any
	var achievements = results.get("achievements_unlocked", [])
	if not achievements.is_empty():
		results_text += "\n\n🏆 [b]New Achievements![/b]\n"
		for achievement in achievements:
			results_text += "• %s\n" % achievement

	results_label.text = results_text
	results_popup.popup_centered()


func _schedule_next_exercise() -> void:
	# Wait a moment before starting next exercise
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		_start_new_exercise()


func _update_ui_state() -> void:
	if restart_button:
		restart_button.disabled = not is_active


func _can_start_exercise() -> bool:
	return config_service != null and user_service != null


# Signal handlers

func _on_character_typed(character: String, is_correct: bool, char_position: int) -> void:
	if not is_active or not current_exercise:
		return

	# Update exercise with typed character
	current_exercise.process_character(character, is_correct, char_position)

	# Update display
	var progress_data = current_exercise.get_progress_data()
	_safe_call_display_method("update_progress", [
		progress_data.user_input,
		progress_data.current_index,
		progress_data.mistakes
	])

	# Show visual feedback
	if is_correct:
		_safe_call_display_method("show_correct_feedback")
	else:
		_safe_call_display_method("show_incorrect_feedback")


func _on_input_completed() -> void:
	if is_active:
		_complete_exercise()


func _on_input_error(error_type: String, details: Dictionary) -> void:
	# Handle input errors (like invalid characters, etc.)
	print("Input error: %s - %s" % [error_type, details])


func _on_session_started() -> void:
	print("Typing session started")


func _on_session_completed(results: Dictionary) -> void:
	print("Session completed with results: ", results)


func _on_stats_updated(stats: Dictionary) -> void:
	if text_display:
		_safe_call_display_method("update_stats", [
			stats.get("wpm", 0.0),
			stats.get("accuracy", 100.0),
			stats.get("mistakes", 0)
		])


func _on_settings_requested() -> void:
	settings_requested.emit()


func _on_restart_requested() -> void:
	restart_current_exercise()


func _on_config_changed(setting_name: String, _new_value) -> void:
	# Propagate config changes to components
	match setting_name:
		"theme", "font_size", "cursor_style":
			if text_display:
				_safe_call_display_method("apply_theme_settings")


# Helper methods to work with both TextDisplay and RichTextDisplay

func _safe_call_display_method(method_name: String, args: Array = []):
	"""Safely call methods on text_display regardless of type"""
	if text_display and text_display.has_method(method_name):
		if args.is_empty():
			text_display.call(method_name)
		else:
			text_display.callv(method_name, args)

func _is_rich_text_display() -> bool:
	"""Check if current display is RichTextDisplay"""
	return text_display != null and text_display.get_script() != null and text_display.get_script().get_global_name() == "RichTextDisplay"


# Input handling

func _input(event: InputEvent) -> void:
	if not is_active or not input_handler:
		return

	# Delegate input handling to input handler component
	input_handler.handle_input(event)
