# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends "./assembler.gd"

var _staged_scenes := {}


func add_part(part: RoommatePart, block: RoommateBlock, root: RoommateRoot) -> void:
	if not is_instance_valid(part) or not is_instance_valid(part.scene):
		return
	
	var part_origin := block.position * root.block_size + root.block_size * part.anchor
	var new_scene := part.scene.instantiate() as Node
	var node3d_scene := new_scene as Node3D
	if is_instance_valid(node3d_scene):
		node3d_scene.transform = part.scene_transform.translated(part_origin)
	
	var parent_path := part.scene_parent_path
	if not parent_path.is_absolute() and not parent_path.is_empty():
		parent_path = NodePath(("%s/%s" % [root.get_path(), part.scene_parent_path]).simplify_path())
	
	if not _staged_scenes.has(parent_path):
		var new_scenes_array: Array[StagedScene] = []
		_staged_scenes[parent_path] = new_scenes_array
	var staged_scene := StagedScene.new()
	staged_scene.scene = new_scene
	staged_scene.property_overrides = part.scene_property_overrides
	_staged_scenes[parent_path].append(staged_scene)


func assemble_and_attach(root: RoommateRoot) -> void:
	root.clear_scenes()
	var scene_paths: Array[NodePath] = []
	scene_paths.assign(_staged_scenes.keys())
	# creating scenes starting from least nested to most nested
	var sort_by_node_path := func(a: NodePath, b: NodePath) -> bool:
		return a.get_name_count() < b.get_name_count()
	scene_paths.sort_custom(sort_by_node_path)
	for scene_path in scene_paths:
		var staged_scene_items := _staged_scenes[scene_path] as Array[StagedScene]
		var scene_parent := _resolve_scene_parent(root, scene_path)
		if not is_instance_valid(scene_parent):
			for staged_scene_item in staged_scene_items:
				var new_scene := staged_scene_item.scene as Node
				new_scene.queue_free()
			continue
		
		for staged_scene_item in staged_scene_items:
			var new_scene := staged_scene_item.scene as Node
			var property_overrides := staged_scene_item.property_overrides as Dictionary
			scene_parent.add_child(new_scene, root.force_readable_scene_names)
			new_scene.owner = root.owner
			new_scene.add_to_group(_SETTINGS.get_string_name(&"stid_scenes_group"), true)
			
			var node3d_scene := new_scene as Node3D
			if is_instance_valid(node3d_scene) and root.transform_scene_relative_to_part:
				node3d_scene.global_transform = root.global_transform * node3d_scene.transform
			for key in property_overrides:
				if key is String or key is StringName:
					var property_name := key as StringName
					new_scene.set(property_name, property_overrides[property_name])


func _resolve_scene_parent(root: RoommateRoot, parent_path: NodePath) -> Node:
	var scene_parent := root.get_node_or_null(parent_path)
	if parent_path.is_empty():
		push_warning("ROOMMATE: Scene creation. Path is empty.")
	elif not is_instance_valid(scene_parent):
		push_warning("ROOMMATE: Scene creation. Parent doesn't exist at %s." % parent_path)
	
	if is_instance_valid(scene_parent):
		return scene_parent
	elif not RoommateRoot.resolve_setting_bool(&"stid_use_scenes_fallback_parent", root.use_scenes_fallback_parent):
		return null
	
	var fallback_name := _SETTINGS.get_string_name(&"stid_scenes_fallback_parent_name")
	var fallback := root.get_node_or_null(NodePath(fallback_name))
	if not is_instance_valid(fallback):
		fallback = Node3D.new()
		fallback.name = fallback_name
		root.add_child(fallback)
		fallback.owner = root.owner
		fallback.add_to_group(_SETTINGS.get_string_name(&"stid_scenes_group"), true)
	return fallback


class StagedScene:
	var scene: Node = null
	var property_overrides := {}
