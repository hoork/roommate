![Roommate Plugin Logo](./images/roommate_logo_full.png)

# Roommate: Procedural 3D Level Builder

Roommate is hassle-free and easy to use 3D level builder plugin for Godot 4. Originally it's intended for creating an indoors environment, but can be repurposed for different use cases like creating cityscape background, adding objects in batch (props, lights, NPCs) and so on.

## Features

- Generate level's mesh, collision, scenes and navigation in one click.

- Simple layout edit, akin to putting CSGBox3D on scene and setting it's size.

- Automatically change properties of a level by user-created rules using the RoommateStyle derived resources. Styles are defined declaratively, like in CSS or SQL.

- Plugin doesn't affect your game's performance. Roommate doesn't run background tasks, periodic checks etc. After generating level it will idle until next generation is requested.

- Wide range of properties: from a PackedScene that will be instantiated to changing uv of a mesh surface.

- Made with customization in mind. You can define you own block types, block areas etc.

## Credits

- [Hoork](https://github.com/Hoork) - Original author of Roommate plugin
- [Kamenka](https://vk.com/club174676862) - Logo, icons
