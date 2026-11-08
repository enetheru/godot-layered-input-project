@tool
extends "fixture.gd"

## Removing the responder root keeps that root.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var root:Responder = _engine_root()
	manager.remove_responder( root )
	TEST_TRUE( manager.get( &"responder_root" ) == root, "root stays" )
	TEST_TRUE( root.get_parent() == manager, "root parent" )
	await _end()
	return runcode
