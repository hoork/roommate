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
	var intersection := ray_front as Vector3 if ray_front != null else ray_back as Vector3
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
			new_block.type_id = RoommateBlock.OBLIQUE_FILLING_TYPE
			new_block.slots = _create_visible_space_parts_without_oblique(extend_axis_index, 
					is_over_plane)
			return new_block
		if (not clear_over and is_over_plane) or (not clear_under and not is_over_plane):
			return null
		new_block.type_id = RoommateBlock.SPACE_TYPE
		new_block.slots = _create_visible_space_parts_without_oblique(extend_axis_index, 
				is_over_plane)
		return new_block
	
	var part_basis := Basis.IDENTITY.from_euler(new_block.rotation)
	var part_scale := Vector3.ONE
	part_scale[up_axis.max_axis_index()] = used_size[up_axis.max_axis_index()] / used_size[forward_axis.max_axis_index()]
	var is_top_facing := extend_axis_index != Vector3.AXIS_Y and plane.normal.dot(Vector3.UP) >= 0
	var part_transform := Transform3D(part_basis, Vector3.ZERO).scaled(part_scale)
	
	var oblique_part := RoommatePart.create(anchor, 
			plane.normal if fill else Vector3.ZERO, 
			part_transform, DEFAULT_OBLIQUE_MESH, 
			DEFAULT_OBLIQUE_MESH if is_top_facing else null)
	
	var left_side_direction := part_basis * Vector3.LEFT
	var left_side_anchor := anchor
	left_side_anchor[extend_axis_index] = 1 if left_side_direction[extend_axis_index] > 0 else 0
	var left_side_transform := part_transform.rotated_local(Vector3.UP, PI / 2)
	var oblique_side_left := RoommatePart.create(left_side_anchor, left_side_direction,
			left_side_transform, DEFAULT_OBLIQUE_SIDE_MESH, null)
	oblique_side_left.fallback_surface_override.flip_faces = true
	
	var right_side_direction := part_basis * Vector3.RIGHT
	var right_side_anchor := anchor
	right_side_anchor[extend_axis_index] = 1 if right_side_direction[extend_axis_index] > 0 else 0
	var right_side_transform := part_transform.rotated_local(Vector3.UP, PI / 2)
	var oblique_side_right := RoommatePart.create(right_side_anchor, right_side_direction,
			right_side_transform, DEFAULT_OBLIQUE_SIDE_MESH, null)
	
	var slots := _create_visible_space_parts_with_oblique(plane)
	slots[RoommateBlock.Slot.OBLIQUE] = oblique_part
	slots[RoommateBlock.Slot.OBLIQUE_SIDE_LEFT] = oblique_side_left
	slots[RoommateBlock.Slot.OBLIQUE_SIDE_RIGHT] = oblique_side_right
	new_block.slots = slots
	return new_block


func _create_visible_space_parts_without_oblique(extend_axis_index: int, is_over_plane: bool) -> Dictionary:
	var slots := RoommateSpace.create_parts()
	if not fill:
		return slots
	for slot_id in slots:
		var part := slots[slot_id] as RoommatePart
		if is_instance_valid(part):
			var extend_axis_vector := Vector3.ZERO
			extend_axis_vector[extend_axis_index] = 1 
			if not is_over_plane and part.flow * extend_axis_vector == Vector3.ZERO:
				slots[slot_id] = null
	return slots


func _create_visible_space_parts_with_oblique(plane: Plane) -> Dictionary:
	var slots := RoommateSpace.create_parts()
	if not fill:
		return slots
	for slot_id in slots:
		var part := slots[slot_id] as RoommatePart
		if is_instance_valid(part):
			var flow_dot := plane.normal.dot(part.flow)
			if flow_dot < 0 and not is_zero_approx(flow_dot):
				slots[slot_id] = null
	return slots
