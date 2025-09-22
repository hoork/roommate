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

const MESH_SINGLE := &"mtid_single"

const COLLISION_CONCAVE := &"csid_concave"
const COLLISION_CONVEX := &"csid_convex"

const NAV_SINGLE := &"nmtid_single"

const OCCLUDER_SINGLE := &"otid_single"

const _SETTINGS := preload("../plugin_settings.gd")
const _INTERNAL_STYLE := preload("../resources/internal_style.gd")

@export var block_size := 1.0:
	set(value):
		block_size = value if value > 0 else 1
		for node in find_children("*", &"RoommateBlocksArea", true, false):
			var area := node as RoommateBlocksArea
			area.update_gizmos()

@export var scale_with_block_size := true
@export var force_white_vertex_color := true
@export var auto_create_resource_files := false
@export var generate_on_ready := false

@export_group("Mesh")
@export_enum(MESH_SINGLE) var mesh_type := String(MESH_SINGLE)
@export_node_path("MeshInstance3D") var linked_mesh_container: NodePath
@export_file("*.tres", "*.res") var path_to_mesh_resource: String
@export var create_mesh_container_if_missing := true
@export var index_mesh := true
@export var generate_normals := true
@export var generate_tangents := true

@export_group("Collision")
@export_enum(COLLISION_CONCAVE, COLLISION_CONVEX) var collision_shape := String(COLLISION_CONCAVE)
@export_node_path("CollisionShape3D") var linked_collision_shape_container: NodePath
@export_file("*.tres", "*.res") var path_to_collision_shape_resource: String

@export_group("Scenes")
@export var transform_scene_relative_to_part := true
@export var use_scenes_fallback_parent := true
@export var force_readable_scene_names := true

@export_group("Navigation")
@export_enum(NAV_SINGLE) var nav_mesh_type := String(NAV_SINGLE)
@export_node_path("NavigationRegion3D") var linked_nav_mesh_container: NodePath
@export_file("*.tres", "*.res") var path_to_nav_mesh_resource: String

@export_group("Occlusion")
@export_enum(OCCLUDER_SINGLE) var occluder_type := String(OCCLUDER_SINGLE)
@export_node_path("OccluderInstance3D") var linked_occluder_container: NodePath
@export_file("*.tres", "*.res", "*.occ") var path_to_occluder_resource: String

var _part_processors := {
	RoommateBlock.SPACE_TYPE: _process_space_block_part,
	RoommateBlock.OBLIQUE_TYPE: _process_oblique_block_part,
	RoommateBlock.NODRAW_TYPE: _process_nodraw_block_part,
}


func _ready() -> void:
	if not Engine.is_editor_hint() and generate_on_ready:
		generate()


func generate() -> void:
	var blocks := create_blocks()
	generate_with(blocks)


func generate_with(all_blocks: Dictionary) -> void:
	if all_blocks.is_empty():
		return
	
	# creating collections
	var surface_tools := {}
	var collision_faces := PackedVector3Array()
	var staged_scenes := {}
	var nav_tool := SurfaceTool.new()
	var occluder_tool := SurfaceTool.new()
	
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
			if processed_part:
				_generate_part(processed_part, block, surface_tools, 
						collision_faces, staged_scenes, nav_tool, occluder_tool)
	
	# applying mesh
	match StringName(mesh_type):
		MESH_SINGLE:
			_generate_single_mesh(surface_tools)
		_:
			push_error("ROOMMATE: Unknown mesh type id %s." % mesh_type)
	
	# applying collision
	var collision_shape_container := get_node_or_null(linked_collision_shape_container) as CollisionShape3D
	if collision_shape_container:
		var new_shape: Shape3D
		match StringName(collision_shape):
			COLLISION_CONCAVE:
				var concave := ConcavePolygonShape3D.new()
				if collision_shape_container.shape is ConcavePolygonShape3D:
					concave = collision_shape_container.shape.duplicate(true) as ConcavePolygonShape3D
				concave.set_faces(collision_faces)
				new_shape = concave
			COLLISION_CONVEX:
				var convex := ConvexPolygonShape3D.new()
				if collision_shape_container.shape is ConvexPolygonShape3D:
					convex = collision_shape_container.shape.duplicate(true) as ConvexPolygonShape3D
				convex.points = collision_faces.duplicate()
				new_shape = convex
			_:
				push_error("ROOMMATE: Unknown collision shape id %s." % collision_shape)
		if _try_save_resource(new_shape, path_to_collision_shape_resource, &"stid_collision_shape_resource_file_postfix"):
			path_to_collision_shape_resource = new_shape.resource_path
		collision_shape_container.shape = new_shape
	
	#applying scenes
	clear_scenes()
	var scene_paths: Array[NodePath] = []
	scene_paths.assign(staged_scenes.keys())
	# creating scenes starting from least nested to most nested
	var sort_by_node_path := func(a: NodePath, b: NodePath) -> bool:
		return a.get_name_count() < b.get_name_count()
	scene_paths.sort_custom(sort_by_node_path)
	for scene_path in scene_paths:
		var staged_scene_items := staged_scenes[scene_path] as Array[Dictionary]
		var scene_parent := _resolve_scene_parent(scene_path)
		if not scene_parent:
			for staged_scene_item in staged_scene_items:
				var new_scene := staged_scene_item[&"scene"] as Node
				new_scene.queue_free()
			continue
		
		for staged_scene_item in staged_scene_items:
			var new_scene := staged_scene_item[&"scene"] as Node
			var property_overrides := staged_scene_item[&"property_overrides"] as Dictionary
			scene_parent.add_child(new_scene, force_readable_scene_names)
			new_scene.owner = owner
			new_scene.add_to_group(_SETTINGS.get_string(&"stid_scenes_group"), true)
			
			var node3d_scene := new_scene as Node3D
			if node3d_scene and transform_scene_relative_to_part:
				node3d_scene.global_transform = global_transform * node3d_scene.transform
			for key in property_overrides:
				if key is String or key is StringName:
					var property_name := key as StringName
					new_scene.set(property_name, property_overrides[property_name])
	
	# applying navigation
	var nav_mesh_container := get_node_or_null(linked_nav_mesh_container) as NavigationRegion3D
	if nav_mesh_container:
		match StringName(nav_mesh_type):
			NAV_SINGLE:
				nav_tool.index()
				var new_nav_mesh := NavigationMesh.new()
				if nav_mesh_container.navigation_mesh:
					new_nav_mesh = nav_mesh_container.navigation_mesh.duplicate(true) as NavigationMesh
				new_nav_mesh.create_from_mesh(nav_tool.commit())
				
				if _try_save_resource(new_nav_mesh, path_to_nav_mesh_resource, &"stid_nav_mesh_resource_file_postfix"):
					path_to_nav_mesh_resource = new_nav_mesh.resource_path
				nav_mesh_container.navigation_mesh = new_nav_mesh
				nav_mesh_container.update_gizmos()
			_:
				push_error("ROOMMATE: Unknown nav mesh type id %s." % nav_mesh_type)
	
	# applying occluder
	var occluder_container := get_node_or_null(linked_occluder_container) as OccluderInstance3D
	if occluder_container:
		match StringName(occluder_type):
			OCCLUDER_SINGLE:
				occluder_tool.index()
				var occluder := ArrayOccluder3D.new()
				var occluder_arrays := occluder_tool.commit_to_arrays()
				var vertices := PackedVector3Array(occluder_arrays[Mesh.ARRAY_VERTEX])
				var indices := PackedInt32Array(occluder_arrays[Mesh.ARRAY_INDEX])
				occluder.set_arrays(vertices, indices)
				
				if _try_save_resource(occluder, path_to_occluder_resource, &"stid_occluder_resource_file_postfix"):
					path_to_occluder_resource = occluder.resource_path
				occluder_container.occluder = occluder
				occluder_container.update_gizmos()
			_:
				push_error("ROOMMATE: Unknown occluder type id %s." % occluder_type)
	
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
			if not new_block:
				continue
			if new_block.type_id == RoommateBlock.OUT_OF_BOUNDS_TYPE:
				all_blocks.erase(new_block_position)
				continue
			all_blocks[new_block_position] = new_block
	
	# Applying internal style
	var internal_style := _INTERNAL_STYLE.new()
	if scale_with_block_size:
		internal_style.scale = Vector3.ONE * block_size
	internal_style.force_white_vertex_color = force_white_vertex_color
	internal_style.apply(all_blocks)
	
	# Applying stylers
	var stylers := get_owned_stylers()
	var sort_stylers := func (a: RoommateStyler, b: RoommateStyler) -> bool:
		return a.style_apply_order < b.style_apply_order
	stylers.sort_custom(sort_stylers)
	for styler in stylers:
		styler.apply_style(all_blocks, global_transform, block_size)
	return all_blocks


func register_block_type_id(block_type_id: StringName, part_processor: Callable) -> void:
	if _part_processors.has(block_type_id):
		push_error("ROOMMATE: Block type %s already registered." % block_type_id)
		return
	_part_processors[block_type_id] = part_processor


func clear_scenes() -> void:
	for scene in get_owned_scenes():
		var parent := scene.get_parent()
		if parent:
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
	var filter_by_parents := func (target: Node) -> bool:
		for parent in child_roots:
			if parent.is_ancestor_of(target):
				return false
		return true
	nodes.assign(child_nodes.filter(filter_by_parents))
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
	var all_scenes := get_tree().get_nodes_in_group(_SETTINGS.get_string(&"stid_scenes_group"))
	var child_roots := find_children("*", &"RoommateRoot", true, false)
	var filter_by_parents_and_self := func (target: Node) -> bool:
		if not is_ancestor_of(target):
			return false
		for parent in child_roots:
			if parent.is_ancestor_of(target):
				return false
		return true
	return all_scenes.filter(filter_by_parents_and_self) as Array[Node]


func _generate_part(part: RoommatePart, parent_block: RoommateBlock, 
		surface_tools: Dictionary, collision_faces: PackedVector3Array,
		staged_scenes: Dictionary, nav_tool: SurfaceTool, 
		occluder_tool: SurfaceTool) -> void:
	if not part:
		return
	var part_origin := parent_block.position * block_size + block_size * part.anchor
	
	if part.collision_mesh:
		var part_collision_faces := part.collision_transform.translated(part_origin) * part.collision_mesh.get_faces()
		collision_faces.append_array(part_collision_faces)
	
	if part.scene:
		var new_scene := part.scene.instantiate() as Node
		var node3d_scene := new_scene as Node3D
		if node3d_scene:
			node3d_scene.transform = part.scene_transform.translated(part_origin)
		
		var parent_path := part.scene_parent_path
		if not parent_path.is_absolute() and not parent_path.is_empty():
			parent_path = NodePath(("%s/%s" % [get_path(), part.scene_parent_path]).simplify_path())
		
		if not staged_scenes.has(parent_path):
			var new_scenes_array: Array[Dictionary] = []
			staged_scenes[parent_path] = new_scenes_array
		staged_scenes[parent_path].append({
			&"scene": new_scene,
			&"property_overrides": part.scene_property_overrides,
		})
	
	if part.nav_mesh:
		for surface_id in part.nav_mesh.get_surface_count():
			nav_tool.append_from(part.nav_mesh, surface_id, part.nav_transform.translated(part_origin))
	
	if part.occluder_mesh:
		for surface_id in part.occluder_mesh.get_surface_count():
			occluder_tool.append_from(part.occluder_mesh, surface_id, 
					part.occluder_transform.translated(part_origin))
	
	if not part.mesh:
		return
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
			
		if not surface_tools.has(part_material):
			var new_surface_tool := SurfaceTool.new()
			new_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			new_surface_tool.set_material(part_material)
			surface_tools[part_material] = new_surface_tool
		var surface_tool := surface_tools[part_material] as SurfaceTool
		surface_tool.append_from(part_mesh, 0, part.mesh_transform.translated(part_origin))


func _generate_single_mesh(surface_tools: Dictionary) -> void:
	var container := _resolve_mesh_container() as MeshInstance3D
	if not container:
		return
	var new_mesh := ArrayMesh.new()
	if container.mesh is ArrayMesh:
		new_mesh = container.mesh.duplicate(true) as ArrayMesh
		new_mesh.clear_surfaces()
	for surface_material in surface_tools:
		var tool := surface_tools[surface_material] as SurfaceTool
		if index_mesh:
			tool.index()
		if generate_normals:
			tool.generate_normals()
		if generate_tangents:
			tool.generate_tangents()
		tool.commit(new_mesh)
		new_mesh.surface_set_material(new_mesh.get_surface_count() - 1, surface_material)
	if _try_save_resource(new_mesh, path_to_mesh_resource, &"stid_mesh_resource_file_postfix"):
		path_to_mesh_resource = new_mesh.resource_path
	container.mesh = new_mesh


func _resolve_mesh_container() -> Node3D:
	var container := get_node_or_null(linked_mesh_container) as Node3D
	if container:
		if mesh_type == MESH_SINGLE and not container is MeshInstance3D:
			push_error("ROOMMATE: Wrong type of mesh container. MeshInstance3D expected.")
			return null
		return container
	if create_mesh_container_if_missing:
		container = MeshInstance3D.new() if mesh_type == MESH_SINGLE else Node3D.new()
		container.name = _SETTINGS.get_string(&"stid_mesh_container_name")
		add_child(container)
		container.owner = owner
		linked_mesh_container = get_path_to(container)
	return container


func _resolve_scene_parent(parent_path: NodePath) -> Node:
	var scene_parent := get_node_or_null(parent_path)
	if parent_path.is_empty():
		push_warning("ROOMMATE: Scene creation. Path is empty.")
	elif not scene_parent:
		push_warning("ROOMMATE: Scene creation. Parent doesn't exist at %s." % parent_path)
	
	if scene_parent:
		return scene_parent
	elif not use_scenes_fallback_parent:
		return null
	
	var fallback_name := _SETTINGS.get_string(&"stid_scenes_fallback_parent_name")
	var fallback := get_node_or_null(NodePath(fallback_name))
	if not fallback:
		fallback = Node3D.new()
		fallback.name = fallback_name
		add_child(fallback)
		fallback.owner = owner
		fallback.add_to_group(_SETTINGS.get_string(&"stid_scenes_group"), true)
	return fallback


func _try_save_resource(new_resource: Resource, path_to_resource: String, postfix_setting: StringName) -> bool:
	var path := path_to_resource
	var auto_creation_requested := auto_create_resource_files and path.is_empty()
	if auto_creation_requested:
		if not is_inside_tree():
			push_error("ROOMMATE: RoommateRoot must be inside tree when saving resource.")
			return false
		var scene_node := get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene
		var scene_path := scene_node.scene_file_path
		var postfix := _SETTINGS.get_string(postfix_setting)
		path = scene_path.path_join("..").simplify_path().path_join(name.to_snake_case() + postfix)
	if ResourceLoader.exists(path) or auto_creation_requested:
		var save_error := ResourceSaver.save(new_resource, path)
		if save_error != OK:
			push_error("ROOMMATE: Can't save resource to %s. Error %s." % [path, save_error])
			return false
		new_resource.take_over_path(path)
		return true
	return false


func _process_space_block_part(slot_id: StringName, part: RoommatePart, block: RoommateBlock, 
		all_blocks: Dictionary) -> RoommatePart:
	if not part:
		return null
	var next_position := block.position + (part.flow as Vector3i)
	var next_block := all_blocks.get(next_position) as RoommateBlock
	return part if not next_block or part.flow == Vector3.ZERO else null


func _process_oblique_block_part(slot_id: StringName, part: RoommatePart, block: RoommateBlock, 
		all_blocks: Dictionary) -> RoommatePart:
	if not part:
		return null
	var next_position := block.position + (part.flow as Vector3i)
	var next_block := all_blocks.get(next_position) as RoommateBlock
	if slot_id == RoommateBlock.Slot.OBLIQUE:
		return part
	return part if not next_block or part.flow == Vector3.ZERO else null


func _process_nodraw_block_part(slot_id: StringName, part: RoommatePart, block: RoommateBlock, 
		all_blocks: Dictionary) -> RoommatePart:
	return null
