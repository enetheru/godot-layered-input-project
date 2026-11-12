@tool
extends "fixture.gd"

## Setting an already active child active again keeps the same table.


func _run_test() -> int:
	var tree:LinkTreeScript = _tree( _action_map( &"li_attack", KEY_A ) )
	var child:RefCounted = _record()
	child.set( &"input_map", _action_map( &"li_menu", KEY_M ) )
	tree.add_responder( child )
	await tree.until_rebuilt()

	var table:CustomInputMap = tree.effective_map
	child.set( &"active", true )
	await tree.until_rebuilt()
	TEST_TRUE( is_same( tree.effective_map, table ), "same table" )
	return runcode
