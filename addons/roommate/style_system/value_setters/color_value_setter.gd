# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./value_setter.gd"

var _blend_over := true


func override(color: Color) -> void:
	_override_requested = true
	_override_value = color


func accumulate(color: Color, new_alpha := -1.0, blend_over := true) -> void:
	_accumulation_requested = true
	if new_alpha >= 0:
		color.a = new_alpha
	_accumulation_value = color
	_blend_over = blend_over


func _handle_accumulation(current_value: Variant) -> Variant:
	var current_color := current_value as Color
	var accumulation_color := _accumulation_value as Color
	var color_under := current_color if _blend_over else accumulation_color
	var color_over := accumulation_color if _blend_over else current_color
	return color_under.blend(color_over)
