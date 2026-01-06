# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
class_name RoommateSurfaceOverride
extends RefCounted

var material: Material:
	set(value):
		material = value
		_on_property_changed("material")
var uv_transform := Transform2D.IDENTITY:
	set(value):
		uv_transform = value
		_on_property_changed("uv_transform")
var flip_faces := false:
	set(value):
		flip_faces = value
		_on_property_changed("flip_faces")
var color := Color.WHITE:
	set(value):
		color = value
		_on_property_changed("color")
var color_weight := 0.0:
	set(value):
		color_weight = value
		_on_property_changed("color_weight")

var _changed_properties: Array[String] = []


static func get_uv_tile_transform(tile_coord: Vector2i, tile_count: Vector2i, 
		tile_rotation: float) -> Transform2D:
	var coord := tile_coord as Vector2
	var count := tile_count as Vector2
	var tile_size := Vector2.ONE / count
	var tile_offset := coord / count
	var rotated_offset := (tile_offset + tile_size / 2).rotated(-tile_rotation) - tile_size / 2
	return Transform2D(tile_rotation, Vector2.ZERO) * Transform2D(0, tile_size, 0, rotated_offset)


func set_uv_tile(tile_coord: Vector2i, tile_count: Vector2i, tile_rotation := 0.0) -> void:
	uv_transform = get_uv_tile_transform(tile_coord, tile_count, tile_rotation)


func set_color(new_color: Color) -> void:
	color = new_color
	color_weight = 1


func get_copy_with_fallback(fallback: RoommateSurfaceOverride) -> RoommateSurfaceOverride:
	var result := RoommateSurfaceOverride.new()
	for property in (RoommateSurfaceOverride as Script).get_script_property_list():
		var property_name := property["name"] as String
		if property_name.begins_with("_"): # ignoring private properties
			continue
		var source := self if _changed_properties.has(property_name) else fallback
		result.set(property_name, source.get(property_name))
	return result


func _on_property_changed(property_name: String) -> void:
	if not _changed_properties.has(property_name):
		_changed_properties.append(property_name)
