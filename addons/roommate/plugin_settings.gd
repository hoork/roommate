# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted

const SETTINGS_PATH_TEMPLATE := "roommate/%s/%s"
const _DEFAULTS := preload("./defaults/default_settings.tres")


static func get_bool(setting_id: StringName) -> bool:
	return get_or_default(setting_id) as bool


static func get_float(setting_id: StringName) -> float:
	return get_or_default(setting_id) as float


static func get_string_name(setting_id: StringName) -> StringName:
	return get_or_default(setting_id) as StringName


static func get_string(setting_id: StringName) -> String:
	return get_or_default(setting_id) as String


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
	if not settind_id.begins_with("stid_"):
		push_error("ROOMMATE: Setting Id must start with stid_ prefix. Received '%s'." % settind_id)
	var category := _DEFAULTS.categories.get(settind_id, "misc") as String
	return SETTINGS_PATH_TEMPLATE % [category, settind_id.trim_prefix("stid_")]


static func init_settings(editor_settings: EditorSettings) -> void:
	for setting_id in _DEFAULTS.shortcuts:
		var shortcut_path := _get_path(setting_id)
		var default_shortcut := Shortcut.new()
		default_shortcut.events = [_DEFAULTS.shortcuts[setting_id].duplicate() as InputEventKey]
		var create_shortcut := not editor_settings.has_setting(shortcut_path)
		if create_shortcut:
			editor_settings.set_setting(shortcut_path, default_shortcut)
		editor_settings.set_initial_value(shortcut_path, default_shortcut, false)
	
	for setting_id in _DEFAULTS.settings:
		var setting_path := _get_path(setting_id)
		var default_value: Variant = _DEFAULTS.settings[setting_id]
		if ProjectSettings.has_setting(setting_path):
			continue
		
		ProjectSettings.set_setting(setting_path, default_value)
		ProjectSettings.set_initial_value(setting_path, default_value)
		if _DEFAULTS.property_infos.has(setting_id):
			var info := _DEFAULTS.property_infos[setting_id].duplicate(true) as Dictionary
			info[&"name"] = setting_path
			ProjectSettings.add_property_info(info)


static func get_shortcut(setting_id: StringName, editor_settings: EditorSettings) -> Shortcut:
	var path := _get_path(setting_id)
	if not editor_settings.has_setting(path):
		push_error("ROOMMATE: Editor setting %s doesn't exist." % path)
		var default_shortcut := Shortcut.new()
		default_shortcut.events = [_DEFAULTS.shortcuts[setting_id].duplicate() as InputEventKey]
		return default_shortcut
	var shortcut := editor_settings.get_setting(path) as Shortcut
	if not shortcut:
		push_error("ROOMMATE: Wrong type of editor setting %s. Shortcut expected." % path)
		return null
	return shortcut


static func clear(editor_settings: EditorSettings) -> void:
	for setting_id in _DEFAULTS.settings:
		var setting_path := _get_path(setting_id)
		ProjectSettings.set_setting(setting_path, null)
	for shortcut_id in _DEFAULTS.shortcuts:
		var shortcut_path := _get_path(shortcut_id)
		editor_settings.erase(shortcut_path)
