@tool
extends "fixture.gd"

## A record with only _input filled stays off the unhandled walk.

var _only:RefCounted


func _title() -> String:
	return "Input only"


func _description() -> String:
	return "A record with only _input filled stays off the unhandled walk."


func _setup() -> int:
	_tree()
	_only = _record()
	_fill( _only, INPUT_SLOT )
	tree.call( &"add_responder", _only )
	return OK


func _run_test() -> int:
	_expect( tree, INPUT_WALK, [_only], "input front" )
	_expect( tree, UNHANDLED_WALK, [], "unhandled skips input-only" )
	return session.runcode
