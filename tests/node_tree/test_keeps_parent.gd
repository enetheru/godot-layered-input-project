@tool
extends "fixture.gd"

## Adding a responder that already has a parent leaves it there.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var kept:Responder = _unhandled( [] )
	var other:Responder = _unhandled( [] )
	var child:Responder = _unhandled( [] )
	var root:Responder = _engine_root()
	_attach( root, kept )
	_attach( root, other )
	_attach( kept, child )
	other.add_responder( child )

	TEST_TRUE( child.get_parent() == kept, "parent stays" )
	TEST_TRUE( kept.get_children().has( child ), "kept children" )
	TEST_FALSE( other.get_children().has( child ), "other children" )
	await _end()
	return runcode
