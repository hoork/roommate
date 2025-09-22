# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
@icon("../icons/style.svg")
class_name RoommateSimpleStyle
extends RoommateStyle

const _BLOCK_SELECTOR := preload("../data/style/blocks_selectors/blocks_selector.gd")

@export var simple_rulesets: Array[RoommateSimpleRuleset] = []


static func _build_transform(position: Vector3, degrees: Vector3, scale: Vector3) -> Transform3D:
	const AXIS_COUNT := 3
	var rotation := Vector3.ZERO
	for i in AXIS_COUNT:
		rotation[i] = deg_to_rad(degrees[i])
	var basis := Basis.from_euler(rotation).scaled(scale)
	return Transform3D(basis, position)


static func _build_transform_fallback(position: Vector3, degrees: Vector3, scale: Vector3,
		fallback: Transform3D) -> Transform3D:
	var transform := _build_transform(position, degrees, scale)
	return transform if transform != Transform3D.IDENTITY else fallback


func _build_rulesets() -> void:
	for simple_ruleset in simple_rulesets:
		_build_simple_ruleset(simple_ruleset)


func _build_simple_ruleset(simple_ruleset: RoommateSimpleRuleset) -> void:
	const RANDOM_DENSITY := 0.5
	
	if not simple_ruleset:
		return
	var ruleset := create_ruleset()
	
	var blocks_selector: _BLOCK_SELECTOR = null
	match StringName(simple_ruleset.blocks_selector):
		RoommateSimpleRuleset.BLOCKS_SELECTOR_ALL:
			blocks_selector = ruleset.select_all_blocks()
		RoommateSimpleRuleset.BLOCKS_SELECTOR_SPACE_TYPE:
			blocks_selector = ruleset.select_blocks_by_type(RoommateBlock.SPACE_TYPE)
		RoommateSimpleRuleset.BLOCKS_SELECTOR_OBLIQUE_TYPE:
			blocks_selector = ruleset.select_blocks_by_type(RoommateBlock.OBLIQUE_TYPE)
		RoommateSimpleRuleset.BLOCKS_SELECTOR_EXTREME:
			blocks_selector = ruleset.select_blocks_by_extreme(simple_ruleset.blocks_selector_step)
		RoommateSimpleRuleset.BLOCKS_SELECTOR_EDGE:
			blocks_selector = ruleset.select_edge_blocks_axis(simple_ruleset.blocks_selector_step)
		RoommateSimpleRuleset.BLOCKS_SELECTOR_INTERVAL:
			blocks_selector = ruleset.select_interval_blocks(simple_ruleset.blocks_selector_step)
		RoommateSimpleRuleset.BLOCKS_SELECTOR_INNER:
			blocks_selector = ruleset.select_inner_blocks_axis(simple_ruleset.blocks_selector_step)
		RoommateSimpleRuleset.BLOCKS_SELECTOR_RANDOM:
			blocks_selector = ruleset.select_random_blocks(RANDOM_DENSITY)
		RoommateSimpleRuleset.BLOCKS_SELECTOR_SEEDED_RANDOM:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("Roommate")
			blocks_selector = ruleset.select_random_blocks(RANDOM_DENSITY, rng)
		_:
			push_error("ROOMMATE: Unknown simple blocks selector type: %s." % simple_ruleset.blocks_selector)
			return
	blocks_selector.set_offset(simple_ruleset.blocks_selector_offset)
	
	var parts_selector := ruleset.select_parts(simple_ruleset.selected_parts)
	parts_selector.inverse_selection = simple_ruleset.inverse_selection
	
	# General
	if simple_ruleset.anchor.clamp(Vector3.ZERO, Vector3.ONE) == simple_ruleset.anchor:
		parts_selector.anchor.override(simple_ruleset.anchor)
	
	# transform overrides
	var uniform_transform := _build_transform(simple_ruleset.uniform_offset, 
			simple_ruleset.uniform_rotation, simple_ruleset.uniform_scale)
	var mesh_transform := _build_transform_fallback(simple_ruleset.mesh_offset, 
			simple_ruleset.mesh_rotation, simple_ruleset.mesh_scale, uniform_transform)
	var collision_transform := _build_transform_fallback(simple_ruleset.collision_offset, 
			simple_ruleset.collision_rotation, simple_ruleset.collision_scale, uniform_transform)
	var scene_transform := _build_transform_fallback(simple_ruleset.scene_offset, 
			simple_ruleset.scene_rotation, simple_ruleset.scene_scale, uniform_transform)
	var nav_transform := _build_transform_fallback(simple_ruleset.nav_offset, 
			simple_ruleset.nav_rotation, simple_ruleset.nav_scale, uniform_transform)
	if mesh_transform != Transform3D.IDENTITY:
		parts_selector.mesh_transform.accumulate(mesh_transform)
	if collision_transform != Transform3D.IDENTITY:
		parts_selector.collision_transform.accumulate(collision_transform)
	if scene_transform != Transform3D.IDENTITY:
		parts_selector.scene_transform.accumulate(scene_transform)
	if nav_transform != Transform3D.IDENTITY:
		parts_selector.nav_transform.accumulate(nav_transform)
	
	# mesh overrides
	var mesh := simple_ruleset.mesh if simple_ruleset.mesh else simple_ruleset.uniform_mesh
	var collision_mesh := simple_ruleset.collision_mesh if simple_ruleset.collision_mesh else simple_ruleset.uniform_mesh
	var nav_mesh := simple_ruleset.nav_mesh if simple_ruleset.nav_mesh else simple_ruleset.uniform_mesh
	if mesh:
		parts_selector.mesh.override(mesh)
	if collision_mesh:
		parts_selector.collision_mesh.override(collision_mesh)
	if nav_mesh:
		parts_selector.nav_mesh.override(nav_mesh)
	
	# scenes overrides
	if simple_ruleset.scene:
		parts_selector.scene.override(simple_ruleset.scene)
	if not simple_ruleset.scene_parent_path.is_empty():
		parts_selector.scene_parent_path.override(NodePath(simple_ruleset.scene_parent_path))
	if not simple_ruleset.scene_property_overrides.is_empty():
		parts_selector.scene_property_overrides.accumulate(simple_ruleset.scene_property_overrides)
	
	# surface overrides
	var surface_override := parts_selector.override_fallback_surface()
	if simple_ruleset.material:
		surface_override.material.override(simple_ruleset.material)
	if simple_ruleset.color != Color.WHITE:
		surface_override.set_color(simple_ruleset.color)
	if simple_ruleset.uv_tile_size.x > 0 and simple_ruleset.uv_tile_size.y > 0:
		surface_override.set_uv_tile(simple_ruleset.uv_tile_position, simple_ruleset.uv_tile_size, 0)
	if simple_ruleset.flip_faces:
		surface_override.flip_faces.override(simple_ruleset.flip_faces)
	
