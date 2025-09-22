# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
@icon("../icons/out_of_bounds.svg")
class_name RoommateOutOfBounds
extends RoommateBlocksArea
## Area that represents filled space of a room.
## 
## Creates multiple [RoommateBlock] of type [i]btid_out_of_bounds[/i]. This type 
## of block will be threated as it doesn't exists. No parts created by a default.


func get_type_order() -> float:
	return 30


func _process_block(new_block: RoommateBlock, blocks_range: AABB) -> RoommateBlock:
	new_block.type_id = RoommateBlock.OUT_OF_BOUNDS_TYPE
	return new_block
