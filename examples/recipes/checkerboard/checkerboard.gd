@tool
extends RoommateStyle


func _build_rulesets():
	var all_ruleset := create_ruleset()
	all_ruleset.select_all_blocks()
	var white_material := preload("res://examples/common_assets/materials/plain_white.tres")
	all_ruleset.select_all_parts().surfaces.material.override(white_material)
	
	var checker_ruleset := create_ruleset()
	const INTERVAL := Vector3i.ONE * 2
	checker_ruleset.select_interval_blocks(INTERVAL)
	checker_ruleset.select_interval_blocks(INTERVAL).set_offset(Vector3i(0, 1, 1))
	checker_ruleset.select_interval_blocks(INTERVAL).set_offset(Vector3i(1, 0, 1))
	checker_ruleset.select_interval_blocks(INTERVAL).set_offset(Vector3i(1, 1, 0))
	checker_ruleset.select_all_parts().surfaces.set_color(Color.GRAY)

