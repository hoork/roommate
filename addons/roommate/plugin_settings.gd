# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted

const _DEFAULTS := preload("./defaults/default_setting_values.tres")

var _editor_settings: EditorSettings


static func get_bool(setting_id: StringName) -> bool:
	return get_or_default(setting_id) as bool


static func get_float(setting_id: StringName) -> float:
	return get_or_default(setting_id) as float


static func get_string(setting_id: StringName) -> StringName:
	return get_or_default(setting_id) as StringName


static func get_or_default(setting_id: StringName) -> Variant:
	var path := _get_path(setting_id)
	var default_value: Variant = _DEFAULTS.settings[setting_id]
	if not ProjectSettings.has_setting(path):
		if Engine.is_editor_hint():
			push_error("ROOMMATE: Project setting %s doesn't exists." % path)
		return default_value
	var value := ProjectSettings.get_setting_with_override(path)
	if typeof(value) != typeof(default_value):
		push_error("ROOMMATE: Wrong type of project setting %s. Type %d expected." % [path, typeof(default_value)])
		return default_value
	return value


static func _get_path(settind_id: StringName) -> String:
	const SETTINGS_PATH_TEMPLATE := "plugins/roommate/%s"
	
	if not settind_id.begins_with("stid_"):
		push_error("ROOMMATE: Setting Id must start with stid_ prefix. Received '%s'." % settind_id)
	return SETTINGS_PATH_TEMPLATE % settind_id.trim_prefix("stid_")


func _init(plugin: EditorPlugin) -> void:
	_editor_settings = plugin.get_editor_interface().get_editor_settings()


func init_settings() -> void:
	clear()
	for setting_id in _DEFAULTS.shortcuts:
		var shortcut_path := _get_path(setting_id)
		var default_shortcut := Shortcut.new()
		default_shortcut.events = [_DEFAULTS.shortcuts[setting_id].duplicate() as InputEventKey]
		var create_shortcut := not _editor_settings.has_setting(shortcut_path)
		if create_shortcut:
			_editor_settings.set_setting(shortcut_path, default_shortcut)
		_editor_settings.set_initial_value(shortcut_path, default_shortcut, false)
	
	for setting_id in _DEFAULTS.settings:
		var setting_path := _get_path(setting_id)
		var default_value: Variant = _DEFAULTS.settings[setting_id]
		if ProjectSettings.has_setting(setting_path):
			continue
		ProjectSettings.set_setting(setting_path, default_value)
		ProjectSettings.set_initial_value(setting_path, default_value)


func get_shortcut(setting_id: StringName) -> Shortcut:
	var path := _get_path(setting_id)
	if not _editor_settings.has_setting(path):
		push_error("ROOMMATE: Editor setting %s doesn't exist." % path)
		var default_shortcut := Shortcut.new()
		default_shortcut.events = [_DEFAULTS.shortcuts[setting_id].duplicate() as InputEventKey]
		return default_shortcut
	var shortcut := _editor_settings.get_setting(path) as Shortcut
	if not shortcut:
		push_error("ROOMMATE: Wrong type of editor setting %s. Shortcut expected." % path)
		return null
	return shortcut


func clear() -> void:
	for setting_id in _DEFAULTS.settings:
		var setting_path := _get_path(setting_id)
		ProjectSettings.set_setting(setting_path, null)
	for shortcut_id in _DEFAULTS.shortcuts:
		var shortcut_path := _get_path(shortcut_id)
		_editor_settings.erase(shortcut_path)
