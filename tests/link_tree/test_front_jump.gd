@tool
extends "fixture.gd"

## The child in front keeps jump, and the root keeps attack.


func _run_test() -> int:
	var root_map:CustomInputMap = _action_map( &"li_jump", KEY_J )
	var _attack:InputAction = root_map.add_action( &"li_attack", 0.2, [_key( KEY_A )] )
	var child_map:CustomInputMap = _action_map( &"li_jump", KEY_K )
	var tree:LinkTreeScript = _tree( root_map )
	var child:RefCounted = _record()
	child.set( &"input_map", child_map )
	tree.add_responder( child )
	await tree.until_rebuilt()

	var table:CustomInputMap = tree.effective_map
	TEST_EQ( KEY_K, _keycode_of( table, &"li_jump" ), "front jump" )
	TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	TEST_EQ( KEY_J, _keycode_of( root_map, &"li_jump" ), "root map stays" )
	TEST_EQ( KEY_K, _keycode_of( child_map, &"li_jump" ), "child map stays" )
	return runcode
