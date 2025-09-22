# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted

var _ur: EditorUndoRedoManager


func _init(plugin: EditorPlugin) -> void:
	_ur = plugin.get_undo_redo()


func generate_roots(roots: Array[RoommateRoot]) -> void:
	if roots.is_empty():
		return
	
	_ur.create_action("ROOMMATE: Generate Root(s)")
	
	for root in roots:
		# pre-generate scenes
		# removing scenes here so generate won't delete them
		var cleared_scene_infos: Array[Dictionary] = []
		var cleared_scenes := root.get_owned_scenes()
		for scene in cleared_scenes:
			_ur.add_do_method(scene.get_parent(), &"remove_child", scene)
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
		if old_mesh_instance:
			_ur.add_undo_property(old_mesh_instance, &"mesh", old_mesh_instance.mesh)
		elif old_mesh_container:
			pass
		_ur.add_undo_property(root, &"linked_mesh_container", root.linked_mesh_container)
		
		# pre-generate collision
		var collision_shape_container := root.get_node_or_null(root.linked_collision_shape_container) as CollisionShape3D
		if collision_shape_container:
			_ur.add_undo_property(collision_shape_container, &"shape", collision_shape_container.shape)
		
		# pre-generate nav
		var nav_mesh_container := root.get_node_or_null(root.linked_nav_mesh_container) as NavigationRegion3D
		if nav_mesh_container:
			_ur.add_undo_property(nav_mesh_container, &"navigation_mesh", nav_mesh_container.navigation_mesh)
		
		# pre-generate occlusion
		var occluder_container := root.get_node_or_null(root.linked_occluder_container) as OccluderInstance3D
		if occluder_container:
			_ur.add_undo_property(occluder_container, &"occluder", occluder_container.occluder)
		
		# generating everything...
		root.generate()
		
		# post-generate mesh
		var new_mesh_container := root.get_node_or_null(root.linked_mesh_container) as Node3D
		var new_mesh_instance := new_mesh_container as MeshInstance3D
		
		if not old_mesh_container and new_mesh_container:
			_ur.add_do_method(new_mesh_container.get_parent(), &"add_child", new_mesh_container)
			_ur.add_do_property(new_mesh_container, &"owner", new_mesh_container.owner)
			_ur.add_do_reference(new_mesh_container)
			_ur.add_undo_method(new_mesh_container.get_parent(), &"remove_child", new_mesh_container)
		
		if new_mesh_instance:
			_ur.add_do_property(new_mesh_instance, &"mesh", new_mesh_instance.mesh)
		elif new_mesh_container:
			pass
		_ur.add_do_property(root, &"linked_mesh_container", root.linked_mesh_container)
		
		# post-generate collision
		if collision_shape_container:
			_ur.add_do_property(collision_shape_container, &"shape", collision_shape_container.shape)
		
		# post-generate nav
		if nav_mesh_container:
			_ur.add_do_property(nav_mesh_container, &"navigation_mesh", nav_mesh_container.navigation_mesh)
		
		# post-generate occlusion
		if occluder_container:
			_ur.add_do_property(occluder_container, &"occluder", occluder_container.occluder)
		
		# post-generate scenes
		for scene in root.get_owned_scenes():
			_ur.add_do_method(scene.get_parent(), &"add_child", scene)
			_ur.add_do_property(scene, &"owner", scene.owner)
			_ur.add_do_reference(scene)
			_ur.add_undo_method(scene.get_parent(), &"remove_child", scene)
		for info in cleared_scene_infos:
			var node := info[&"node"] as Node
			var parent := info[&"parent"] as Node
			var owner := info[&"owner"] as Node
			_ur.add_undo_method(parent, &"add_child", node)
			_ur.add_undo_property(node, &"owner", owner)
			_ur.add_undo_reference(node)
	
	_ur.commit_action(false)


func snap_roots_areas(roots: Array[RoommateRoot]) -> void:
	var root_areas_map := {}
	for root in roots:
		var areas := root.get_owned_areas()
		if not areas.is_empty():
			root_areas_map[root] = areas
	if root_areas_map.is_empty():
		return
	
	_ur.create_action("ROOMMATE: Snap Root's Area(s) To Blocks")
	for key in root_areas_map:
		var root := key as RoommateRoot
		var areas := root_areas_map[root] as Array[RoommateBlocksArea]
		for area in areas:
			_ur.add_undo_property(area, &"transform", area.transform)
			_ur.add_undo_property(area, &"size", area.size)
			area.snap_to_range(root.global_transform, root.block_size)
			_ur.add_do_property(area, &"transform", area.transform)
			_ur.add_do_property(area, &"size", area.size)
	_ur.commit_action()


func clear_roots_scenes(roots: Array[RoommateRoot]) -> void:
	var scenes: Array[Node] = []
	for root in roots:
		scenes.append_array(root.get_owned_scenes())
	if scenes.is_empty():
		return
	
	_ur.create_action("ROOMMATE: Clear Root's Scene(s)")
	for scene in scenes:
		_ur.add_undo_method(scene.get_parent(), &"add_child", scene)
		_ur.add_undo_property(scene, &"owner", scene.owner)
		_ur.add_undo_reference(scene)
		_ur.add_do_method(scene.get_parent(), &"remove_child", scene)
	_ur.commit_action()


func snap_areas(areas: Array[RoommateBlocksArea]) -> void:
	var root_area_map := {}
	for area in areas:
		var related_root := area.find_root()
		if related_root:
			root_area_map[related_root] = area
	if root_area_map.is_empty():
		return
	
	_ur.create_action("ROOMMATE: Snap Area(s) To Blocks")
	for key in root_area_map:
		var related_root := key as RoommateRoot
		var area := root_area_map[related_root] as RoommateBlocksArea
		_ur.add_undo_property(area, &"transform", area.transform)
		_ur.add_undo_property(area, &"size", area.size)
		area.snap_to_range(related_root.global_transform, related_root.block_size)
		_ur.add_do_property(area, &"transform", area.transform)
		_ur.add_do_property(area, &"size", area.size)
	_ur.commit_action()
