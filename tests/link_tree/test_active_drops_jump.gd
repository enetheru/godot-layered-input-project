@tool
extends "fixture.gd"

## Silencing the front child settles the table on the root jump.

var _child:RefCounted


func _title() -> String:
	return "Active drops jump"


func _description() -> String:
	return "Silencing the front child settles the table on the root jump."


func _setup() -> int:
	var root_map:CustomInputMap = _action_map( &"li_jump", KEY_J )
	var child_map:CustomInputMap = _action_map( &"li_jump", KEY_K )
	_tree( root_map )
	_child = _record()
	_child.set( &"input_map", child_map )
	tree.add_responder( _child )
	await tree.until_rebuilt()
	return OK


func _run_test() -> int:
	_child.set( &"active", false )
	await tree.until_rebuilt()
	var table:CustomInputMap = tree.effective_map
	session.TEST_EQ( KEY_J, _keycode_of( table, &"li_jump" ), "root jump returns" )
	session.TEST_EQ( KEY_J, _engine_keycode( &"li_jump" ), "engine jump returns" )
	return session.runcode
