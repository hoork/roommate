@tool
extends RoommateStyle


func _build_rulesets() -> void:
	var material := preload("res://examples/common_assets/materials/tile_material.tres")
	
	var ruleset := create_ruleset()
	ruleset.select_blocks_by_extreme(Vector3.DOWN)
	var floor_setter := ruleset.select_floor()
	floor_setter.override_fallback_surface().material.override(material)
	
	# In some cases we need to change property of each part to unique value. 
	# Instead of creating dozens of rulesets, we can use handle_part callback of part setter...
	# ...and set values directly to part.
	# handle_part called for each selected part.
	
	# Let's set each floor part to it's random tile.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("Roommate is cool!")
	floor_setter.handle_part = func (_slot_id: StringName, part: RoommatePart, 
			_block: RoommateBlock) -> void:
		var tileset_size := Vector2i(4, 3)
		var tile_position := Vector2i.ZERO
		tile_position.x = rng.randi_range(0, 3)
		tile_position.y = rng.randi_range(0, 2)
		part.fallback_surface_override.set_uv_tile(tile_position, tileset_size)

