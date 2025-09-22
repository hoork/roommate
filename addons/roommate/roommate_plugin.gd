# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends EditorPlugin

const _SETTINGS := preload("./plugin_settings.gd")
const _GIZMO_PLUGIN := preload("./gizmos/gizmo_plugin.gd")
const _EDITOR_ACTIONS := preload("./editor_actions.gd")
const _CONTROL_SCENES: Array[PackedScene] = [
	preload("./controls/root_actions/root_actions.tscn"),
	preload("./controls/blocks_area_actions/blocks_area_actions.tscn"),
	preload("./controls/styler_actions/styler_actions.tscn"),
]

var settings: _SETTINGS
var actions: _EDITOR_ACTIONS
var _gizmo_plugin: _GIZMO_PLUGIN
var _controls: Array[Control] = []


func _init() -> void:
	settings = _SETTINGS.new(self)
	actions = _EDITOR_ACTIONS.new(self)
	_gizmo_plugin = _GIZMO_PLUGIN.new(self)


func _enter_tree() -> void:
	get_editor_interface().get_selection().selection_changed.connect(_update_controls_visibility)
	settings.init_settings()
	add_node_3d_gizmo_plugin(_gizmo_plugin)
	for scene in _CONTROL_SCENES:
		var control := scene.instantiate() as Control
		control.set(&"plugin", self)
		add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, control)
		_controls.append(control)
	_update_controls_visibility()


func _exit_tree() -> void:
	get_editor_interface().get_selection().selection_changed.disconnect(_update_controls_visibility)
	for control in _controls:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, control)
		control.free()
	_controls.clear()
	remove_node_3d_gizmo_plugin(_gizmo_plugin)


func _disable_plugin() -> void:
	if settings.get_bool(&"stid_clear_settings_when_plugin_disabled"):
		settings.clear()


func _update_controls_visibility() -> void:
	var nodes := get_editor_interface().get_selection().get_selected_nodes()
	for control in _controls:
		var callable := Callable(control, &"visibility_predicate")
		control.visible = callable.is_valid() and callable.call(nodes) as bool
