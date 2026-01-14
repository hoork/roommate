# Changing Appearance of Rooms

To change look of created rooms, we need to use RoommateStyle.

Steps to create new style:

1. Create new gd script

2. Make it tool script

3. Extend it from RoommateStyle

4. Override `_build_rulesets` function

5. Create new rulesets in this function

For example, code below adds sphere in the center of each block.

```gdscript
@tool
extends RoommateStyle


func _build_rulesets() -> void:
    var ruleset := create_ruleset()
    var block_selector := ruleset.select_all_blocks()
    var parts_setter := ruleset.select_all_walls()

    var new_mesh := CylinderMesh.new()
    new_mesh.top_radius = 0
    new_mesh.bottom_radius = 0.1
    new_mesh.height = 0.5
    parts_setter.mesh.override(new_mesh).
```

Now you can create new Resource file with this script and set it to Style property of RoommateStyler derived node.

For example, we can set style above to the RoommateSpace. After clicking **Generate** button, we can see the result. 

![](../assets/images/changing_appearance_of_rooms/creating_styles_example_result.webp)
