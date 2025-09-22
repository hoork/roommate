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
	var area := get_node_3d() as RoommateBlocksArea
	var root := area.find_root()
	
	# blocks range
	if not root:
		return
	
	var blocks_box := area.get_blocks_range(root.global_transform, root.block_size)
	blocks_box.size *= root.block_size
	blocks_box.position *= root.block_size
	var blocks_box_lines := area.global_transform.affine_inverse() * (root.global_transform * _get_aabb_lines(blocks_box))
	var blocks_material := get_plugin().get_material("blocks", self)
	add_lines(blocks_box_lines, blocks_material)
