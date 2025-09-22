# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
class_name RoommatePart
extends RefCounted

var anchor := Vector3.ZERO
var flow := Vector3.ZERO

var mesh_transform := Transform3D.IDENTITY
var collision_transform := Transform3D.IDENTITY
var scene_transform := Transform3D.IDENTITY
var nav_transform := Transform3D.IDENTITY
var occluder_transform := Transform3D.IDENTITY

var mesh: Mesh
var collision_mesh: Mesh
var scene: PackedScene
var nav_mesh: Mesh
var occluder_mesh: Mesh

var scene_parent_path := NodePath()
var scene_property_overrides := {}

var fallback_surface_override := RoommateSurfaceOverride.new()
var surface_overrides := {}


func resolve_surface_override(surface_id: int) -> RoommateSurfaceOverride:
	if surface_overrides.has(surface_id):
		return surface_overrides[surface_id] as RoommateSurfaceOverride
	var new_override := RoommateSurfaceOverride.new()
	surface_overrides[surface_id] = new_override
	return new_override


func resolve_surface_override_with_fallback(surface_id: int) -> RoommateSurfaceOverride:
	if not fallback_surface_override:
		push_warning("ROOMMATE: fallback_surface_override is null. Creating new one.")
		fallback_surface_override = RoommateSurfaceOverride.new()
	if surface_overrides.has(surface_id):
		var override := surface_overrides[surface_id] as RoommateSurfaceOverride
		return override.get_copy_with_fallback(fallback_surface_override)
	return fallback_surface_override
