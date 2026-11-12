@tool
extends "fixture.gd"

## An add and a map swap before idle settle in one rebuild.


func _run_test() -> int:
	var hits:Array[int] = [0]
	var tree:LinkTreeScript = _tree( _action_map( &"li_attack", KEY_A ) )
	var on_rebuilt := func() -> void:
		hits[0] += 1
	var _bound:Error = tree.rebuild_finished.connect( on_rebuilt )
	var child:RefCounted = _record()
	child.set( &"input_map", _action_map( &"li_menu", KEY_M ) )
	tree.add_responder( child )
	tree.root.set( &"input_map", _action_map( &"li_attack", KEY_B ) )
	await tree.until_rebuilt()

	var table:CustomInputMap = tree.effective_map
	TEST_EQ( 1, hits[0], "one rebuild" )
	TEST_EQ( KEY_B, _keycode_of( table, &"li_attack" ), "swapped attack" )
	TEST_EQ( KEY_M, _keycode_of( table, &"li_menu" ), "added menu" )
	return runcode
