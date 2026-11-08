@tool
extends "fixture.gd"

## set_active(true) on an already active child leaves that child in front.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var order:Array = []
	var root:Responder = _unhandled( order )
	var child:Responder = _unhandled( order )
	_attach( _engine_root(), root )
	_attach( root, child )
	child.active = true
	_push()
	_expect_nodes( order, [child, root], "still child then root" )
	TEST_TRUE( root.get_child( 0 ) == child, "child stays" )
	await _end()
	return runcode
