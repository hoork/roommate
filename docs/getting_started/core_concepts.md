# Core Concepts

The core idea of this plugin to make a level design tool that more sophisticalted than GridMap node and less compled than making levels in quake map editor or making 3d models of levels. Portal 2's level editor is the direct inspiration.

## How it works

Space is logically divided by blocks (like in minecraft). These blocks are consist of various number of parts (floor, walls and etc) and these parts are responsible to hold information that later will be used to generate mesh, collision shapes etc.. Initially these blocks doesn't hold any information, but you can add BlocksArea derived nodes to set information. After that, Style derived resources are called. They are changing part information based on the rulesets created by these resources. And After that the plugin will create mesh, collision and etc, based on generated info.






