@tool
extends "fixture.gd"

## set_active(true) on an already active record keeps the same walk array.

var _child:RefCounted
var _walk:Array
var _before:Array


func _title() -> String:
	return "Active unchanged"


func _description() -> String:
	return "set_active(true) on an already active record keeps the same walk array."


func _setup() -> int:
	_tree()
	var root:Object = tree.get( &"root" )
	_child = _record()
	_fill( root, UNHANDLED_SLOT )
	_fill( _child, UNHANDLED_SLOT )
	tree.call( &"add_responder", _child )
	_walk = tree.get( UNHANDLED_WALK )
	_before = _walk.duplicate()
	return OK


func _run_test() -> int:
	_child.set( &"active", true )
	var got:Array = tree.get( UNHANDLED_WALK )
	session.TEST_TRUE( is_same( got, _walk ), "same walk array" )
	_expect_array( got, _before, "same walk records" )
	return session.runcode
