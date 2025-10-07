extends Control

@export var _username_lbl: LineEdit


func _ready() -> void:
	AppManager.app_initialized.connect(_set_username)
	UserService.profile_loaded.connect(_set_username)
	UserService.profile_saved.connect(_set_username)


func _set_username() -> void:
	_username_lbl.text = UserService.get_profile().get("username")


func on_save_button() -> void:
	UserService.set_username(_username_lbl.text)
	UserService.save_profile()
