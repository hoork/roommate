# Selecting Blocks

There are several ways to do it.

We will be using style below to mark selected area by triangles.

```gdscript
@tool
class_name AllPrismStyle
extends RoommateStyle


func _build_rulesets() -> void:
    var ruleset := create_ruleset()

    ruleset.select_all_blocks()

    var all_parts := ruleset.select_center()
    all_parts.invert_selection()

    var prism := PrismMesh.new()
    prism.size = Vector3(1, 1, 0.05)
    all_parts.mesh.override(prism)
```

## Selecting All Blocks

If you want to change all the blocks in RoommateRoot, you can add RoommateStyler and set it's style.

![](../assets/images/placeholder.png)

## Selecting Blocks With Blocks Areas

You can use RoommateBlocksArea and set style and set it where you want. In this example, We changed quarter of the room to triangles. 

![](../assets/images/placeholder.png)

You can actually do the same with RoommateSpace, but RoommateBlocksArea doesn't create any blocks, so it's more convenient.

## Selecting Blocks Dynamically Using Style's Blocks Selectors

You can change block selection . For example, here we selecting farthest block along Z axis.

```gdscript
@tool
class_name AllPrismStyle
extends RoommateStyle


func _build_rulesets() -> void:
    var ruleset := create_ruleset()

    # NEW!!
    ruleset.select_blocks_by_extreme(Vector3.FORWARD)

    var all_parts := ruleset.select_center()
    all_parts.invert_selection()

    var prism := PrismMesh.new()
    prism.size = Vector3(1, 1, 0.05)
    all_parts.mesh.override(prism)
```

![](../assets/images/placeholder.png)

You can set this style to RoommateBlocksAreas. Selection will be limited to blocks that this area encompases.

![](../assets/images/placeholder.png)

You can also merge together multiple selectors with different modes

```gdscript
ruleset.select_blocks_by_extreme(Vector3.FORWARD).include()
ruleset.select_all_blocks().invert()
```

![](../assets/images/placeholder.png)

You can find more on the topic in [block selector reference page](../references/selecting_blocks.md)
