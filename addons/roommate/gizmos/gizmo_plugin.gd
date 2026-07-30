# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends EditorNode3DGizmoPlugin

signal area_handle_commited(area: RoommateBlocksArea,
		original_transform: Transform3D,
		original_size: Vector3)
signal redrawed(gizmo: EditorNode3DGizmo)

const _AREA_EDIT_GIZMO := preload("./area_edit_gizmo.gd")
const _BLOCKS_AREA_GIZMO := preload("./blocks_gizmo.gd")
const _OBLIQUE_GIZMO := preload("./oblique_gizmo.gd")


func _init(plugin: EditorPlugin) -> void:
	create_material("blocks", Color.GREEN)
	create_material("area", Color.AQUA)
	create_material("handles_3d", Color.YELLOW)
	create_handle_material("handles")


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is RoommateBlocksArea


func _get_gizmo_name() -> String:
	return "Roommate"


func _create_gizmo(for_node_3d: Node3D) -> EditorNode3DGizmo:
	var new_gizmo: _AREA_EDIT_GIZMO = null
	if for_node_3d is RoommateOblique:
		new_gizmo = _OBLIQUE_GIZMO.new()
	if for_node_3d is RoommateBlocksArea:
		new_gizmo = _BLOCKS_AREA_GIZMO.new()
	
	if is_instance_valid(new_gizmo):
		new_gizmo.area_handle_commited.connect(_area_handle_commited_bubbling)
		new_gizmo.redrawed.connect(_redrawed_bubbling)
	return new_gizmo


func _area_handle_commited_bubbling(area: RoommateBlocksArea, 
		original_transform: Transform3D,
		original_size: Vector3) -> void:
	area_handle_commited.emit(area, original_transform, original_size)


func _redrawed_bubbling(gizmo: EditorNode3DGizmo) -> void:
	redrawed.emit(gizmo)
