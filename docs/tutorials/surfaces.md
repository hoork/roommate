# How to Set And Change Textures

To change material of a wall, you need to get surface override and when override it's properties.

```gdscript
@tool
class_name SurfacesStyle
extends RoommateStyle


func _build_rulesets() -> void:
    var ruleset := create_ruleset()
    ruleset.select_all_blocks()
    var parts := ruleset.select_all_parts()

    # getting surface overrides by surface id
    var override_surface := parts.override_surface(0)

    # overriding material of surface
    var material := StandardMaterial3D.new()
    material.albedo_color = Color.BLUE
    override_surface.material.override(material)
```

![](../assets/images/placeholder.png)

If you want change all surfaces all at once, you can use next method.

```gdscript
var override_surface := parts.override_fallback_surface()
```

or, more consise

```gdscript
var override_surface := parts.surfaces
```

Note, that changes made with explicitly called part surface has priority.
