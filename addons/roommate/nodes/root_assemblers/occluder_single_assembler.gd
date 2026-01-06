# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./assembler.gd"

var _occluder_tool := SurfaceTool.new()


func add_part(part: RoommatePart, block: RoommateBlock) -> void:
	if not part or not part.occluder_mesh:
		return
	var part_origin := block.position * block_size + block_size * part.anchor
	for surface_id in part.occluder_mesh.get_surface_count():
		_occluder_tool.append_from(part.occluder_mesh, surface_id, 
				part.occluder_transform.translated(part_origin))


func assemble_and_attach(root: RoommateRoot) -> void:
	var occluder_container := _resolve_occluder_container(root)
	if not occluder_container:
		return
	_occluder_tool.index()
	var occluder := ArrayOccluder3D.new()
	var occluder_arrays := _occluder_tool.commit_to_arrays()
	var vertices := PackedVector3Array(occluder_arrays[Mesh.ARRAY_VERTEX])
	var indices := PackedInt32Array(occluder_arrays[Mesh.ARRAY_INDEX])
	occluder.set_arrays(vertices, indices)
	
	if root.try_save_resource(occluder, root.path_to_occluder_resource, &"stid_occluder_resource_file_postfix"):
		root.path_to_occluder_resource = occluder.resource_path
	occluder_container.occluder = occluder
	occluder_container.update_gizmos()


func _resolve_occluder_container(root: RoommateRoot) -> OccluderInstance3D:
	var container := root.get_node_or_null(root.linked_occluder_container) as OccluderInstance3D
	if container:
		return container
	if RoommateRoot.resolve_setting_bool(&"stid_create_occluder_container_if_missing", root.create_occluder_container_if_missing):
		container = OccluderInstance3D.new()
		container.name = _SETTINGS.get_string_name(&"stid_occluder_container_name")
		root.add_child(container)
		container.owner = root.owner
		root.linked_occluder_container = root.get_path_to(container)
	return container
