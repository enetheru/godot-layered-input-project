@tool
extends "fixture.gd"

## The front responder marks the viewport handled, and the back one stays quiet.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var front_hits:Array[int] = [0]
	var back_hits:Array[int] = [0]
	var back:Responder = _count_row( back_hits )
	var front:Responder = _handle_row( front_hits, vp )
	_attach( _engine_root(), back )
	_attach( back, front )
	_push()
	TEST_EQ( 1, front_hits[0], "handled front" )
	TEST_EQ( 0, back_hits[0], "handled back" )
	await _end()
	return runcode
