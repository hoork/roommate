# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
class_name RoommateSegment
extends RefCounted

var step := Vector3i.ZERO
var max_steps := 0


func _init(init_step: Vector3i, init_max_steps: int) -> void:
	step = init_step
	max_steps = init_max_steps
