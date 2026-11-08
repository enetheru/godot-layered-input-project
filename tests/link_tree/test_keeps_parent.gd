@tool
extends "fixture.gd"

## Adding a record that already has a parent leaves it there.


func _run_test() -> int:
	var tree:Object = _tree()
	var kept:RefCounted = _record()
	var other:RefCounted = _record()
	tree.call( &"add_responder", kept )
	tree.call( &"add_responder", other )
	var child:RefCounted = _record()
	kept.call( &"add_responder", child )
	other.call( &"add_responder", child )

	TEST_TRUE( child.get( &"parent" ) == kept, "parent stays" )
	TEST_TRUE( _children( kept ).has( child ), "kept children" )
	TEST_FALSE( _children( other ).has( child ), "other children" )
	return runcode
