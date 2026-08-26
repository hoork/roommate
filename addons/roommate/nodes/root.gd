# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
@icon("../icons/root.svg")
class_name RoommateRoot
extends Node3D
## Node that creates mesh, collision and scenes. 
## 
## Set [RoommateBlocksArea] or it's derived nodes as a child to affect generation.

signal generated

enum SettingBool { 
	FROM_SETTINGS = -1, 
	FALSE = 0, 
	TRUE = 1, 
}

const MESH_SINGLE := &"mtid_single"
const MESH_CHUNKS := &"mtid_chunks"

const COLLISION_CONCAVE := &"csid_concave"
const COLLISION_CONVEX := &"csid_convex"

const SCENES_ALL := &"stid_all"

const NAV_SINGLE := &"nmtid_single"

const OCCLUDER_SINGLE := &"otid_single"

const _SETTINGS := preload("../plugin_settings.gd")
const _INTERNAL_STYLE := preload("../resources/styles/internal_style.gd")

const _ASSEMBLER := preload("./root_assemblers/assembler.gd")
const _ASSEMBLERS := {
	MESH_SINGLE: preload("./root_assemblers/mesh_single_assembler.gd"),
	MESH_CHUNKS: preload("./root_assemblers/mesh_chunks_assembler.gd"),
	COLLISION_CONCAVE: preload("./root_assemblers/collision_single_concave_assembler.gd"),
	COLLISION_CONVEX: preload("./root_assemblers/collision_single_convex_assembler.gd"),
	SCENES_ALL: preload("./root_assemblers/scenes_all_assembler.gd"),
	NAV_SINGLE: preload("./root_assemblers/nav_single_assembler.gd"),
	OCCLUDER_SINGLE: preload("./root_assemblers/occluder_single_assembler.gd"),
}

@export var block_size := 1.0:
	set(value):
		block_size = value if value > 0 else 1
		for node in find_children("*", &"RoommateBlocksArea", true, false):
			var area := node as RoommateBlocksArea
			area.update_gizmos()

@export var scale_with_block_size := true
@export var force_white_vertex_color := true
@export var auto_create_resource_files := SettingBool.FROM_SETTINGS
@export var generate_on_ready := false

@export_group("Mesh")
@export_enum(MESH_SINGLE, MESH_CHUNKS) var mesh_type := String(MESH_SINGLE)
@export var mesh_chunk_size := Vector3i.ONE * 3
@export_node_path("MeshInstance3D") var linked_mesh_container: NodePath
@export_file("*.tres", "*.res") var path_to_mesh_resource: String
@export_dir var path_to_mesh_resources_directory: String
@export var create_mesh_container_if_missing := SettingBool.FROM_SETTINGS
@export var index_mesh := true
@export var generate_normals := false
@export var generate_tangents := true

@export_group("Collision")
@export_enum(COLLISION_CONCAVE, COLLISION_CONVEX) var collision_shape := String(COLLISION_CONCAVE)
@export_node_path("CollisionShape3D") var linked_collision_shape_container: NodePath
@export_file("*.tres", "*.res") var path_to_collision_shape_resource: String
@export var create_collision_container_if_missing := SettingBool.FROM_SETTINGS

@export_group("Scenes")
@export_enum(SCENES_ALL) var scenes_type := String(SCENES_ALL)
@export var transform_scene_relative_to_part := true
@export var use_scenes_fallback_parent := SettingBool.FROM_SETTINGS
@export var force_readable_scene_names := true

@export_group("Navigation")
@export_enum(NAV_SINGLE) var nav_mesh_type := String(NAV_SINGLE)
@export_node_path("NavigationRegion3D") var linked_nav_mesh_container: NodePath
@export_file("*.tres", "*.res") var path_to_nav_mesh_resource: String
@export var create_nav_mesh_container_if_missing := SettingBool.FROM_SETTINGS

@export_group("Occlusion")
@export_enum(OCCLUDER_SINGLE) var occluder_type := String(OCCLUDER_SINGLE)
@export_node_path("OccluderInstance3D") var linked_occluder_container: NodePath
@export_file("*.tres", "*.res", "*.occ") var path_to_occluder_resource: String
@export var create_occluder_container_if_missing := SettingBool.FROM_SETTINGS

var _part_processors := {
	RoommateBlock.SPACE_TYPE: process_space_block_part,
	RoommateBlock.OBLIQUE_TYPE: process_oblique_block_part,
	RoommateBlock.OBLIQUE_FILLING_TYPE: process_oblique_filling_type,
	RoommateBlock.NODRAW_TYPE: process_nodraw_block_part,
}


static func process_space_block_part(slot_id: StringName, part: RoommatePart, block: RoommateBlock, 
		all_blocks: Dictionary) -> RoommatePart:
	if not is_instance_valid(part):
		return null
	var next_position := block.position + (part.flow as Vector3i)
	var next_block := all_blocks.get(next_position) as RoommateBlock
	if not is_instance_valid(next_block):
		return part
	if part.flow == Vector3.ZERO:
		return part
	if next_block.type_id == RoommateBlock.OBLIQUE_FILLING_TYPE:
		return part
	
	var oblique_part := next_block.slots.get(RoommateBlock.Slot.OBLIQUE) as RoommatePart
	var block_rotation := Quaternion.from_euler(next_block.rotation)
	var block_forward := block_rotation * Vector3.FORWARD
	var block_bottom := block_rotation * Vector3.DOWN
	if is_instance_valid(oblique_part) and (is_equal_approx(block_forward.dot(part.flow), -1) or is_equal_approx(block_bottom.dot(part.flow), -1)):
		return part
	return null


static func process_oblique_block_part(slot_id: StringName, part: RoommatePart, block: RoommateBlock, 
		all_blocks: Dictionary) -> RoommatePart:
	if not is_instance_valid(part):
		return null
	var next_position := block.position + (part.flow as Vector3i)
	var next_block := all_blocks.get(next_position) as RoommateBlock
	if slot_id == RoommateBlock.Slot.OBLIQUE:
		return part
	if slot_id == RoommateBlock.Slot.OBLIQUE_SIDE_LEFT or slot_id == RoommateBlock.Slot.OBLIQUE_SIDE_RIGHT:
		return part if is_instance_valid(next_block) and next_block.type_id != RoommateBlock.OBLIQUE_TYPE else null
	if not is_instance_valid(next_block):
		return part
	if part.flow == Vector3.ZERO:
		return part
	return null


static func process_oblique_filling_type(slot_id: StringName, part: RoommatePart, block: RoommateBlock, 
		all_blocks: Dictionary) -> RoommatePart:
	return null


static func process_nodraw_block_part(slot_id: StringName, part: RoommatePart, block: RoommateBlock, 
		all_blocks: Dictionary) -> RoommatePart:
	return null


static func resolve_setting_bool(setting_id: StringName, value: SettingBool) -> bool:
	if value == SettingBool.FROM_SETTINGS:
		return _SETTINGS.get_bool(setting_id)
	return value == SettingBool.TRUE


func _ready() -> void:
	if not Engine.is_editor_hint() and generate_on_ready:
		generate()


func generate() -> void:
	var blocks := create_blocks()
	generate_with(blocks)


func generate_with(all_blocks: Dictionary) -> void:
	if all_blocks.is_empty():
		return
	
	var assemblers: Array[_ASSEMBLER] = []
	for type in [mesh_type, collision_shape, scenes_type, nav_mesh_type, occluder_type]:
		if not _ASSEMBLERS.has(type):
			continue
		var assembler: _ASSEMBLER = _ASSEMBLERS[type].new()
		assemblers.append(assembler)
	
	# generating everything
	for block_position in all_blocks:
		var block := all_blocks[block_position] as RoommateBlock
		if not _part_processors.has(block.type_id):
			push_error("ROOMMATE: Unknown block type: %s." % block.type_id)
			continue
		var processor := _part_processors[block.type_id] as Callable
		for slot_id in block.slots:
			var part := block.slots.get(slot_id) as RoommatePart
			var processed_part := processor.call(slot_id, part, block, all_blocks) as RoommatePart
			if is_instance_valid(processed_part):
				for assembler in assemblers:
					assembler.add_part(processed_part, block, self)
	
	for assembler in assemblers:
		assembler.assemble_and_attach(self)
	
	if not Engine.is_editor_hint():
		generated.emit()


func create_blocks() -> Dictionary:
	# Searching for areas which are not children of other root nodes
	var areas := get_owned_areas()
	if areas.size() == 0:
		push_warning("ROOMMATE: RoommateRoot doesn't own any blocks areas.")
		return {}
	
	var sort_areas := func (a: RoommateBlocksArea, b: RoommateBlocksArea) -> bool:
		if a.blocks_apply_order == b.blocks_apply_order:
			return a.get_type_order() < b.get_type_order()
		return a.blocks_apply_order < b.blocks_apply_order
	areas.sort_custom(sort_areas)
	
	# Creating all the blocks that defined by areas and applying styles
	var all_blocks := {}
	for area in areas:
		var area_blocks := area.create_blocks(global_transform, block_size)
		for new_block_position in area_blocks:
			var new_block := area_blocks[new_block_position] as RoommateBlock
			if not is_instance_valid(new_block):
				continue
			if new_block.marked_for_deletion:
				all_blocks.erase(new_block_position)
				continue
			all_blocks[new_block_position] = new_block
	
	# Applying internal style
	var internal_style := _INTERNAL_STYLE.new()
	if scale_with_block_size:
		internal_style.scale = Vector3.ONE * block_size
	internal_style.force_white_vertex_color = force_white_vertex_color
	internal_style.apply(all_blocks)
	
	# Applying global style
	var global_style_path := _SETTINGS.get_string(&"stid_global_style")
	if ResourceLoader.exists(global_style_path):
		var global_style := load(String(global_style_path)) as RoommateStyle
		if is_instance_valid(global_style):
			global_style.apply(all_blocks)
	
	# Applying stylers
	var stylers := get_owned_stylers()
	var sort_stylers := func (a: RoommateStyler, b: RoommateStyler) -> bool:
		return a.style_apply_order < b.style_apply_order
	stylers.sort_custom(sort_stylers)
	for styler in stylers:
		styler.apply_style(all_blocks, global_transform, block_size)
	return all_blocks


func register_block_type_id(block_type_id: StringName, part_processor: Callable) -> void:
	_part_processors[block_type_id] = part_processor


func clear_scenes() -> void:
	for scene in get_owned_scenes():
		var parent := scene.get_parent()
		if is_instance_valid(parent):
			parent.remove_child(scene)
		scene.queue_free()


func snap_areas() -> void:
	var areas := get_owned_areas()
	for area in areas:
		area.snap_to_range(global_transform, block_size)


func get_owned_nodes(node_class_name: StringName) -> Array[Node]:
	var child_nodes := find_children("*", node_class_name, true, false)
	var child_roots := find_children("*", &"RoommateRoot", true, false)
	var nodes: Array[Node] = []
	for target in child_nodes:
		var owned := true
		for parent in child_roots:
			if parent.is_ancestor_of(target):
				owned = false
				break
		if owned:
			nodes.append(target)
	return nodes


func get_owned_areas() -> Array[RoommateBlocksArea]:
	var areas: Array[RoommateBlocksArea] = []
	areas.assign(get_owned_nodes(&"RoommateBlocksArea"))
	return areas


func get_owned_stylers() -> Array[RoommateStyler]:
	var stylers: Array[RoommateStyler] = []
	stylers.assign(get_owned_nodes(&"RoommateStyler"))
	return stylers


func get_owned_scenes() -> Array[Node]:
	if not is_inside_tree():
		push_warning("ROOMMATE: RoommateRoot must be inside tree when getting owned scenes.")
		return []
	var all_scenes := get_tree().get_nodes_in_group(_SETTINGS.get_string_name(&"stid_scenes_group"))
	var child_roots := find_children("*", &"RoommateRoot", true, false)
	var nodes: Array[Node] = []
	for target in all_scenes:
		if not is_ancestor_of(target):
			continue
		var owned := true
		for parent in child_roots:
			if parent.is_ancestor_of(target):
				owned = false
				break
		if owned:
			nodes.append(target)
	return nodes


func try_save_resource(new_resource: Resource, path_to_resource: String, postfix_setting: StringName,
		before_postfix_string := String()) -> bool:
	var path := path_to_resource
	var auto_creation_requested := resolve_setting_bool(&"stid_auto_create_resource_files", auto_create_resource_files) and path.is_empty()
	if auto_creation_requested:
		if not is_inside_tree():
			push_error("ROOMMATE: RoommateRoot must be inside tree when saving resource.")
			return false
		var scene_node := get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene
		var scene_path := scene_node.scene_file_path
		var postfix := _SETTINGS.get_string(postfix_setting)
		path = scene_path.path_join("..").simplify_path().path_join(name.to_snake_case() + before_postfix_string + postfix)
	if ResourceLoader.exists(path) or auto_creation_requested:
		var save_error := ResourceSaver.save(new_resource, path)
		if save_error != OK:
			push_error("ROOMMATE: Can't save resource to %s. Error %s." % [path, save_error])
			return false
		new_resource.take_over_path(path)
		return true
	return false
