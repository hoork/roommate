# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/Hoork/Roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
class_name RoommateBlock
extends RefCounted

const NODRAW_TYPE := &"btid_nodraw"
const SPACE_TYPE := &"btid_space"
const OBLIQUE_TYPE := &"btid_oblique"
const OUT_OF_BOUNDS_TYPE := &"btid_out_of_bounds"

var type_id: StringName
var position: Vector3i
var rotation: Vector3
var slots := {}
var center: Vector3:
	get: return (position as Vector3) + Vector3.ONE / 2


static func raycast(start: Vector3i, step: Vector3i, source_blocks: Dictionary) -> int:
	var result := 0
	var block := source_blocks.get(start + step) as RoommateBlock
	while block:
		result += 1
		block = source_blocks.get(block.position + step) as RoommateBlock
	return result


class Slot:
	const CEIL := &"slid_ceil"
	const FLOOR := &"slid_floor"
	const WALL_LEFT := &"slid_wall_left"
	const WALL_RIGHT := &"slid_wall_right"
	const WALL_FORWARD := &"slid_wall_forward"
	const WALL_BACK := &"slid_wall_back"
	const CENTER := &"slid_center"

	const OBLIQUE := &"slid_oblique"
