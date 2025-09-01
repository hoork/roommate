# Creating Styles

Steps to create new style:

1. Create new gd script

2. Make it tool script

3. Extend it from RoommateStyleBlocks are selected only inside certain scope. Said scope is computed
    by RoommateStyler. RoommateBlocksArea's scope is limited by it's 
   bounding box. Scope of plain RoommateStyle affect all blocks in 
   RoommateRoot.

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

Now you can create new Resource file with this script and set it to Style property of RoommateStyler node.

For example, we can set style above to the RoommateSpace (it inherits from RoommateStyler). After clicking **Generate** button, we can see the result. 

![](../assets/images/creating_styles_example_result.png)
