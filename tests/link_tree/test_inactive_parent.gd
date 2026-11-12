@tool
extends "fixture.gd"

## An inactive parent stays out, and its active child still contributes.


func _run_test() -> int:
	var tree:LinkTreeScript = _tree( _action_map( &"li_attack", KEY_A ) )
	var parent:RefCounted = _record()
	parent.set( &"input_map", _action_map( &"li_menu", KEY_M ) )
	parent.set( &"active", false )
	var child:RefCounted = _record()
	child.set( &"input_map", _action_map( &"li_play", KEY_P ) )
	parent.call( &"add_responder", child )
	tree.add_responder( parent )
	await tree.until_rebuilt()

	var table:CustomInputMap = tree.effective_map
	TEST_TRUE( table.has_action( &"li_play" ), "child play" )
	TEST_EQ( KEY_P, _keycode_of( table, &"li_play" ), "play key" )
	TEST_FALSE( table.has_action( &"li_menu" ), "parent menu stays out" )
	TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	return runcode
