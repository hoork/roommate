# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted

const _BASE_VALUE_SETTER := preload("../value_setters/value_setter.gd")
const _BOOL_SETTER := preload("../value_setters/bool_value_setter.gd")
const _FLOAT_SETTER := preload("../value_setters/float_value_setter.gd")
const _VECTOR3_SETTER := preload("../value_setters/vector3_value_setter.gd")
const _COLOR_SETTER := preload("../value_setters/color_value_setter.gd")
const _NODE_PATH_SETTER := preload("../value_setters/node_path_value_setter.gd")
const _TRANSFORM2D_SETTER := preload("../value_setters/transform2d_value_setter.gd")
const _TRANSFORM3D_SETTER := preload("../value_setters/transform3d_value_setter.gd")
const _DICTIONARY_SETTER := preload("../value_setters/dictionary_value_setter.gd")
const _MATERIAL_SETTER := preload("../value_setters/material_value_setter.gd")
const _MESH_SETTER := preload("../value_setters/mesh_value_setter.gd")
const _PACKED_SCENE_SETTER := preload("../value_setters/packed_scene_value_setter.gd")

var _value_setters := {}


func resolve_value_setter(property_name: StringName, setter_script: Script) -> _BASE_VALUE_SETTER:
	if _value_setters.has(property_name):
		var existing_setter := _value_setters[property_name] as _BASE_VALUE_SETTER
		if not setter_script.instance_has(existing_setter):
			push_error("ROOMMATE: Setter %s doesn't have expected type." % property_name)
		return existing_setter
	var new_setter := setter_script.new() as _BASE_VALUE_SETTER
	new_setter.property_name = property_name
	_value_setters[property_name] = new_setter
	return new_setter
