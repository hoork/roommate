# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./assembler.gd"

var _collision_faces := PackedVector3Array()


func add_part(part: RoommatePart, block: RoommateBlock) -> void:
	if not part or not part.collision_mesh:
		return
	var part_origin := block.position * block_size + block_size * part.anchor
	var part_collision_faces := part.collision_transform.translated(part_origin) * part.collision_mesh.get_faces()
	_collision_faces.append_array(part_collision_faces)


func assemble_and_attach(root: RoommateRoot) -> void:
	var collision_shape_container := _resolve_collision_shape_container(root)
	if not collision_shape_container:
		return
	var new_shape := ConvexPolygonShape3D.new()
	if collision_shape_container.shape is ConvexPolygonShape3D:
		new_shape = collision_shape_container.shape.duplicate(true) as ConvexPolygonShape3D
	new_shape.points = _collision_faces.duplicate()
	if root.try_save_resource(new_shape, root.path_to_collision_shape_resource, &"stid_collision_shape_resource_file_postfix"):
		root.path_to_collision_shape_resource = new_shape.resource_path
	collision_shape_container.shape = new_shape


func _resolve_collision_shape_container(root: RoommateRoot) -> CollisionShape3D:
	var container := root.get_node_or_null(root.linked_collision_shape_container) as CollisionShape3D
	if container:
		return container
	if RoommateRoot.resolve_setting_bool(&"stid_create_collision_shape_container_if_missing", root.create_collision_container_if_missing):
		var static_body := StaticBody3D.new()
		static_body.name = _SETTINGS.get_string_name(&"stid_collision_static_body_name")
		
		container = CollisionShape3D.new()
		container.name = _SETTINGS.get_string_name(&"stid_collision_shape_container_name")
		
		root.add_child(static_body)
		static_body.add_child(container)
		
		static_body.owner = root.owner
		container.owner = root.owner
		root.linked_collision_shape_container = root.get_path_to(container)
	return container
