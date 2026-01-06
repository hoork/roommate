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
	if not part or not part.mesh:
		return
	
	var part_origin := block.position * root.block_size + root.block_size * part.anchor
	
	for surface_id in part.mesh.get_surface_count():
		var part_surface_override := part.resolve_surface_override_with_fallback(surface_id)
		
		# modifying mesh
		var part_mesh := ArrayMesh.new()
		var mesh_arrays := part.mesh.surface_get_arrays(surface_id)
		if part_surface_override.flip_faces:
			if mesh_arrays[Mesh.ARRAY_INDEX] and mesh_arrays[Mesh.ARRAY_INDEX].size() > 0:
				mesh_arrays[Mesh.ARRAY_INDEX].reverse()
			else:
				push_warning("ROOMMATE: Can't flip faces. Mesh array doesn't have indexes.")
		part_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
		var mesh_data_tool := MeshDataTool.new()
		var create_error := mesh_data_tool.create_from_surface(part_mesh, 0)
		if create_error != OK:
			push_error("ROOMMATE: Can't create MeshDataTool from surface. Error %s." % create_error)
		
		for vertex_id in mesh_data_tool.get_vertex_count():
			var uv := mesh_data_tool.get_vertex_uv(vertex_id)
			mesh_data_tool.set_vertex_uv(vertex_id, part_surface_override.uv_transform * uv)
			var color := mesh_data_tool.get_vertex_color(vertex_id)
			mesh_data_tool.set_vertex_color(vertex_id, color.lerp(part_surface_override.color, part_surface_override.color_weight))
		
		part_mesh.clear_surfaces()
		var commit_error := mesh_data_tool.commit_to_surface(part_mesh)
		if commit_error != OK:
			push_error("ROOMMATE: MeshDataTool can't commit to surface. Error %s." % commit_error)
		
		# appending surfaces
		var part_material := part.mesh.surface_get_material(surface_id)
		if part_surface_override.material:
			part_material = part_surface_override.material
			
		if not _surface_tools.has(part_material):
			var new_surface_tool := SurfaceTool.new()
			new_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			new_surface_tool.set_material(part_material)
			_surface_tools[part_material] = new_surface_tool
		var surface_tool := _surface_tools[part_material] as SurfaceTool
		surface_tool.append_from(part_mesh, 0, part.mesh_transform.translated(part_origin))


func assemble_and_attach(root: RoommateRoot) -> void:
	var container := _resolve_mesh_container(root) as MeshInstance3D
	if not container:
		return
	var new_mesh := ArrayMesh.new()
	if container.mesh is ArrayMesh:
		new_mesh = container.mesh.duplicate(true) as ArrayMesh
		new_mesh.clear_surfaces()
	for surface_material in _surface_tools:
		var tool := _surface_tools[surface_material] as SurfaceTool
		if root.index_mesh:
			tool.index()
		if root.generate_normals:
			tool.generate_normals()
		if root.generate_tangents:
			tool.generate_tangents()
		tool.commit(new_mesh)
		new_mesh.surface_set_material(new_mesh.get_surface_count() - 1, surface_material)
	if root.try_save_resource(new_mesh, root.path_to_mesh_resource, &"stid_mesh_resource_file_postfix"):
		root.path_to_mesh_resource = new_mesh.resource_path
	container.mesh = new_mesh


func _resolve_mesh_container(root: RoommateRoot) -> Node3D:
	var container := root.get_node_or_null(root.linked_mesh_container) as Node3D
	if container:
		return container
	if RoommateRoot.resolve_setting_bool(&"stid_create_mesh_container_if_missing", root.create_mesh_container_if_missing):
		container = MeshInstance3D.new()
		container.name = _SETTINGS.get_string_name(&"stid_mesh_container_name")
		root.add_child(container)
		container.owner = root.owner
		root.linked_mesh_container = root.get_path_to(container)
	return container


