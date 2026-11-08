@tool
extends "fixture.gd"

## active false drops the child from the visit, and active true brings it back.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var order:Array = []
	var root:Responder = _unhandled( order )
	var child:Responder = _unhandled( order )
	var map := CustomInputMap.new()
	child.input_map = map
	_attach( _engine_root(), root )
	_attach( root, child )

	child.active = false
	TEST_FALSE( child.contributes_map(), "inactive map" )
	TEST_TRUE( child.input_map == map, "map stays set" )
	_push()
	_expect_nodes( order, [root], "inactive visit" )

	order.clear()
	child.active = true
	TEST_TRUE( child.contributes_map(), "active map" )
	_push()
	_expect_nodes( order, [child, root], "active visit" )
	await _end()
	return runcode
