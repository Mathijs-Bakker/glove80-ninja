extends Control

@export var _username: Label

@export var _practice_btn: Button
@export var _profile_btn: Button
@export var _settings_btn: Button
@export var _layouts_btn: Button

@export var _profile_scn: PackedScene
@export var _settings_scn: PackedScene
@export var _layouts_scn: PackedScene

var _profile: Node
var _settings: Node
var _layouts: Node


func _ready() -> void:
	AppManager.app_initialized.connect(get_username)
	UserService.profile_loaded.connect(get_username)
	UserService.profile_saved.connect(get_username)

	_profile = _profile_scn.instantiate()
	add_child(_profile)
	_profile.hide()

	_settings = _settings_scn.instantiate()
	add_child(_settings)
	_settings.hide()

	_layouts = _layouts_scn.instantiate()
	add_child(_layouts)
	_layouts.hide()


func get_username() -> void:
	var username = UserService.get_profile().get("username")
	var dict = UserService.get_profile()

	if username == null:
		Log.Error("[main menu][get_username] Error fetching username")
	else:
		_username.text = username
		for key_value in dict:  # shorthand
			print(key_value, ":", dict[key_value])


func on_practice_btn() -> void:
	_profile.hide()
	_settings.hide()
	_layouts.hide()


func on_profile_btn() -> void:
	_profile.show()
	_settings.hide()
	_layouts.hide()


func on_setting_btn() -> void:
	_profile.hide()
	_settings.show()
	_layouts.hide()


func on_layouts_btn() -> void:
	_profile.hide()
	_settings.hide()
	_layouts.show()
