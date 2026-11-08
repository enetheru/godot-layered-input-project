@tool
extends "fixture.gd"

## Unhandled walk for a root and one child.


func _run_test() -> int:
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
	var child:RefCounted = _record()
	_fill( root, UNHANDLED_SLOT )
	_fill( child, UNHANDLED_SLOT )
	tree.call( &"add_responder", child )
	_expect( tree, UNHANDLED_WALK, [child, root], "child then root" )
	return runcode
