# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./blocks_selector.gd"

var interval := Vector3i.ZERO
var global_space := false
var _min_position := Vector3i.ZERO


func _init(init_interval: Vector3i, init_global := false) -> void:
	interval = init_interval
	global_space = init_global


func prepare(blocks_scope: Dictionary) -> void: # virtual method
	_min_position = Vector3i.ZERO 
	if not global_space:
		_min_position = blocks_scope.keys().min() as Vector3i


func _block_is_selected(offset_position: Vector3i, block: RoommateBlock, 
		blocks_scope: Dictionary) -> bool:
	var position := offset_position - _min_position
	return position.snapped(interval) == position
