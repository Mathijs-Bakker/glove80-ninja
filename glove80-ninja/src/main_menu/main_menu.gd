extends Control

@export var _username: Label

@export var _user_profile_scn: PackedScene
@export var _stats_scn: PackedScene
@export var _settings_scn: PackedScene
@export var _layouts_scn: PackedScene

var _user_profile: Node
var _stats: Node
var _settings: Node
var _layouts: Node


func _ready() -> void:
	if not AppManager.app_initialized.is_connected(get_username):
		AppManager.app_initialized.connect(get_username)
	if not UserService.profile_loaded.is_connected(get_username):
		UserService.profile_loaded.connect(get_username)
	if not UserService.profile_saved.is_connected(get_username):
		UserService.profile_saved.connect(get_username)

	_user_profile = _user_profile_scn.instantiate()
	add_child(_user_profile)
	_user_profile.hide()

	_stats = _stats_scn.instantiate()
	add_child(_stats)
	_stats.hide()

	_settings = _settings_scn.instantiate()
	_settings.initialize(ConfigService)
	add_child(_settings)
	_settings.hide()

	_layouts = _layouts_scn.instantiate()
	add_child(_layouts)
	_layouts.hide()

	if AppManager.is_initialized():
		get_username()


func get_username() -> void:
	var username = UserService.get_profile().get(User.PROFILE.USERNAME)
	var dict = UserService.get_profile()

	if username == null:
		Log.Error("[main menu][get_username] Error fetching username")
	else:
		_username.text = username
		for key_value in dict:  # shorthand
			print(key_value, ":", dict[key_value])


func on_user_profile_btn() -> void:
	_user_profile.show()
	_stats.hide()
	_settings.hide()
	_layouts.hide()


func on_practice_btn() -> void:
	_user_profile.hide()
	_stats.hide()
	_settings.hide()
	_layouts.hide()


func on_stats_btn() -> void:
	_user_profile.hide()
	_stats.show()
	_settings.hide()
	_layouts.hide()


func on_setting_btn() -> void:
	_user_profile.hide()
	_stats.hide()
	_settings.show()
	_layouts.hide()


func on_layouts_btn() -> void:
	_user_profile.hide()
	_stats.hide()
	_settings.hide()
	_layouts.show()
