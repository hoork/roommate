# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./blocks_selector.gd"

var check_selection: Callable
var prepare_vars: Callable

var _check_selection_valid := false
var _prepared_vars := {}


func _init(init_check_selection: Callable, init_prepare_vars: Callable) -> void:
	check_selection = init_check_selection
	prepare_vars = init_prepare_vars


func prepare(blocks_scope: Dictionary) -> void:
	_check_selection_valid = true
	_prepared_vars = {}
	if prepare_vars.is_valid():
		var new_vars := prepare_vars.call(blocks_scope)
		if new_vars is Dictionary:
			_prepared_vars = new_vars
		else:
			push_error("ROOMMATE: prepare_vars returned value of type %s. Dictionary expected." % typeof(new_vars))


func _block_is_selected(offset_position: Vector3i, block: RoommateBlock, 
		blocks_scope: Dictionary) -> bool:
	if not _check_selection_valid:
		return false
	if not check_selection.is_valid():
		_check_selection_valid = false
		push_error("ROOMMATE: check_selection is not valid callback.")
		return false
	
	var check_value := check_selection.call(offset_position, block, blocks_scope, 
			_prepared_vars)
	if not check_value is bool:
		_check_selection_valid = false
		push_error("ROOMMATE: check_selection returned value of type %s. Bool expected." % typeof(check_value))
		return false
	return check_value
