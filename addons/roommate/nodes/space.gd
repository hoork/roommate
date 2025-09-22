# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
@icon("../icons/space.svg")
class_name RoommateSpace
extends RoommateBlocksArea
## Area that represents empty space of a room.
## 
## Creates multiple [RoommateBlock] of type [i]btid_space[/i]. By default these 
## blocks will be generated as flat surfaces visible part of which will be 
## directed inwards block.


func get_type_order() -> float:
	return 10


func _process_block(new_block: RoommateBlock, blocks_range: AABB) -> RoommateBlock:
	new_block.type_id = RoommateBlock.SPACE_TYPE;
	new_block.slots = _create_space_parts()
	return new_block
