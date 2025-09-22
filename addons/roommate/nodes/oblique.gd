# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
@icon("../icons/oblique.svg")
class_name RoommateOblique
extends RoommateBlocksArea
## Area that represents sloped surface

@export var clear_over := true
@export var clear_under := true
@export var fill := false
@export var fill_start_distance := 0.7


static func get_oblique_plane(block_rotation: Vector3, blocks_range: AABB) -> Plane:
	var block_quat := Quaternion.from_euler(block_rotation)
	var extend_axis := block_quat * Vector3.RIGHT
	var extend_axis_index := extend_axis.abs().max_axis_index()
	
	# Translating direction to Vector3(0, a, b) form (default direction with no rotation).
	var plane_direction := blocks_range.size
	plane_direction[extend_axis_index] = 0
	var direction_rotation_angle := PI / 2 if extend_axis_index != Vector3.AXIS_X else 0
	var direction_rotation_axis := Vector3.BACK if extend_axis_index == Vector3.AXIS_Y else Vector3.DOWN
	plane_direction = plane_direction.rotated(direction_rotation_axis, direction_rotation_angle)
	
	# Swapping a and b if block rotated horizontally.
	var plane_forward := Vector3.LEFT if extend_axis_index == Vector3.AXIS_Z else Vector3.FORWARD
	if not is_zero_approx((block_quat * Vector3.FORWARD).dot(plane_forward)):
		plane_direction = plane_direction.rotated(Vector3.LEFT, PI / 2).abs()
	
	var plane_normal := block_quat * plane_direction.normalized()
	return Plane(plane_normal, blocks_range.get_center())


static func get_extend_axis_index(block_rotation: Vector3) -> int:
	return (Quaternion.from_euler(block_rotation) * Vector3.RIGHT).abs().max_axis_index()


static func _get_oblique_block_anchor(block_position: Vector3i, oblique_plane: Plane,
		up_axis: Vector3) -> Vector3:
	var center := (block_position as Vector3) + Vector3.ONE / 2
	var ray_front := oblique_plane.intersects_ray(center, up_axis)
	var ray_back := oblique_plane.intersects_ray(center, -up_axis)
	var intersection := ray_front as Vector3 if ray_front else ray_back as Vector3
	return intersection - center + Vector3.ONE / 2


func get_type_order() -> float:
	return 20


func _process_block(new_block: RoommateBlock, blocks_range: AABB) -> RoommateBlock:
	new_block.type_id = RoommateBlock.OBLIQUE_TYPE
	
	var extend_axis_index := get_extend_axis_index(new_block.rotation)
	var used_size := blocks_range.size
	used_size[extend_axis_index] = 0
	
	var max_side_size := used_size[used_size.max_axis_index()]
	
	var up_axis := Vector3.ONE
	up_axis[extend_axis_index] = 0
	up_axis[used_size.max_axis_index()] = 0
	var forward_axis := Vector3.ONE
	forward_axis[extend_axis_index] = 0
	forward_axis[up_axis.max_axis_index()] = 0
	
	var plane := get_oblique_plane(new_block.rotation, blocks_range)
	
	var has_fill := fill and plane.distance_to(new_block.center) <= minf(-fill_start_distance, 0)
	var is_over_plane := plane.is_point_over(new_block.center)
	
	var anchor := _get_oblique_block_anchor(new_block.position, plane, up_axis)
	var anchor_valid := anchor.clamp(Vector3.ZERO, Vector3.ONE).is_equal_approx(anchor)
	
	var anchor_up := _get_oblique_block_anchor(new_block.position + (up_axis as Vector3i),
			plane, up_axis)
	var anchor_up_valid := anchor_up.clamp(Vector3.ZERO, Vector3.ONE).is_equal_approx(anchor_up)
	
	if not anchor_valid or anchor_up_valid:
		if has_fill:
			new_block.type_id = RoommateBlock.OUT_OF_BOUNDS_TYPE
			return new_block
		if (not clear_over and is_over_plane) or (not clear_under and not is_over_plane):
			return null
		new_block.type_id = RoommateBlock.SPACE_TYPE
		var space_hide_predicate := func(part: RoommatePart) -> bool:
			var extend_axis_vector := Vector3.ZERO
			extend_axis_vector[extend_axis_index] = 1
			return not is_over_plane and part.flow * extend_axis_vector == Vector3.ZERO
		new_block.slots = _create_visible_space_parts(space_hide_predicate)
		return new_block
	
	var part_scale := (used_size.length() - max_side_size) / max_side_size + 1
	var part_transform := Transform3D.IDENTITY.looking_at(-plane.normal, up_axis).scaled_local(Vector3(1, part_scale, 1))
	var is_top_facing := extend_axis_index != Vector3.AXIS_Y and plane.normal.dot(Vector3.UP) >= 0
	var oblique_part := _create_default_part(anchor, plane.normal if fill else Vector3.ZERO, 
			part_transform, is_top_facing)
	
	var oblique_hide_predicate := func(part: RoommatePart) -> bool:
		var flow_dot := plane.normal.dot(part.flow)
		return flow_dot < 0 and not is_zero_approx(flow_dot)
	var slots := _create_visible_space_parts(oblique_hide_predicate)
	slots[RoommateBlock.Slot.OBLIQUE] = oblique_part
	new_block.slots = slots
	return new_block


func _create_visible_space_parts(hide_predicate: Callable) -> Dictionary:
	var slots := _create_space_parts()
	if not fill:
		return slots
	for slot_id in slots:
		var part := slots[slot_id] as RoommatePart
		if part and hide_predicate.call(part):
			slots[slot_id] = null
	return slots
