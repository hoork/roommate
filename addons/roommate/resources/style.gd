# Copyright (c) 2025 Kirill Rozhkov.
#
# This file is part of Roommate plugin: https://github.com/hoork/roommate
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

@tool
@icon("../icons/style.svg")
class_name RoommateStyle
extends Resource
## Base class for generating rulesets and changing [RoommatePart]
## 
## On it's own it doesn't do anything. Extend this class, override 
## [method RoommateStyle._build_rulesets] and create rulesets to change 
## [RoommatePart] properties.
## [br][br]
## It can be used in [RoommateRoot], [RoommateBlocksArea] and it's derived classes.

const _RULESET := preload("../data/style/ruleset.gd")

var _current_rulesets: Array[_RULESET] = []


func apply(blocks_scope: Dictionary) -> void:
	_current_rulesets.clear()
	_build_rulesets()
	for ruleset in _current_rulesets:
		ruleset.apply(blocks_scope)
	_current_rulesets.clear()


func create_ruleset() -> _RULESET:
	var new_ruleset = _RULESET.new()
	_current_rulesets.append(new_ruleset)
	return new_ruleset


func _build_rulesets() -> void: # virtual function
	pass
