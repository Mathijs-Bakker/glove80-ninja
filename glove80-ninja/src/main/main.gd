extends Control
class_name Main

## Refactored main scene that uses the new architecture
## Uses AppManager for service management and proper dependency injection

signal scene_ready()

# Core components
var app_manager: AppManager
var current_controller: Control
var loading_screen: Control

# UI References
@onready var main_container: Control = $MainContainer
@onready var header_container: HBoxContainer = $MainContainer/HeaderContainer
@onready var content_container: Control = $MainContainer/ContentContainer
@onready var footer_container: HBoxContainer = $MainContainer/FooterContainer

# Navigation buttons
@onready var practice_button: Button = $MainContainer/HeaderContainer/NavigationContainer/PracticeButton
@onready var settings_button: Button = $MainContainer/HeaderContainer/NavigationContainer/SettingsButton
@onready var profile_button: Button = $MainContainer/HeaderContainer/NavigationContainer/ProfileButton

# Status display
@onready var status_label: Label = $MainContainer/FooterContainer/StatusLabel
@onready var version_label: Label = $MainContainer/FooterContainer/VersionLabel

# Loading overlay
@onready var loading_overlay: ColorRect = $LoadingOverlay
@onready var loading_label: Label = $LoadingOverlay/VBoxContainer/LoadingLabel
@onready var progress_bar: ProgressBar = $LoadingOverlay/VBoxContainer/ProgressBar

# Current scene state
var current_scene: String = ""
var is_loading: bool = false


func _ready() -> void:
	_setup_ui()
	_initialize_app()


## Initialize the application
func _initialize_app() -> void:
	_show_loading_screen("Initializing application...")

	# Create and initialize AppManager
	app_manager = AppManager.new()
	app_manager.name = "AppManager"
	add_child(app_manager)
	app_manager.add_to_group("app_manager")

	# Connect AppManager signals
	app_manager.app_initialized.connect(_on_app_initialized)
	app_manager.services_ready.connect(_on_services_ready)
	app_manager.app_shutting_down.connect(_on_app_shutting_down)

	# Wait for initialization
	await app_manager.app_initialized

	_hide_loading_screen()
	_setup_initial_scene()


## Get the AppManager instance (for static access)
func get_app_manager() -> AppManager:
	return app_manager


## Navigate to practice scene
func navigate_to_practice() -> void:
	if is_loading or current_scene == "practice":
		return

	_show_loading_screen("Loading practice session...")
	_load_scene("practice")
	_hide_loading_screen()


## Navigate to settings scene
func navigate_to_settings() -> void:
	if is_loading or current_scene == "settings":
		return

	_show_loading_screen("Loading settings...")
	_load_scene("settings")
	_hide_loading_screen()


## Navigate to profile scene
func navigate_to_profile() -> void:
	if is_loading or current_scene == "profile":
		return

	_show_loading_screen("Loading profile...")
	_load_scene("profile")
	_hide_loading_screen()


## Handle application exit
func quit_application() -> void:
	_show_loading_screen("Saving and closing...")

	if app_manager:
		app_manager.shutdown_app()
		await app_manager.app_shutting_down

	get_tree().quit()


# Private methods

func _setup_ui() -> void:
	# Connect navigation buttons
	if practice_button:
		practice_button.pressed.connect(navigate_to_practice)

	if settings_button:
		settings_button.pressed.connect(navigate_to_settings)

	if profile_button:
		profile_button.pressed.connect(navigate_to_profile)

	# Set initial UI state
	_update_ui_state()

	# Handle quit requests - Godot 4 compatibility
	get_tree().set_auto_accept_quit(false)
	get_viewport().close_requested.connect(quit_application)


func _setup_initial_scene() -> void:
	# Start with the practice scene by default
	navigate_to_practice()
	scene_ready.emit()


func _load_scene(scene_name: String) -> void:
	current_scene = scene_name

	# Remove current controller if exists
	if current_controller:
		current_controller.queue_free()
		current_controller = null

	# Create new controller based on scene name
	match scene_name:
		"practice":
			current_controller = app_manager.create_practice_controller()
			if current_controller:
				current_controller.settings_requested.connect(navigate_to_settings)

		"settings":
			current_controller = app_manager.create_settings_controller()
			if current_controller:
				current_controller.settings_closed.connect(navigate_to_practice)

		"profile":
			current_controller = _create_profile_controller()

	# Add controller to scene
	if current_controller:
		content_container.add_child(current_controller)
		_update_navigation_state()
		_update_status("Ready")
	else:
		_update_status("Failed to load " + scene_name)


func _create_profile_controller() -> Control:
	# Placeholder for profile controller - create a simple label for now
	var label = Label.new()
	label.text = "Profile View\n(Coming Soon)\n\nThis will show:\n• User Statistics\n• Achievements\n• Progress History"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Add some basic styling
	label.add_theme_font_size_override("font_size", 18)

	return label


func _show_loading_screen(message: String) -> void:
	is_loading = true
	loading_label.text = message
	loading_overlay.visible = true
	progress_bar.value = 0

	# Animate progress bar
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100, 0.5)


func _hide_loading_screen() -> void:
	is_loading = false
	loading_overlay.visible = false


func _update_ui_state() -> void:
	# Update version label
	if version_label and app_manager:
		var config = app_manager.get_config_service()
		if config:
			var version = config.get_setting("app_version", "1.0.0")
			version_label.text = "v" + version


func _update_navigation_state() -> void:
	# Update button states based on current scene
	if practice_button:
		practice_button.disabled = (current_scene == "practice")

	if settings_button:
		settings_button.disabled = (current_scene == "settings")

	if profile_button:
		profile_button.disabled = (current_scene == "profile")


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = message
	print("Main: " + message)


# Signal handlers

func _on_app_initialized() -> void:
	print("Main: Application initialized successfully")
	_update_ui_state()


func _on_services_ready() -> void:
	print("Main: All services are ready")
	_update_status("Services ready")


func _on_app_shutting_down() -> void:
	print("Main: Application shutting down")
	_update_status("Shutting down...")


# Input handling

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event = event as InputEventKey
	if not key_event.pressed:
		return

	# Handle global shortcuts
	match key_event.keycode:
		KEY_F1:
			navigate_to_practice()
		KEY_F2:
			navigate_to_settings()
		KEY_F3:
			navigate_to_profile()
		KEY_ESCAPE:
			if current_scene == "settings":
				navigate_to_practice()
		KEY_Q:
			if key_event.ctrl_pressed:
				quit_application()
