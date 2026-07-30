# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends MenuButton

var visibility_predicate: Callable = func(node: Node) -> bool: return true
var _actions := {}


func _enter_tree() -> void:
	get_popup().index_pressed.connect(_on_popup_menu_index_pressed)


func _exit_tree() -> void:
	get_popup().clear()
	_actions.clear()
	get_popup().index_pressed.disconnect(_on_popup_menu_index_pressed)


func add_button(label: String, item_shortcut: Shortcut, action: Callable) -> void:
	get_popup().add_item(label)
	var current_index := get_popup().item_count - 1
	get_popup().set_item_shortcut(current_index, item_shortcut, true)
	_actions[current_index] = action


func update_visible(selected_nodes: Array[Node]) -> void:
	if selected_nodes.is_empty():
		visible = false
		return
	visible = selected_nodes.all(visibility_predicate)


func _on_popup_menu_index_pressed(index: int) -> void:
	if _actions.has(index):
		_actions[index].call()
