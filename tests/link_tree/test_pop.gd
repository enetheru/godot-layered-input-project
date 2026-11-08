@tool
extends "fixture.gd"

## pop_responder returns the last child, then null.


func _run_test() -> int:
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
	var child:RefCounted = _record()
	_fill( root, UNHANDLED_SLOT )
	_fill( child, UNHANDLED_SLOT )
	tree.call( &"add_responder", child )

	var popped:Variant = root.call( &"pop_responder" )
	TEST_TRUE( popped == child, "pop returns last child" )
	_expect( tree, UNHANDLED_WALK, [root], "walk is the root" )
	TEST_TRUE( root.call( &"pop_responder" ) == null, "second pop" )
	return runcode
