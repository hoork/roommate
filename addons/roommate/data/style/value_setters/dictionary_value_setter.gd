# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./value_setter.gd"

var _overwrite := false


func override(dictionary: Dictionary) -> void:
	_override_requested = true
	_override_value = dictionary


func accumulate(dictionary: Dictionary, overwrite := false) -> void:
	_accumulation_requested = true
	_accumulation_value = dictionary
	_overwrite = overwrite


func _handle_accumulation(current_value: Variant) -> Variant:
	var current := current_value as Dictionary
	var accumulation := _accumulation_value as Dictionary
	current.merge(accumulation, _overwrite)
	return current
