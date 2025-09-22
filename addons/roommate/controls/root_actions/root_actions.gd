# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "../roommate_menu_button.gd"


func visibility_predicate(nodes: Array[Node]) -> bool:
	if nodes.is_empty():
		return false
	var is_extends := func(node: Node) -> bool:
		return node is RoommateRoot
	return nodes.all(is_extends)


func _build_menu() -> void:
	_add_button("Generate", &"stid_generate_root_nodes_shortcut", _generate)
	_add_button("Snap Areas To Blocks", &"stid_snap_roots_areas_shortcut", _snap)
	_add_button("Clear Scenes", &"stid_clear_scenes_shortcut", _clear_scenes)


func _generate() -> void:
	var roots := _get_roots()
	if roots.is_empty():
		return
	plugin.actions.generate_roots(roots)


func _snap() -> void:
	var roots := _get_roots()
	if roots.is_empty():
		return
	plugin.actions.snap_roots_areas(roots)


func _clear_scenes() -> void:
	var roots := _get_roots()
	if roots.is_empty():
		return
	plugin.actions.clear_roots_scenes(roots)
