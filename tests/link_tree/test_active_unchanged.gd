@tool
extends "fixture.gd"

## set_active(true) on an already active record keeps the same walk array.


func _run_test() -> int:
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
	var child:RefCounted = _record()
	_fill( root, UNHANDLED_SLOT )
	_fill( child, UNHANDLED_SLOT )
	tree.call( &"add_responder", child )

	var walk:Array = tree.get( UNHANDLED_WALK )
	var before:Array = walk.duplicate()
	child.set( &"active", true )
	var got:Array = tree.get( UNHANDLED_WALK )
	TEST_TRUE( is_same( got, walk ), "same walk array" )
	_expect_array( got, before, "same walk records" )
	return runcode
