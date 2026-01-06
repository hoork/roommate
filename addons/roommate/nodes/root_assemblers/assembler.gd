# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
extends RefCounted

const _SETTINGS := preload("../../plugin_settings.gd")

var block_size := 0.0
var root_node_path := NodePath()


func add_part(part: RoommatePart, block: RoommateBlock) -> void:
	pass


func assemble_and_attach(root: RoommateRoot) -> void:
	pass
