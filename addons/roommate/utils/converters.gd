# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted


static func part_to_visual_mesh(part: RoommatePart, surface_id: int) -> ArrayMesh:
	var part_surface_override := part.resolve_surface_override_with_fallback(surface_id)
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
	return part_mesh


static func surface_tools_dict_to_mesh(surface_tools: Dictionary, container: ArrayMesh,
		index: bool, generate_normals: bool, generate_tangents: bool) -> ArrayMesh:
	var new_mesh := ArrayMesh.new()
	if container is ArrayMesh:
		new_mesh = container.duplicate(true) as ArrayMesh
		new_mesh.clear_surfaces()
	for surface_material in surface_tools:
		var tool := surface_tools[surface_material] as SurfaceTool
		if index:
			tool.index()
		if generate_normals:
			tool.generate_normals()
		if generate_tangents:
			tool.generate_tangents()
		tool.commit(new_mesh)
		new_mesh.surface_set_material(new_mesh.get_surface_count() - 1, surface_material)
	return new_mesh
