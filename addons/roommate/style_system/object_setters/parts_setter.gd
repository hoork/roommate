# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./object_setter.gd"

const _SURFACE_OVERRIDE_SETTER := preload("./surface_override_setter.gd")

var selected_slot_ids: Array[StringName] = []
var inverse_selection := false
var handle_part: Callable

var anchor: _VECTOR3_SETTER:
	get: return resolve_value_setter(&"anchor", _VECTOR3_SETTER)
var flow: _VECTOR3_SETTER:
	get: return resolve_value_setter(&"flow", _VECTOR3_SETTER)

var mesh_transform: _TRANSFORM3D_SETTER:
	get: return resolve_value_setter(&"mesh_transform", _TRANSFORM3D_SETTER)
var collision_transform: _TRANSFORM3D_SETTER:
	get: return resolve_value_setter(&"collision_transform", _TRANSFORM3D_SETTER)
var scene_transform: _TRANSFORM3D_SETTER:
	get: return resolve_value_setter(&"scene_transform", _TRANSFORM3D_SETTER)
var nav_transform: _TRANSFORM3D_SETTER:
	get: return resolve_value_setter(&"nav_transform", _TRANSFORM3D_SETTER)
var occluder_transform: _TRANSFORM3D_SETTER:
	get: return resolve_value_setter(&"occluder_transform", _TRANSFORM3D_SETTER)

var mesh: _MESH_SETTER:
	get: return resolve_value_setter(&"mesh", _MESH_SETTER)
var collision_mesh: _MESH_SETTER:
	get: return resolve_value_setter(&"collision_mesh", _MESH_SETTER)
var scene: _PACKED_SCENE_SETTER:
	get: return resolve_value_setter(&"scene", _PACKED_SCENE_SETTER)
var nav_mesh: _MESH_SETTER:
	get: return resolve_value_setter(&"nav_mesh", _MESH_SETTER)
var occluder_mesh: _MESH_SETTER:
	get: return resolve_value_setter(&"occluder_mesh", _MESH_SETTER)

var scene_parent_path: _NODE_PATH_SETTER:
	get: return resolve_value_setter(&"scene_parent_path", _NODE_PATH_SETTER)
var scene_property_overrides: _DICTIONARY_SETTER:
	get: return resolve_value_setter(&"scene_property_overrides", _DICTIONARY_SETTER)

var surfaces: _SURFACE_OVERRIDE_SETTER:
	get: return override_fallback_surface()

var surface_overrides := {}
var fallback_surface_override: _SURFACE_OVERRIDE_SETTER = null


func apply(block: RoommateBlock) -> void:
	for slot_id in block.slots:
		var selected := selected_slot_ids.has(slot_id)
		if (not inverse_selection and not selected) or (inverse_selection and selected):
			continue
		var current_part := block.slots.get(slot_id) as RoommatePart
		if not current_part:
			continue
		
		for property_name in _value_setters:
			var setter := _value_setters[property_name] as _BASE_VALUE_SETTER
			setter.apply(current_part)
		if fallback_surface_override:
			fallback_surface_override.apply(current_part.fallback_surface_override)
		for surface_id in surface_overrides:
			var override_setter := surface_overrides[surface_id] as _SURFACE_OVERRIDE_SETTER
			if not override_setter:
				push_warning("ROOMMATE: Surface override setter is null.")
				continue
			var current_override := current_part.resolve_surface_override(surface_id)
			override_setter.apply(current_override)
		
		if handle_part.is_valid():
			handle_part.call(slot_id, current_part, block)


func override_surface(surface_id: int) -> _SURFACE_OVERRIDE_SETTER:
	if surface_overrides.has(surface_id):
		return surface_overrides[surface_id] as _SURFACE_OVERRIDE_SETTER
	var new_override := _SURFACE_OVERRIDE_SETTER.new()
	surface_overrides[surface_id] = new_override
	return new_override


func override_fallback_surface() -> _SURFACE_OVERRIDE_SETTER:
	if not fallback_surface_override:
		fallback_surface_override = _SURFACE_OVERRIDE_SETTER.new()
	return fallback_surface_override


func invert_selection() -> void:
	inverse_selection = true
