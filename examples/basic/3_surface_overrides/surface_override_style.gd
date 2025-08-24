@tool
extends RoommateStyle


func _build_rulesets() -> void:
	var ruleset := create_ruleset()
	ruleset.select_all_blocks()
	
	# We have mesh with 2 surfaces.
	var walls_setter := ruleset.select_all_walls()
	var wall_mesh := preload("res://examples/common_assets/models/example_wall.tres")
	walls_setter.mesh.override(wall_mesh)
	
	# We can override certain surface by it's index.
	var right_surface_id := 1
	walls_setter.override_surface(right_surface_id).color.override(Color.BLUE)
	walls_setter.override_surface(right_surface_id).color_weight.override(1)
	# color_weight is a weight number of lerp function, which mix mesh's vertex color...
	# ...and part's color during room generation. For convenience you can use set_color...
	# ...to override color_weight with 1 automatically.
	var right_side_material := preload("res://examples/common_assets/materials/chains_material.tres")
	walls_setter.override_surface(right_surface_id).material.override(right_side_material)
	
	# If we want to affect all the surfaces, we can use fallback override.
	walls_setter.override_fallback_surface().set_color(Color.RED)
	walls_setter.override_fallback_surface().uv_transform.accumulate(Transform2D.IDENTITY.rotated(PI / 4))
	# Notice that right side is still blue (because explicit surface override have a priority...
	# ...over fallback override), but uv of left and right side are both rotated.
	# Also material on the left side is not changed.
	
	var floor_material := preload("res://examples/common_assets/materials/tile_material.tres")
	var floor_setter := ruleset.select_floor()
	var floor_surface := floor_setter.override_fallback_surface()
	floor_surface.material.override(floor_material)
	# Instead of AtlasTexture, you can use set_uv_tile. It overrides uv_transform...
	# ...in such a way that only desired tile would be shown.
	# Although, currently it's unpredictable and I recommend applying this transform to...
	# ...quad mesh without tile rotation.
	var target_tile_position := Vector2i(2, 1)
	var tileset_size := Vector2i(4, 3)
	var tile_rotation := PI
	floor_surface.set_uv_tile(target_tile_position, tileset_size, tile_rotation)
