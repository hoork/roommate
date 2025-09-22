# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./blocks_selector.gd"

var target_type_id: StringName


func _init(init_target_type_id: StringName) -> void:
	target_type_id = init_target_type_id


func _block_is_selected(offset_position: Vector3i, block: RoommateBlock, 
		blocks_scope: Dictionary) -> bool:
	return block.type_id == target_type_id
