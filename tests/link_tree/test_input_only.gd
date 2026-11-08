@tool
extends "fixture.gd"

## A record with only _input filled stays off the unhandled walk.


func _run_test() -> int:
	var tree:Object = _tree()
	var only:RefCounted = _record()
	_fill( only, INPUT_SLOT )
	tree.call( &"add_responder", only )
	_expect( tree, INPUT_WALK, [only], "input front" )
	_expect( tree, UNHANDLED_WALK, [], "unhandled skips input-only" )
	return runcode
