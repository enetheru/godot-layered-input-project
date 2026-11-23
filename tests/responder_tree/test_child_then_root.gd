@tool
extends "fixture.gd"

## Unhandled walk for a root and one child.

var _root:Object
var _child:RefCounted


func _title() -> String:
	return "Child then root"


func _description() -> String:
	return "Unhandled walk for a root and one child."


func _setup() -> int:
	_tree()
	_root = tree.get( &"root" )
	_child = _record()
	_fill( _root, UNHANDLED_SLOT )
	_fill( _child, UNHANDLED_SLOT )
	tree.call( &"add_responder", _child )
	return OK


func _run_test() -> int:
	_expect( tree, UNHANDLED_WALK, [_child, _root], "child then root" )
	return session.runcode
