@tool
extends "fixture.gd"

## Silencing the front child settles the table on the root jump.


func _run_test() -> int:
	var root_map:CustomInputMap = _action_map( &"li_jump", KEY_J )
	var child_map:CustomInputMap = _action_map( &"li_jump", KEY_K )
	var tree:LinkTreeScript = _tree( root_map )
	var child:RefCounted = _record()
	child.set( &"input_map", child_map )
	tree.add_responder( child )
	await tree.until_rebuilt()

	child.set( &"active", false )
	await tree.until_rebuilt()
	var table:CustomInputMap = tree.effective_map
	TEST_EQ( KEY_J, _keycode_of( table, &"li_jump" ), "root jump returns" )
	TEST_EQ( KEY_J, _engine_keycode( &"li_jump" ), "engine jump returns" )
	return runcode
