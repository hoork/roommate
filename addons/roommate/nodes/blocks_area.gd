# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
@icon("../icons/blocks_area.svg")
class_name RoommateBlocksArea
extends RoommateStyler
## Base class for creating multiple [RoommateBlock] and applying styles over 
## occupied area.
##
## This node doesn't create blocks on it's own, but it still can be used to 
## apply style on certain area.

@export var size := Vector3.ONE:
	set(value):
		size = value.abs()
		update_gizmos()
@export var blocks_apply_order := 0
@export var extra_slots: Array[StringName] = []

var box: AABB:
	get:
		return AABB(-size / 2, size)
var _styler_range: AABB


func _ready():
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update_gizmos()


func _prepare_for_style(all_blocks: Dictionary, root_transform: Transform3D, 
		block_size: float) -> void:
	_styler_range = get_blocks_range(root_transform, block_size)


func _block_is_selected_for_style(block: RoommateBlock, all_blocks: Dictionary) -> bool:
	return _styler_range.has_point((block.position as Vector3) + Vector3.ONE / 2)


func get_block_positions(root_transform: Transform3D, block_size: float) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var range := get_blocks_range(root_transform, block_size)
	for x in range(range.position.x, range.end.x):
		for y in range(range.position.y, range.end.y):
			for z in range(range.position.z, range.end.z):
				result.append(Vector3i(x, y, z))
	return result


func get_block_rotation(root_transform: Transform3D) -> Vector3:
	var relative_transform := root_transform.affine_inverse() * global_transform
	return relative_transform.basis.get_euler().snapped(Vector3.ONE * PI / 2)


func create_blocks(root_transform: Transform3D, block_size: float) -> Dictionary:
	var result := {}
	var blocks_range := get_blocks_range(root_transform, block_size)
	var block_rotation := get_block_rotation(root_transform)
	for block_position in get_block_positions(root_transform, block_size):
		var new_block := RoommateBlock.new()
		new_block.type_id = RoommateBlock.NODRAW_TYPE
		new_block.position = block_position
		new_block.rotation = block_rotation
		var processed_block := _process_block(new_block, blocks_range)
		if processed_block:
			processed_block.position = block_position
			processed_block.rotation = block_rotation
			for slot_id in extra_slots:
				if processed_block.slots.has(slot_id):
					continue
				processed_block.slots[slot_id] = RoommatePart.new()
			processed_block.make_read_only()
		result[block_position] = processed_block
	return result


func get_blocks_range(root_transform: Transform3D, block_size: float) -> AABB:
	const AABB_ENDPOINTS_COUNT := 8
	
	var start := Vector3.INF
	var end := -Vector3.INF
	for i in AABB_ENDPOINTS_COUNT:
		var corner := root_transform.affine_inverse() * global_transform * box.get_endpoint(i)
		start = Vector3(minf(start.x, corner.x), minf(start.y, corner.y), minf(start.z, corner.z))
		end = Vector3(maxf(end.x, corner.x), maxf(end.y, corner.y), maxf(end.z, corner.z))
	var range_step := Vector3.ONE * _SETTINGS.get_float(&"stid_area_block_range_step")
	var start_block_position := (start / block_size).snapped(range_step).floor()
	var end_block_position := (end / block_size).snapped(range_step).ceil()
	var range := AABB(start_block_position, Vector3.ZERO).expand(end_block_position)
	range.size.x = 1 if range.size.x == 0 and size.x != 0 else range.size.x
	range.size.y = 1 if range.size.y == 0 and size.y != 0 else range.size.y
	range.size.z = 1 if range.size.z == 0 and size.z != 0 else range.size.z
	return range


func snap_to_range(root_transform: Transform3D, block_size: float) -> void:
	const AXIS_COUNT := 3
	
	var range := get_blocks_range(root_transform, block_size)
	range.size *= block_size
	range.position *= block_size
	range = range.grow(-absf(_SETTINGS.get_float(&"stid_area_snap_margin")))
	global_position = root_transform * range.get_center()
	
	var block_quat := Quaternion.from_euler(get_block_rotation(root_transform))
	var new_global_quat := root_transform.basis.get_rotation_quaternion() * block_quat
	
	if _SETTINGS.get_bool(&"stid_set_global_rotation_when_snapping"):
		global_rotation = new_global_quat.get_euler()
	else:
		var local_quat := Quaternion.from_euler(rotation.snapped(Vector3.ONE * PI / 2))
		var parent := get_parent() as Node3D
		if parent:
			local_quat = Quaternion.from_euler(parent.global_rotation).inverse() * new_global_quat
		rotation = local_quat.get_euler()
	
	# Not letting rotation snap between -PI and PI each time method called
	var current_rotation := rotation
	for i in AXIS_COUNT:
		if is_equal_approx(current_rotation[i], -PI):
			current_rotation[i] = -PI
	rotation = current_rotation
	
	size = global_transform.affine_inverse().basis * (root_transform.basis * range.size)


func find_root() -> RoommateRoot:
	var parent := get_parent()
	while not parent is RoommateRoot:
		parent = parent.get_parent()
		if not parent:
			return null
	return parent as RoommateRoot


func get_type_order() -> float: # virtual method
	return 0


func _process_block(new_block: RoommateBlock, blocks_range: AABB) -> RoommateBlock: # virtual method
	return null


func _create_default_part(anchor: Vector3, flow: Vector3, part_transform: Transform3D, 
		set_nav := false, set_occluder := true, set_mesh := true) -> RoommatePart:
	var result := RoommatePart.new()
	result.anchor = anchor
	result.flow = flow
	result.mesh_transform = part_transform
	result.collision_transform = part_transform
	result.nav_transform = part_transform
	result.occluder_transform = part_transform
	result.scene_transform = part_transform
	var default_mesh := QuadMesh.new()
	default_mesh.material = RoommateStyler.DEFAULT_MATERIAL
	result.mesh = default_mesh if set_mesh else null
	result.collision_mesh = default_mesh if set_mesh else null
	result.nav_mesh = default_mesh if set_nav else null
	result.occluder_mesh = default_mesh if set_occluder else null
	return result


func _create_space_parts() -> Dictionary:
	return {
		RoommateBlock.Slot.CENTER: _create_default_part(Vector3(0.5, 0.5, 0.5), Vector3i.ZERO, 
			Transform3D.IDENTITY, false, false, false),
		RoommateBlock.Slot.CEIL: _create_default_part(Vector3(0.5, 1, 0.5), Vector3i.UP, 
				Transform3D.IDENTITY.rotated(Vector3.RIGHT, PI / 2)),
		RoommateBlock.Slot.FLOOR: _create_default_part(Vector3(0.5, 0, 0.5), Vector3i.DOWN, 
				Transform3D.IDENTITY.rotated(Vector3.LEFT, PI / 2), true),
		RoommateBlock.Slot.WALL_LEFT: _create_default_part(Vector3(0, 0.5, 0.5), Vector3i.LEFT, 
				Transform3D.IDENTITY.rotated(Vector3.UP, PI / 2)),
		RoommateBlock.Slot.WALL_RIGHT: _create_default_part(Vector3(1, 0.5, 0.5), Vector3i.RIGHT, 
				Transform3D.IDENTITY.rotated(Vector3.DOWN, PI / 2)),
		RoommateBlock.Slot.WALL_FORWARD: _create_default_part(Vector3(0.5, 0.5, 0), Vector3i.FORWARD, 
				Transform3D.IDENTITY),
		RoommateBlock.Slot.WALL_BACK: _create_default_part(Vector3(0.5, 0.5, 1), Vector3i.BACK, 
				Transform3D.IDENTITY.rotated(Vector3.UP, PI)),
	}
