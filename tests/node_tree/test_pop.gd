@tool
extends "fixture.gd"

## pop_responder returns the last child, then null, and the walk is the root.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var order:Array = []
	var root:Responder = _unhandled( order )
	var child:Responder = _unhandled( order )
	_attach( _engine_root(), root )
	_attach( root, child )

	var popped:Responder = root.pop_responder()
	TEST_TRUE( popped == child, "pop returns last child" )
	TEST_TRUE( root.pop_responder() == null, "second pop" )
	_push()
	_expect_nodes( order, [root], "walk is the root" )
	await _end()
	return runcode
