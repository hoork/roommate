# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
class_name RoommateSimpleRuleset
extends Resource

# sbsid - simple blocks selector id
const BLOCKS_SELECTOR_ALL := &"sbsid_all"
const BLOCKS_SELECTOR_SPACE_TYPE := &"sbsid_space_type"
const BLOCKS_SELECTOR_OBLIQUE_TYPE := &"sbsid_oblique_type"
const BLOCKS_SELECTOR_EXTREME := &"sbsid_extreme"
const BLOCKS_SELECTOR_EDGE := &"sbsid_edge"
const BLOCKS_SELECTOR_INTERVAL := &"sbsid_interval"
const BLOCKS_SELECTOR_INNER := &"sbsid_inner"
const BLOCKS_SELECTOR_RANDOM := &"sbsid_random"
const BLOCKS_SELECTOR_SEEDED_RANDOM := &"sbsid_seeded_random"

@export_group("Blocks Selector")
@export_enum(BLOCKS_SELECTOR_ALL, BLOCKS_SELECTOR_SPACE_TYPE, BLOCKS_SELECTOR_OBLIQUE_TYPE, 
		BLOCKS_SELECTOR_EXTREME, BLOCKS_SELECTOR_EDGE, BLOCKS_SELECTOR_INTERVAL, 
		BLOCKS_SELECTOR_INNER, BLOCKS_SELECTOR_RANDOM) var blocks_selector := String(BLOCKS_SELECTOR_ALL)
@export var blocks_selector_step := Vector3i.ZERO
@export var blocks_selector_offset := Vector3i.ZERO

@export_group("Parts Setter")
@export var selected_parts: Array[StringName] = [
	RoommateBlock.Slot.CEIL,
	RoommateBlock.Slot.FLOOR,
	RoommateBlock.Slot.WALL_LEFT,
	RoommateBlock.Slot.WALL_RIGHT,
	RoommateBlock.Slot.WALL_FORWARD,
	RoommateBlock.Slot.WALL_BACK,
	RoommateBlock.Slot.OBLIQUE,
]
@export var inverse_selection := false

@export_group("General")
@export var anchor := -Vector3.ONE
@export var uniform_offset := Vector3.ZERO
@export var uniform_rotation := Vector3.ZERO
@export var uniform_scale := Vector3.ONE
@export var uniform_mesh: Mesh

@export_group("Mesh")
@export var mesh_offset := Vector3.ZERO
@export var mesh_rotation := Vector3.ZERO
@export var mesh_scale := Vector3.ONE
@export var mesh: Mesh = null

@export_group("Mesh Surface")
@export var material: Material = null
@export var uv_tile_size := Vector2i.ZERO
@export var uv_tile_position := Vector2i.ZERO
@export var color := Color.WHITE
@export var flip_faces := false

@export_group("Collision") 
@export var collision_offset := Vector3.ZERO
@export var collision_rotation := Vector3.ZERO
@export var collision_scale := Vector3.ONE
@export var collision_mesh: Mesh = null

@export_group("Scenes")
@export var scene_offset := Vector3.ZERO
@export var scene_rotation := Vector3.ZERO
@export var scene_scale := Vector3.ONE
@export var scene: PackedScene = null
@export var scene_parent_path := String()
@export var scene_property_overrides := {}

@export_group("Navigation")
@export var nav_offset := Vector3.ZERO
@export var nav_rotation := Vector3.ZERO
@export var nav_scale := Vector3.ONE
@export var nav_mesh: Mesh = null
