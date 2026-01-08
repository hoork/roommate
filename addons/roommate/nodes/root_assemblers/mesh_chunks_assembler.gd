# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./assembler.gd"

#{
#	chunk_position_1: {
#		surface_material_a: SurfaceTool,
#		surface_material_b: SurfaceTool,
#	},
#	chunk_position_2: {
#		surface_material_a: SurfaceTool,
#		surface_material_x: SurfaceTool,
#	}
#}
var _chunks := {}


func add_part(part: RoommatePart, block: RoommateBlock, root: RoommateRoot) -> void:
	if not part or not part.mesh:
		return
	
	var chunk_size := Vector3.ZERO
	chunk_size.x = maxf(root.mesh_chunk_size.x, 1)
	chunk_size.y = maxf(root.mesh_chunk_size.y, 1)
	chunk_size.z = maxf(root.mesh_chunk_size.z, 1)
	var chunk_position := Vector3i.ZERO
	var block_position := Vector3(block.position)
	chunk_position.x = floori(block_position.x / chunk_size.x)
	chunk_position.y = floori(block_position.y / chunk_size.y)
	chunk_position.z = floori(block_position.z / chunk_size.z)
	
	var part_origin := block.position * root.block_size + root.block_size * part.anchor
	
	for surface_id in part.mesh.get_surface_count():
		# modifying mesh
		var part_mesh := _CONVERTERS.part_to_visual_mesh(part, surface_id)
	
		var part_surface_override := part.resolve_surface_override_with_fallback(surface_id)
		# appending surfaces
		var part_material := part.mesh.surface_get_material(surface_id)
		if part_surface_override.material:
			part_material = part_surface_override.material
		
		if not _chunks.has(chunk_position):
			_chunks[chunk_position] = {}
		var chunk_surfaces := _chunks[chunk_position] as Dictionary
		
		if not chunk_surfaces.has(part_material):
			var new_surface_tool := SurfaceTool.new()
			new_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			new_surface_tool.set_material(part_material)
			chunk_surfaces[part_material] = new_surface_tool
		var surface_tool := chunk_surfaces[part_material] as SurfaceTool
		surface_tool.append_from(part_mesh, 0, part.mesh_transform.translated(part_origin))


func assemble_and_attach(root: RoommateRoot) -> void:
	var container := _resolve_mesh_container(root)
	if not container:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for chunk_position in _chunks:
		var chunk_surfaces := _chunks[chunk_position] as Dictionary
		var chunk_container := _resolve_mesh_chunk(chunk_position, container, root)
		if not chunk_container:
			continue
		var new_mesh := _CONVERTERS.surface_tools_dict_to_mesh(chunk_surfaces, chunk_container.mesh,
				root.index_mesh, root.generate_normals, root.generate_tangents)
		# TODO: save chunk files here
		chunk_container.mesh = new_mesh


func _resolve_mesh_chunk(chunk_position: Vector3i, container: Node3D, root: RoommateRoot) -> MeshInstance3D:
	var chunk_container := MeshInstance3D.new()
	chunk_container.name = _vector_to_snake_case(chunk_position)
	container.add_child(chunk_container, true)
	chunk_container.owner = root.owner
	return chunk_container


func _resolve_mesh_container(root: RoommateRoot) -> Node3D:
	var container := root.get_node_or_null(root.linked_mesh_container) as Node3D
	if container:
		return container
	if RoommateRoot.resolve_setting_bool(&"stid_create_mesh_container_if_missing", root.create_mesh_container_if_missing):
		container = Node3D.new()
		container.name = _SETTINGS.get_string_name(&"stid_mesh_container_name")
		root.add_child(container)
		container.owner = root.owner
		root.linked_mesh_container = root.get_path_to(container)
	return container


func _vector_to_snake_case(vector: Vector3i) -> String:
	var result := "%d_%d_%d" % [vector.x, vector.y, vector.z]
	return result.replace("-", "m")
