# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends EditorNode3DGizmoPlugin

const _BLOCKS_AREA_GIZMO := preload("./blocks_gizmo.gd")
const _OBLIQUE_GIZMO := preload("./oblique_gizmo.gd")

var _plugin: EditorPlugin


func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin
	create_material("blocks", Color.GREEN)
	create_material("area", Color.AQUA)
	create_material("handles_3d", Color.YELLOW)
	create_handle_material("handles")


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is RoommateBlocksArea


func _get_gizmo_name() -> String:
	return "Roommate"


func _create_gizmo(for_node_3d: Node3D) -> EditorNode3DGizmo:
	if for_node_3d is RoommateOblique:
		return _OBLIQUE_GIZMO.new(_plugin)
	if for_node_3d is RoommateBlocksArea:
		return _BLOCKS_AREA_GIZMO.new(_plugin)
	return null
