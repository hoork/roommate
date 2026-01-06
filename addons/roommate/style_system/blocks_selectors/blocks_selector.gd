# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted

# omid - operation mode id
var mode := &"omid_include"
var offset := Vector3i.ZERO


func update_inclusion(block: RoommateBlock, blocks_scope: Dictionary,
		is_included: bool) -> bool:
	if not _block_is_selected(block.position - offset, block, blocks_scope):
		if mode == &"omid_intersect":
			return false
		return is_included
	
	match mode:
		&"omid_include":
			return true
		&"omid_exclude":
			return false
		&"omid_invert":
			return not is_included
		&"omid_intersect":
			return is_included
	
	push_warning("ROOMMATE: Unexpected operation mode id %s." % mode)
	return is_included


func include() -> void:
	mode = &"omid_include"


func exclude() -> void:
	mode = &"omid_exclude"


func invert() -> void:
	mode = &"omid_invert"


func intersect() -> void:
	mode = &"omid_intersect"


func set_offset(new_offset: Vector3i) -> void:
	offset = new_offset


func prepare(blocks_scope: Dictionary) -> void: # virtual method
	pass


func _block_is_selected(offset_position: Vector3i, block: RoommateBlock, 
		blocks_scope: Dictionary) -> bool: # virtual method
	return false
