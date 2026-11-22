@tool
extends "fixture.gd"

## pop_responder returns the last child, then null.

var _root:Object
var _child:RefCounted


func _title() -> String:
	return "Pop"


func _description() -> String:
	return "pop_responder returns the last child, then null."


func _setup() -> int:
	_tree()
	_root = tree.get( &"root" )
	_child = _record()
	_fill( _root, UNHANDLED_SLOT )
	_fill( _child, UNHANDLED_SLOT )
	tree.call( &"add_responder", _child )
	return OK


func _run_test() -> int:
	var popped:Variant = _root.call( &"pop_responder" )
	session.TEST_TRUE( popped == _child, "pop returns last child" )
	_expect( tree, UNHANDLED_WALK, [_root], "walk is the root" )
	session.TEST_TRUE( _root.call( &"pop_responder" ) == null, "second pop" )
	return session.runcode
