# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./value_setter.gd"


func override(vector: Vector3) -> void:
	_override_requested = true
	_override_value = vector


func accumulate(vector: Vector3) -> void:
	_accumulation_requested = true
	_accumulation_value = vector


func _handle_accumulation(current_value: Variant) -> Variant:
	return current_value + _accumulation_value
