# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./assembler.gd"

var _nav_tool := SurfaceTool.new()


func add_part(part: RoommatePart, block: RoommateBlock, root: RoommateRoot) -> void:
	if not is_instance_valid(part) or not is_instance_valid(part.nav_mesh):
		return
	var part_origin := block.position * root.block_size + root.block_size * part.anchor
	for surface_id in part.nav_mesh.get_surface_count():
		_nav_tool.append_from(part.nav_mesh, surface_id, part.nav_transform.translated(part_origin))


func assemble_and_attach(root: RoommateRoot) -> void:
	var nav_mesh_container := _resolve_nav_mesh_container(root)
	if is_instance_valid(nav_mesh_container):
		_nav_tool.index()
		var new_nav_mesh := NavigationMesh.new()
		if is_instance_valid(nav_mesh_container.navigation_mesh):
			new_nav_mesh = nav_mesh_container.navigation_mesh.duplicate(true) as NavigationMesh
		new_nav_mesh.create_from_mesh(_nav_tool.commit())
		
		if root.try_save_resource(new_nav_mesh, root.path_to_nav_mesh_resource, &"stid_nav_mesh_resource_file_postfix"):
			root.path_to_nav_mesh_resource = new_nav_mesh.resource_path
		nav_mesh_container.navigation_mesh = new_nav_mesh
		nav_mesh_container.update_gizmos()


func _resolve_nav_mesh_container(root: RoommateRoot) -> NavigationRegion3D:
	var container := root.get_node_or_null(root.linked_nav_mesh_container) as NavigationRegion3D
	if is_instance_valid(container):
		return container
	if RoommateRoot.resolve_setting_bool(&"stid_create_nav_mesh_container_if_missing", root.create_nav_mesh_container_if_missing):
		container = NavigationRegion3D.new()
		container.name = _SETTINGS.get_string_name(&"stid_nav_mesh_container_name")
		root.add_child(container)
		container.owner = root.owner
		root.linked_nav_mesh_container = root.get_path_to(container)
	return container
