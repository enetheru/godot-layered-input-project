@tool
extends "fixture.gd"

## One key visits the child, then the root, through _unhandled_input.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var order:Array = []
	var root:Responder = _unhandled( order )
	var child:Responder = _unhandled( order )
	_attach( _engine_root(), root )
	_attach( root, child )
	_push()
	_expect_nodes( order, [child, root], "child then root" )
	await _end()
	return runcode
