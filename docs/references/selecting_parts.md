# Selecting Parts

You can select parts with the `select_parts` function and passing array of slot ids. For convinience there is `select_part` which can select single part of a RoommateBlock. You can also use select function for certain default parts, like `select_floor`, `select_wall_forward` and etc.

All these part selection functions returns parts setter object. You can change it's property `inverse_selection` to `true`, so every part will be selected, except provided.

## Default Parts Reference

| Slot Id             | Select Function       | Const                             |
| ------------------- | --------------------- | --------------------------------- |
| *slid_ceil*         | `select_ceil`         | `RoommateBlock.Slot.CEIL`         |
| *slid_floor*        | `select_floor`        | `RoommateBlock.Slot.FLOOR`        |
| *slid_wall_left*    | `select_wall_left`    | `RoommateBlock.Slot.WALL_LEFT`    |
| *slid_wall_right*   | `select_wall_right`   | `RoommateBlock.Slot.WALL_RIGHT`   |
| *slid_wall_forward* | `select_wall_forward` | `RoommateBlock.Slot.WALL_FORWARD` |
| *slid_wall_back*    | `select_wall_back`    | `RoommateBlock.Slot.WALL_BACK`    |
| *slid_center*       | `select_center`       | `RoommateBlock.Slot.CENTER`       |
| *slid_oblique*      | `select_oblique`      | `RoommateBlock.Slot.OBLIQUE`      |
