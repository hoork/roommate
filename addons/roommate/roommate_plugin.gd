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
const _ROOMMATE_MENU_BUTTON := preload("./controls/roommate_menu_button.gd")

var _gizmo_plugin: _GIZMO_PLUGIN
var _menu_buttons: Array[_ROOMMATE_MENU_BUTTON] = []


func _init() -> void:
	_gizmo_plugin = _GIZMO_PLUGIN.new(self)


func _enter_tree() -> void:
	var editor_settings := get_editor_interface().get_editor_settings()
	
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
	
	_SETTINGS.init_settings(editor_settings)
	
	_gizmo_plugin.area_handle_commited.connect(_on_gizmo_area_handle_commited)
	_gizmo_plugin.redrawed.connect(_on_gizmo_redrawed)
	add_node_3d_gizmo_plugin(_gizmo_plugin)
	
	# menus
	var root_actions_menu := _ROOMMATE_MENU_BUTTON.new()
	root_actions_menu.text = "RoommateRoot"
	root_actions_menu.icon = preload("./icons/root.svg")
	root_actions_menu.visibility_predicate = func(node: Node) -> bool:
		return node is RoommateRoot
	root_actions_menu.add_button("Generate",
			_SETTINGS.get_shortcut(&"stid_generate_root_nodes_shortcut", editor_settings), 
			_get_action(&"generate_selected_roots"))
	root_actions_menu.add_button("Snap Areas To Blocks",
			_SETTINGS.get_shortcut(&"stid_snap_roots_areas_shortcut", editor_settings), 
			_get_action(&"snap_selected_roots_areas"))
	root_actions_menu.add_button("Clear Scenes",
			_SETTINGS.get_shortcut(&"stid_clear_scenes_shortcut", editor_settings), 
			_get_action(&"clear_selected_roots_scenes"))
	_menu_buttons.append(root_actions_menu)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, root_actions_menu)
	
	var block_area_actions_menu := _ROOMMATE_MENU_BUTTON.new()
	block_area_actions_menu.text = "RoommateBlocksArea"
	block_area_actions_menu.icon = preload("./icons/blocks_area.svg")
	block_area_actions_menu.visibility_predicate = func(node: Node) -> bool:
		return node is RoommateBlocksArea
	block_area_actions_menu.add_button("Generate Related Root",
			_SETTINGS.get_shortcut(&"stid_generate_root_nodes_shortcut", editor_settings), 
			_get_action(&"generate_selected_related_roots"))
	block_area_actions_menu.add_button("Snap Area To Blocks",
			_SETTINGS.get_shortcut(&"stid_snap_roots_areas_shortcut", editor_settings), 
			_get_action(&"snap_selected_blocks_areas"))
	_menu_buttons.append(block_area_actions_menu)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, block_area_actions_menu)
	
	var styler_actions_menu := _ROOMMATE_MENU_BUTTON.new()
	styler_actions_menu.text = "RoommateStyler"
	styler_actions_menu.icon = preload("./icons/styler.svg")
	styler_actions_menu.visibility_predicate = func(node: Node) -> bool:
		return node is RoommateStyler and not node is RoommateBlocksArea
	styler_actions_menu.add_button("Generate Related Root",
			_SETTINGS.get_shortcut(&"stid_generate_root_nodes_shortcut", editor_settings), 
			_get_action(&"generate_selected_related_roots"))
	_menu_buttons.append(styler_actions_menu)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, styler_actions_menu)
	
	var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
	for menu_button in _menu_buttons:
		menu_button.update_visible(selected_nodes)


func _exit_tree() -> void:
	get_editor_interface().get_selection().selection_changed.disconnect(_on_selection_changed)
	for menu_button in _menu_buttons:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, menu_button)
		menu_button.free()
	_menu_buttons.clear()
	remove_node_3d_gizmo_plugin(_gizmo_plugin)
	_gizmo_plugin.area_handle_commited.disconnect(_on_gizmo_area_handle_commited)
	_gizmo_plugin.redrawed.disconnect(_on_gizmo_redrawed)
	_gizmo_plugin = null


func _disable_plugin() -> void:
	if _SETTINGS.get_bool(&"stid_clear_settings_when_plugin_disabled"):
		var editor_settings := get_editor_interface().get_editor_settings()
		_SETTINGS.clear(editor_settings)


func _on_selection_changed() -> void:
	var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
	for menu_button in _menu_buttons:
		menu_button.update_visible(selected_nodes)


func _on_gizmo_area_handle_commited(area: RoommateBlocksArea,
		original_transform: Transform3D,
		original_size: Vector3) -> void:
	var ur := get_undo_redo()
	ur.create_action("ROOMMATE: Change Area Size")
	ur.add_undo_property(area, &"global_transform", original_transform)
	ur.add_do_property(area, &"global_transform", area.global_transform)
	ur.add_undo_property(area, &"size", original_size)
	ur.add_do_property(area, &"size", area.size)
	ur.commit_action()


func _on_gizmo_redrawed(gizmo: EditorNode3DGizmo) -> void:
	var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
	gizmo.set_hidden(not selected_nodes.has(gizmo.get_node_3d()) or selected_nodes.size() > 1)


func _get_action(method_name: StringName) -> Callable:
	var selection := get_editor_interface().get_selection()
	var ur := get_undo_redo()
	return Callable(_EDITOR_ACTIONS, method_name).bind(selection, ur)
