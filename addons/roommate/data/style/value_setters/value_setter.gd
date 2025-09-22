# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted

var property_name: StringName
var _override_value: Variant
var _accumulation_value: Variant
var _override_requested := false
var _accumulation_requested := false


func apply(target: Object) -> void:
	if _override_requested:
		target.set(property_name, _override_value)
		
	if _accumulation_requested:
		var current_value: Variant = target.get(property_name)
		var new_value: Variant = _handle_accumulation(current_value)
		target.set(property_name, new_value)


func _handle_accumulation(current_value: Variant) -> Variant: # virtual method
	return current_value
