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
		return node is RoommateStyler and not node is RoommateBlocksArea
	return nodes.all(is_extends)


func _build_menu() -> void:
	_add_button("Generate Related Root", &"stid_generate_root_nodes_shortcut", _generate)


func _generate() -> void:
	var roots := _get_related_roots()
	if roots.is_empty():
		return
	plugin.actions.generate_roots(roots)
