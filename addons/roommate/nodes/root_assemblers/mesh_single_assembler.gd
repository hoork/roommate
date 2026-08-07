# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./assembler.gd"

var _surface_tools := {}


func add_part(part: RoommatePart, block: RoommateBlock, root: RoommateRoot) -> void:
	if not is_instance_valid(part) or not is_instance_valid(part.mesh):
		return
	
	var part_origin := block.position * root.block_size + root.block_size * part.anchor
	
	for surface_id in part.mesh.get_surface_count():
		# modifying mesh
		var part_mesh := _CONVERTERS.part_to_visual_mesh(part, surface_id)
		
		var part_surface_override := part.resolve_surface_override_with_fallback(surface_id)
		# appending surfaces
		var part_material := part.mesh.surface_get_material(surface_id)
		if is_instance_valid(part_surface_override.material):
			part_material = part_surface_override.material
			
		if not _surface_tools.has(part_material):
			var new_surface_tool := SurfaceTool.new()
			new_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			new_surface_tool.set_material(part_material)
			_surface_tools[part_material] = new_surface_tool
		var surface_tool := _surface_tools[part_material] as SurfaceTool
		surface_tool.append_from(part_mesh, 0, part.mesh_transform.translated(part_origin))


func assemble_and_attach(root: RoommateRoot) -> void:
	var container := _resolve_mesh_container(root)
	if not is_instance_valid(container):
		return
	var new_mesh := _CONVERTERS.surface_tools_dict_to_mesh(_surface_tools, container.mesh,
			root.index_mesh, root.generate_normals, root.generate_tangents)
	if root.try_save_resource(new_mesh, root.path_to_mesh_resource, &"stid_mesh_resource_file_postfix"):
		root.path_to_mesh_resource = new_mesh.resource_path
	container.mesh = new_mesh


func _resolve_mesh_container(root: RoommateRoot) -> MeshInstance3D:
	var container := root.get_node_or_null(root.linked_mesh_container) as MeshInstance3D
	if is_instance_valid(container):
		return container
	if RoommateRoot.resolve_setting_bool(&"stid_create_mesh_container_if_missing", root.create_mesh_container_if_missing):
		container = MeshInstance3D.new()
		container.name = _SETTINGS.get_string_name(&"stid_mesh_container_name")
		root.add_child(container)
		container.owner = root.owner
		root.linked_mesh_container = root.get_path_to(container)
	return container


