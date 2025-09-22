# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./blocks_selector.gd"

var axis := Vector3.ZERO
var _max_position := Vector3.ZERO
var _min_position := Vector3.ZERO


func _init(init_axis: Vector3) -> void:
	axis = init_axis


func prepare(blocks_scope: Dictionary) -> void:
	const AXIS_COUNT := 3
	
	_max_position = -Vector3.INF
	_min_position = Vector3.INF
	for key in blocks_scope.keys():
		var position := key as Vector3i
		for i in AXIS_COUNT:
			_max_position[i] = maxf(_max_position[i], position[i])
			_min_position[i] = minf(_min_position[i], position[i])


func _block_is_selected(offset_position: Vector3i, block: RoommateBlock, 
		blocks_scope: Dictionary) -> bool:
	const AXIS_COUNT := 3
	
	if not AABB(_min_position, Vector3.ZERO).expand(_max_position).has_point(offset_position):
		return false
	for i in AXIS_COUNT:
		if axis[i] == 0:
			continue
		var max_delta := axis[i] if axis[i] > 0 else 0 
		var min_delta := axis[i] if axis[i] < 0 else 0 
		var over_min: bool = offset_position[i] >= _min_position[i] - min_delta
		var below_max: bool = offset_position[i] <= _max_position[i] - max_delta
		if over_min and below_max:
			return false
	return true
