@tool
extends RoommateStyle


func _build_rulesets() -> void:
	# every style should have at least one ruleset
	# create_ruleset() creates ruleset and adds it to internal array 
	var ruleset := create_ruleset()
	# ruleset consist of block selectors and part setters.
	
	# with select_all_blocks() we can create block selector which selects...
	# ...all the blocks. Created selector is added in internal array
	var block_selector := ruleset.select_all_blocks()
	# there are a lot different select blocks function like select_blocks_by_type, ...
	# ...select_blocks_by_extreme etc.
	
	# you can change the operation mode of a selector.
	block_selector.exclude() # Excluding all selected blocks. All blocks are excluded...
	# ...and therefore nothing will be changed by this style.
	block_selector.include() # Reverting back to default behaviour.
	# there are many more modes.
	
	# We can also set offset selected blocks. But when everything is selected, offset will do nothing
	block_selector.set_offset(Vector3i.RIGHT)
	
	# With select_all_walls we are creating parts setter which will set values...
	# ...of all wall parts of all included blocks. 
	# This function add setter to internal array
	var parts_setter := ruleset.select_all_walls()
	# There are different functions that can create setters like select_floor and select_all_parts
	
	# by using value setters accessed via properties we can override current part values.
	var new_mesh := CylinderMesh.new()
	new_mesh.top_radius = 0
	new_mesh.bottom_radius = 0.1
	new_mesh.height = 0.5
	parts_setter.mesh.override(new_mesh) # in this instance we replacing default quad wall with cone mesh.
	
	# Some properties can be accumulated, i.e. we can add something to existing value.
	# In this case we locally rotating mesh by 45 degrees.
	var rotation := Transform3D.IDENTITY.rotated(Vector3.FORWARD, PI / 4)
	parts_setter.mesh_transform.accumulate(rotation)
	# you can try replacing accumulate with override to see how they affect mesh's transform
	
	# order in which you create rulesets, block selectors and parts setters does matter.
	# you can specify apply order of blocks areas and styles in the inspector.
