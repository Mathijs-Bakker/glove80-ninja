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
	Log.info("[Main][_ready] Main scene ready, initializing UI and app")
	_setup_ui()
	_initialize_app()


## Initialize the application
func _initialize_app() -> void:
	Log.info("[Main][_initialize_app] Starting application initialization")
	_show_loading_screen("Initializing application...")

	# Create and initialize AppManager
	Log.info("[Main][_initialize_app] Creating AppManager")
	app_manager = AppManager.new()
	app_manager.name = "AppManager"
	add_child(app_manager)
	app_manager.add_to_group("app_manager")

	# Connect AppManager signals
	app_manager.app_initialized.connect(_on_app_initialized)
	app_manager.services_ready.connect(_on_services_ready)
	app_manager.app_shutting_down.connect(_on_app_shutting_down)
	Log.info("[Main][_initialize_app] AppManager signals connected")

	# Wait for initialization
	Log.info("[Main][_initialize_app] Waiting for AppManager initialization")
	await app_manager.app_initialized

	_hide_loading_screen()
	_setup_initial_scene()
	Log.info("[Main][_initialize_app] Application initialization complete")


## Get the AppManager instance (for static access)
func get_app_manager() -> AppManager:
	Log.info("[Main][get_app_manager] Returning AppManager instance")
	return app_manager


## Navigate to practice scene
func navigate_to_practice() -> void:
	Log.info("[Main][navigate_to_practice] Navigating to practice scene")
	if is_loading or current_scene == "practice":
		Log.info("[Main][navigate_to_practice] Already loading or in practice scene, skipping")
		return

	_show_loading_screen("Loading practice session...")
	_load_scene("practice")
	_hide_loading_screen()
	Log.info("[Main][navigate_to_practice] Navigation to practice complete")


## Navigate to settings scene
func navigate_to_settings() -> void:
	Log.info("[Main][navigate_to_settings] Navigating to settings scene")
	if is_loading or current_scene == "settings":
		Log.info("[Main][navigate_to_settings] Already loading or in settings scene, skipping")
		return

	_show_loading_screen("Loading settings...")
	_load_scene("settings")
	_hide_loading_screen()
	Log.info("[Main][navigate_to_settings] Navigation to settings complete")


## Navigate to profile scene
func navigate_to_profile() -> void:
	Log.info("[Main][navigate_to_profile] Navigating to profile scene")
	if is_loading or current_scene == "profile":
		Log.info("[Main][navigate_to_profile] Already loading or in profile scene, skipping")
		return

	_show_loading_screen("Loading profile...")
	_load_scene("profile")
	_hide_loading_screen()
	Log.info("[Main][navigate_to_profile] Navigation to profile complete")


## Handle application exit
func quit_application() -> void:
	Log.info("[Main][quit_application] Application quit requested")
	_show_loading_screen("Saving and closing...")

	if app_manager:
		Log.info("[Main][quit_application] Shutting down AppManager")
		app_manager.shutdown_app()
		await app_manager.app_shutting_down
		Log.info("[Main][quit_application] AppManager shutdown complete")

	Log.info("[Main][quit_application] Exiting application")
	get_tree().quit()


# Private methods

func _setup_ui() -> void:
	Log.info("[Main][_setup_ui] Setting up UI components")

	# Connect navigation buttons
	if practice_button:
		practice_button.pressed.connect(navigate_to_practice)
		Log.info("[Main][_setup_ui] Practice button connected")

	if settings_button:
		settings_button.pressed.connect(navigate_to_settings)
		Log.info("[Main][_setup_ui] Settings button connected")

	if profile_button:
		profile_button.pressed.connect(navigate_to_profile)
		Log.info("[Main][_setup_ui] Profile button connected")

	# Set initial UI state
	_update_ui_state()

	# Handle quit requests - Godot 4 compatibility
	get_tree().set_auto_accept_quit(false)
	get_viewport().close_requested.connect(quit_application)
	Log.info("[Main][_setup_ui] Quit handling configured")

	Log.info("[Main][_setup_ui] UI setup complete")


func _setup_initial_scene() -> void:
	Log.info("[Main][_setup_initial_scene] Setting up initial scene")
	# Start with the practice scene by default
	navigate_to_practice()
	scene_ready.emit()
	Log.info("[Main][_setup_initial_scene] Initial scene setup complete")


func _load_scene(p_scene_name: String) -> void:
	Log.info("[Main][_load_scene] Loading scene: %s" % p_scene_name)
	current_scene = p_scene_name

	# Remove current controller if exists
	if current_controller:
		Log.info("[Main][_load_scene] Removing existing controller")
		current_controller.queue_free()
		current_controller = null

	# Create new controller based on scene name
	match p_scene_name:
		"practice":
			Log.info("[Main][_load_scene] Creating practice controller")
			current_controller = app_manager.create_practice_controller()
			if current_controller:
				current_controller.settings_requested.connect(navigate_to_settings)
				Log.info("[Main][_load_scene] Practice controller created and connected")

		"settings":
			Log.info("[Main][_load_scene] Creating settings controller")
			current_controller = app_manager.create_settings_controller()
			if current_controller:
				current_controller.settings_closed.connect(navigate_to_practice)
				Log.info("[Main][_load_scene] Settings controller created and connected")

		"profile":
			Log.info("[Main][_load_scene] Creating profile controller")
			current_controller = _create_profile_controller()

		_:
			Log.error("[Main][_load_scene] Unknown scene name: %s" % p_scene_name)

	# Add controller to scene
	if current_controller:
		content_container.add_child(current_controller)
		_update_navigation_state()
		_update_status("Ready")
		Log.info("[Main][_load_scene] Controller added to scene successfully")
	else:
		Log.error("[Main][_load_scene] Failed to create controller for scene: %s" % p_scene_name)
		_update_status("Failed to load " + p_scene_name)


func _create_profile_controller() -> Control:
	Log.info("[Main][_create_profile_controller] Creating placeholder profile controller")
	# Placeholder for profile controller - create a simple label for now
	var label = Label.new()
	label.text = "Profile View\n(Coming Soon)\n\nThis will show:\n• User Statistics\n• Achievements\n• Progress History"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Add some basic styling
	label.add_theme_font_size_override("font_size", 18)

	Log.info("[Main][_create_profile_controller] Profile controller placeholder created")
	return label


func _show_loading_screen(p_message: String) -> void:
	Log.info("[Main][_show_loading_screen] Showing loading screen: %s" % p_message)
	is_loading = true
	loading_label.text = p_message
	loading_overlay.visible = true
	progress_bar.value = 0

	# Animate progress bar
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100, 0.5)


func _hide_loading_screen() -> void:
	Log.info("[Main][_hide_loading_screen] Hiding loading screen")
	is_loading = false
	loading_overlay.visible = false


func _update_ui_state() -> void:
	Log.info("[Main][_update_ui_state] Updating UI state")
	# Update version label
	if version_label and app_manager:
		var config = app_manager.get_config_service()
		if config:
			var version = config.get_setting("app_version", "1.0.0")
			version_label.text = "v" + version
			Log.info("[Main][_update_ui_state] Version label updated to: v%s" % version)


func _update_navigation_state() -> void:
	Log.info("[Main][_update_navigation_state] Updating navigation state for scene: %s" % current_scene)
	# Update button states based on current scene
	if practice_button:
		practice_button.disabled = (current_scene == "practice")

	if settings_button:
		settings_button.disabled = (current_scene == "settings")

	if profile_button:
		profile_button.disabled = (current_scene == "profile")

	Log.info("[Main][_update_navigation_state] Navigation buttons updated")


func _update_status(p_message: String) -> void:
	Log.info("[Main][_update_status] Updating status: %s" % p_message)
	if status_label:
		status_label.text = p_message


# Signal handlers

func _on_app_initialized() -> void:
	Log.info("[Main][_on_app_initialized] Application initialized successfully")
	_update_ui_state()


func _on_services_ready() -> void:
	Log.info("[Main][_on_services_ready] All services are ready")
	_update_status("Services ready")


func _on_app_shutting_down() -> void:
	Log.info("[Main][_on_app_shutting_down] Application shutting down")
	_update_status("Shutting down...")


# Input handling

func _input(p_event: InputEvent) -> void:
	if not p_event is InputEventKey:
		return

	var key_event = p_event as InputEventKey
	if not key_event.pressed:
		return

	# Handle global shortcuts
	match key_event.keycode:
		KEY_F1:
			Log.info("[Main][_input] F1 pressed, navigating to practice")
			navigate_to_practice()
		KEY_F2:
			Log.info("[Main][_input] F2 pressed, navigating to settings")
			navigate_to_settings()
		KEY_F3:
			Log.info("[Main][_input] F3 pressed, navigating to profile")
			navigate_to_profile()
		KEY_ESCAPE:
			if current_scene == "settings":
				Log.info("[Main][_input] Escape pressed in settings, returning to practice")
				navigate_to_practice()
		KEY_Q:
			if key_event.ctrl_pressed:
				Log.info("[Main][_input] Ctrl+Q pressed, quitting application")
				quit_application()
