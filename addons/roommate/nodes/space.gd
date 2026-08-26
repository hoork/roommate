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


static func create_parts() -> Dictionary:
	return {
		RoommateBlock.Slot.CENTER: RoommatePart.create(Vector3(0.5, 0.5, 0.5), 
				Vector3i.ZERO, Transform3D.IDENTITY, null, null),
		RoommateBlock.Slot.CEIL: RoommatePart.create(Vector3(0.5, 1, 0.5), Vector3i.UP, 
				Transform3D.IDENTITY.rotated(Vector3.RIGHT, PI / 2), DEFAULT_QUAD_MESH, null),
		RoommateBlock.Slot.FLOOR: RoommatePart.create(Vector3(0.5, 0, 0.5), Vector3i.DOWN, 
				Transform3D.IDENTITY.rotated(Vector3.LEFT, PI / 2), DEFAULT_QUAD_MESH, DEFAULT_QUAD_MESH),
		RoommateBlock.Slot.WALL_LEFT: RoommatePart.create(Vector3(0, 0.5, 0.5), Vector3i.LEFT, 
				Transform3D.IDENTITY.rotated(Vector3.UP, PI / 2), DEFAULT_QUAD_MESH, null),
		RoommateBlock.Slot.WALL_RIGHT: RoommatePart.create(Vector3(1, 0.5, 0.5), Vector3i.RIGHT, 
				Transform3D.IDENTITY.rotated(Vector3.DOWN, PI / 2), DEFAULT_QUAD_MESH, null),
		RoommateBlock.Slot.WALL_FORWARD: RoommatePart.create(Vector3(0.5, 0.5, 0), Vector3i.FORWARD, 
				Transform3D.IDENTITY, DEFAULT_QUAD_MESH, null),
		RoommateBlock.Slot.WALL_BACK: RoommatePart.create(Vector3(0.5, 0.5, 1), Vector3i.BACK, 
				Transform3D.IDENTITY.rotated(Vector3.UP, PI), DEFAULT_QUAD_MESH, null),
	}


func get_type_order() -> float:
	return 10


func _process_block(new_block: RoommateBlock, blocks_range: AABB) -> RoommateBlock:
	new_block.type_id = RoommateBlock.SPACE_TYPE;
	new_block.slots = create_parts()
	return new_block
