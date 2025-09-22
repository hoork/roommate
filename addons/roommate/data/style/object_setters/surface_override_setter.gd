# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./object_setter.gd"

var material: _MATERIAL_SETTER:
	get: return resolve_value_setter(&"material", _MATERIAL_SETTER)
var uv_transform: _TRANSFORM2D_SETTER:
	get: return resolve_value_setter(&"uv_transform", _TRANSFORM2D_SETTER)
var flip_faces: _BOOL_SETTER:
	get: return resolve_value_setter(&"flip_faces", _BOOL_SETTER)
var color: _COLOR_SETTER:
	get: return resolve_value_setter(&"color", _COLOR_SETTER)
var color_weight: _FLOAT_SETTER:
	get: return resolve_value_setter(&"color_weight", _FLOAT_SETTER)


func apply(target: RoommateSurfaceOverride) -> void:
	for property_name in _value_setters:
		var setter := _value_setters[property_name] as _BASE_VALUE_SETTER
		setter.apply(target)


func set_uv_tile(tile_coord: Vector2i, tile_count: Vector2i, tile_rotation := 0.0) -> void:
	var transform := RoommateSurfaceOverride.get_uv_tile_transform(tile_coord, tile_count, tile_rotation)
	uv_transform.override(transform)


func set_color(new_color: Color) -> void:
	color.override(new_color)
	color_weight.override(1)
