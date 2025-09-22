# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends MenuButton

const _ROOMMATE := preload("../roommate_plugin.gd")

var plugin: _ROOMMATE
var _actions := {}


func _enter_tree() -> void:
	get_popup().index_pressed.connect(_on_popup_menu_index_pressed)
	rebuild_menu()


func _exit_tree() -> void:
	get_popup().clear()
	_actions.clear()
	get_popup().index_pressed.disconnect(_on_popup_menu_index_pressed)


func visibility_predicate(nodes: Array[Node]) -> bool: # virtual method
	return true


func _build_menu() -> void: # virtual method
	pass


func rebuild_menu() -> void:
	get_popup().clear()
	_actions.clear()
	_build_menu()


func _on_popup_menu_index_pressed(index: int) -> void:
	if _actions.has(index):
		_actions[index].call()


func _add_button(label: String, shortcut_setting_id: String, action: Callable) -> void:
	if not plugin:
		return
	var popup := get_popup()
	popup.add_item(label)
	var current_index := popup.item_count - 1
	var item_shortcut := plugin.settings.get_shortcut(shortcut_setting_id)
	popup.set_item_shortcut(current_index, item_shortcut, true)
	_actions[current_index] = action


func _get_blocks_areas() -> Array[RoommateBlocksArea]:
	if not plugin:
		return []
	var nodes := plugin.get_editor_interface().get_selection().get_selected_nodes()
	var is_extends := func (node: Node) -> bool:
		return node is RoommateBlocksArea
	var areas: Array[RoommateBlocksArea] = []
	areas.assign(nodes.filter(is_extends))
	return areas


func _get_roots() -> Array[RoommateRoot]:
	if not plugin:
		return []
	var nodes := plugin.get_editor_interface().get_selection().get_selected_nodes()
	var is_extends := func (node: Node) -> bool:
		return node is RoommateRoot
	var roots: Array[RoommateRoot] = []
	roots.assign(nodes.filter(is_extends))
	return roots


func _get_related_roots() -> Array[RoommateRoot]:
	if not plugin:
		return []
	var selected_nodes := plugin.get_editor_interface().get_selection().get_selected_nodes()
	var roots: Array[RoommateRoot] = []
	for node in selected_nodes:
		var node_parent := node.get_parent()
		while node_parent and not node_parent is RoommateRoot:
			node_parent = node_parent.get_parent()
		if node_parent and not roots.has(node_parent):
			roots.append(node_parent)
	return roots
