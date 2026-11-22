@tool
extends "fixture.gd"

## Adding a record that already has a parent leaves it there.

var _kept:RefCounted
var _other:RefCounted
var _child:RefCounted


func _title() -> String:
	return "Keeps parent"


func _description() -> String:
	return "Adding a record that already has a parent leaves it there."


func _setup() -> int:
	_tree()
	_kept = _record()
	_other = _record()
	tree.call( &"add_responder", _kept )
	tree.call( &"add_responder", _other )
	_child = _record()
	_kept.call( &"add_responder", _child )
	return OK


func _run_test() -> int:
	_other.call( &"add_responder", _child )
	session.TEST_TRUE( _child.get( &"parent" ) == _kept, "parent stays" )
	session.TEST_TRUE( _children( _kept ).has( _child ), "kept children" )
	session.TEST_FALSE( _children( _other ).has( _child ), "other children" )
	return session.runcode
