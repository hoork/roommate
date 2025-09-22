# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./blocks_selector.gd"

var density := 0.0
var rng: RandomNumberGenerator = null


func _init(init_density: float, init_rng: RandomNumberGenerator) -> void:
	density = init_density
	rng = init_rng


func _block_is_selected(offset_position: Vector3i, block: RoommateBlock, 
		blocks_scope: Dictionary) -> bool:
	var random_number := rng.randf() if rng else randf()
	return density >= random_number
