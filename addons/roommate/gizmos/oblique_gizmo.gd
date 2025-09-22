# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./area_edit_gizmo.gd"


func _redraw() -> void:
	clear()
	_draw_area_edit()
	
	var area := get_node_3d() as RoommateOblique
	var root := area.find_root()
	
	# blocks range
	if not root:
		return
	
	var blocks_box := area.get_blocks_range(root.global_transform, root.block_size)
	blocks_box.size *= root.block_size
	blocks_box.position *= root.block_size
	var block_rotation := area.get_block_rotation(root.global_transform)
	var plane := RoommateOblique.get_oblique_plane(block_rotation, blocks_box)
	var blocks_box_lines := area.global_transform.affine_inverse() * (root.global_transform * _get_oblique_lines(blocks_box, plane))
	var blocks_material := get_plugin().get_material("blocks", self)
	add_lines(blocks_box_lines, blocks_material)


func _get_oblique_lines(aabb: AABB, plane: Plane) -> PackedVector3Array:
	const AABB_ENDPOINTS_COUNT := 8
	const ENDPOINTS_MATRIX_ORDER := 2
	const TOP_ENDPOINTS := [[2, 1], [0, 3]]
	const BOTTOM_ENDPOINTS := [[6, 5], [4, 7]]
	const OPPOSITE_ENDPOINTS_ID_SUM := 7
	
	var result := PackedVector3Array()
	for i in ENDPOINTS_MATRIX_ORDER:
		for j in ENDPOINTS_MATRIX_ORDER:
			# corner 1
			_try_add_oblique_line(aabb.get_endpoint(TOP_ENDPOINTS[0][i]), 
					aabb.get_endpoint(TOP_ENDPOINTS[1][j]), plane, result)
			# corner 2
			_try_add_oblique_line(aabb.get_endpoint(BOTTOM_ENDPOINTS[0][i]), 
					aabb.get_endpoint(BOTTOM_ENDPOINTS[1][j]), plane, result)
			# vertical line
			_try_add_oblique_line(aabb.get_endpoint(TOP_ENDPOINTS[i][j]),
					aabb.get_endpoint(BOTTOM_ENDPOINTS[i][j]), plane, result)
	for i in AABB_ENDPOINTS_COUNT:
		for j in AABB_ENDPOINTS_COUNT:
			if i == j or i + j == OPPOSITE_ENDPOINTS_ID_SUM:
				continue
			var from := aabb.get_endpoint(i)
			var to := aabb.get_endpoint(j)
			if plane.has_point(from) and plane.has_point(to):
				result.push_back(from)
				result.push_back(to)
	return result


func _try_add_oblique_line(from: Vector3, to: Vector3, plane: Plane, result: PackedVector3Array) -> void:
	var from_inside := plane.has_point(from) or not plane.is_point_over(from)
	var to_inside := plane.has_point(to) or not plane.is_point_over(to)
	if from_inside and to_inside:
		result.push_back(from)
		result.push_back(to)
