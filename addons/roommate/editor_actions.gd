# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted


static func get_selected_blocks_areas(selection: EditorSelection) -> Array[RoommateBlocksArea]:
	var selected_nodes := selection.get_selected_nodes()
	var areas: Array[RoommateBlocksArea] = []
	for node in selected_nodes:
		if node is RoommateBlocksArea:
			areas.append(node)
	return areas


static func get_selected_roots(selection: EditorSelection) -> Array[RoommateRoot]:
	var selected_nodes := selection.get_selected_nodes()
	var roots: Array[RoommateRoot] = []
	for node in selected_nodes:
		if node is RoommateRoot:
			roots.append(node)
	return roots


static func get_selected_related_roots(selection: EditorSelection) -> Array[RoommateRoot]:
	var selected_nodes := selection.get_selected_nodes()
	var roots: Array[RoommateRoot] = []
	for node in selected_nodes:
		var node_parent := node.get_parent()
		while is_instance_valid(node_parent) and not node_parent is RoommateRoot:
			node_parent = node_parent.get_parent()
		if is_instance_valid(node_parent) and not roots.has(node_parent):
			roots.append(node_parent)
	return roots


static func generate_roots(roots: Array[RoommateRoot], ur: EditorUndoRedoManager) -> void:
	if roots.is_empty():
		return
	
	ur.create_action("ROOMMATE: Generate Root(s)")
	
	for root in roots:
		# pre-generate scenes
		# removing scenes here so generate won't delete them
		var cleared_scene_infos: Array[Dictionary] = []
		var cleared_scenes := root.get_owned_scenes()
		for scene in cleared_scenes:
			ur.add_do_method(scene.get_parent(), &"remove_child", scene)
			cleared_scene_infos.append({
				&"node": scene,
				&"parent": scene.get_parent(),
				&"owner": scene.owner,
			})
		for scene in cleared_scenes:
			scene.get_parent().remove_child(scene)
		
		# pre-generate mesh
		var old_mesh_container := root.get_node_or_null(root.linked_mesh_container) as Node3D
		var old_mesh_instance := old_mesh_container as MeshInstance3D
		if is_instance_valid(old_mesh_instance):
			ur.add_undo_property(old_mesh_instance, &"mesh", old_mesh_instance.mesh)
		elif is_instance_valid(old_mesh_container):
			pass
		ur.add_undo_property(root, &"linked_mesh_container", root.linked_mesh_container)
		
		# pre-generate collision
		var collision_shape_container := root.get_node_or_null(root.linked_collision_shape_container) as CollisionShape3D
		if is_instance_valid(collision_shape_container):
			ur.add_undo_property(collision_shape_container, &"shape", collision_shape_container.shape)
		
		# pre-generate nav
		var nav_mesh_container := root.get_node_or_null(root.linked_nav_mesh_container) as NavigationRegion3D
		if is_instance_valid(nav_mesh_container):
			ur.add_undo_property(nav_mesh_container, &"navigation_mesh", nav_mesh_container.navigation_mesh)
		
		# pre-generate occlusion
		var occluder_container := root.get_node_or_null(root.linked_occluder_container) as OccluderInstance3D
		if is_instance_valid(occluder_container):
			ur.add_undo_property(occluder_container, &"occluder", occluder_container.occluder)
		
		# generating everything...
		root.generate()
		
		# post-generate mesh
		var new_mesh_container := root.get_node_or_null(root.linked_mesh_container) as Node3D
		var new_mesh_instance := new_mesh_container as MeshInstance3D
		
		if not is_instance_valid(old_mesh_container) and is_instance_valid(new_mesh_container):
			ur.add_do_method(new_mesh_container.get_parent(), &"add_child", new_mesh_container)
			ur.add_do_property(new_mesh_container, &"owner", new_mesh_container.owner)
			ur.add_do_reference(new_mesh_container)
			ur.add_undo_method(new_mesh_container.get_parent(), &"remove_child", new_mesh_container)
		
		if is_instance_valid(new_mesh_instance):
			ur.add_do_property(new_mesh_instance, &"mesh", new_mesh_instance.mesh)
		elif is_instance_valid(new_mesh_container):
			pass
		ur.add_do_property(root, &"linked_mesh_container", root.linked_mesh_container)
		
		# post-generate collision
		if is_instance_valid(collision_shape_container):
			ur.add_do_property(collision_shape_container, &"shape", collision_shape_container.shape)
		
		# post-generate nav
		if is_instance_valid(nav_mesh_container):
			ur.add_do_property(nav_mesh_container, &"navigation_mesh", nav_mesh_container.navigation_mesh)
		
		# post-generate occlusion
		if is_instance_valid(occluder_container):
			ur.add_do_property(occluder_container, &"occluder", occluder_container.occluder)
		
		# post-generate scenes
		for scene in root.get_owned_scenes():
			ur.add_do_method(scene.get_parent(), &"add_child", scene)
			ur.add_do_property(scene, &"owner", scene.owner)
			ur.add_do_reference(scene)
			ur.add_undo_method(scene.get_parent(), &"remove_child", scene)
		for info in cleared_scene_infos:
			var node := info[&"node"] as Node
			var parent := info[&"parent"] as Node
			var owner := info[&"owner"] as Node
			ur.add_undo_method(parent, &"add_child", node)
			ur.add_undo_property(node, &"owner", owner)
			ur.add_undo_reference(node)
	
	ur.commit_action(false)


static func snap_roots_areas(roots: Array[RoommateRoot], ur: EditorUndoRedoManager) -> void:
	if roots.is_empty():
		return
	
	var root_areas_map := {}
	for root in roots:
		var areas := root.get_owned_areas()
		if not areas.is_empty():
			root_areas_map[root] = areas
	if root_areas_map.is_empty():
		return
	
	ur.create_action("ROOMMATE: Snap Root's Area(s) To Blocks")
	for key in root_areas_map:
		var root := key as RoommateRoot
		var areas := root_areas_map[root] as Array[RoommateBlocksArea]
		for area in areas:
			ur.add_undo_property(area, &"transform", area.transform)
			ur.add_undo_property(area, &"size", area.size)
			area.snap_to_range(root.global_transform, root.block_size)
			ur.add_do_property(area, &"transform", area.transform)
			ur.add_do_property(area, &"size", area.size)
	ur.commit_action()


static func clear_roots_scenes(roots: Array[RoommateRoot], ur: EditorUndoRedoManager) -> void:
	if roots.is_empty():
		return
	
	var scenes: Array[Node] = []
	for root in roots:
		scenes.append_array(root.get_owned_scenes())
	if scenes.is_empty():
		return
	
	ur.create_action("ROOMMATE: Clear Root's Scene(s)")
	for scene in scenes:
		ur.add_undo_method(scene.get_parent(), &"add_child", scene)
		ur.add_undo_property(scene, &"owner", scene.owner)
		ur.add_undo_reference(scene)
		ur.add_do_method(scene.get_parent(), &"remove_child", scene)
	ur.commit_action()


static func snap_areas(areas: Array[RoommateBlocksArea], ur: EditorUndoRedoManager) -> void:
	if areas.is_empty():
		return
	
	var root_area_map := {}
	for area in areas:
		var related_root := area.find_root()
		if is_instance_valid(related_root):
			root_area_map[related_root] = area
	if root_area_map.is_empty():
		return
	
	ur.create_action("ROOMMATE: Snap Area(s) To Blocks")
	for key in root_area_map:
		var related_root := key as RoommateRoot
		var area := root_area_map[related_root] as RoommateBlocksArea
		ur.add_undo_property(area, &"transform", area.transform)
		ur.add_undo_property(area, &"size", area.size)
		area.snap_to_range(related_root.global_transform, related_root.block_size)
		ur.add_do_property(area, &"transform", area.transform)
		ur.add_do_property(area, &"size", area.size)
	ur.commit_action()


static func generate_selected_roots(selection: EditorSelection, ur: EditorUndoRedoManager) -> void:
	generate_roots(get_selected_roots(selection), ur)


static func generate_selected_related_roots(selection: EditorSelection, ur: EditorUndoRedoManager) -> void:
	generate_roots(get_selected_related_roots(selection), ur)


static func snap_selected_blocks_areas(selection: EditorSelection, ur: EditorUndoRedoManager) -> void:
	snap_areas(get_selected_blocks_areas(selection), ur)


static func snap_selected_roots_areas(selection: EditorSelection, ur: EditorUndoRedoManager) -> void:
	snap_roots_areas(get_selected_roots(selection), ur)


static func clear_selected_roots_scenes(selection: EditorSelection, ur: EditorUndoRedoManager) -> void:
	clear_roots_scenes(get_selected_roots(selection), ur)
