extends Node

const SettingsSave = preload("res://src/SettingsSave.gd")
const save_path = "user://settings.tres"

var _settings: SettingsSave

func get_settings() -> SettingsSave:
	if _settings == null:
		_setup_settings()
				
	return _settings

func _setup_settings():
	if _does_settings_save_exist():
		_settings = _load_settings()
	else:
		_settings = _create_default_settings()
	_settings.connect("settings_changed", self, "_on_settings_changed")

func _on_settings_changed(_setting_name: String):
	_save_settings()
	
func _does_settings_save_exist() -> bool:
	return Directory.new().file_exists(save_path)

func _create_default_settings() -> SettingsSave:
	return SettingsSave.new()

func _load_settings() -> SettingsSave:
	var save: SettingsSave = ResourceLoader.load(save_path)
	return save

func _save_settings() -> void:
	ResourceSaver.save(save_path, _settings)
