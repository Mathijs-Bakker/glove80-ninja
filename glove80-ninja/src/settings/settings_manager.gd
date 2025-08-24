extends Node

@onready var settings_btn: Button = $SettingsBtn
@onready var config_manager = get_node("/root/ConfigManager")

var settings_scene: Control

func _ready():
	settings_scene = preload("res://src/settings/settings.tscn").instantiate()
	get_parent().add_child(settings_scene)
	settings_scene.hide()
	settings_btn.pressed.connect(open_settings)

func open_settings() -> void:
	settings_scene.show()

func close_settings() -> void:
	settings_scene.hide()

func handle_settings_input(event: InputEventKey) -> bool:
	if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		if settings_scene.visible:
			close_settings()
			return true
		else:
			open_settings()
			return true
	return false
