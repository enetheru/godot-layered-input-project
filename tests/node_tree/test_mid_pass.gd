@tool
extends "fixture.gd"

## A responder added during the visit waits for the next key.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var added_hits:Array[int] = [0]
	var back_hits:Array[int] = [0]
	var back:Responder = _count_row( back_hits )
	var front:Responder = _front_row( back, added_hits )
	_attach( _engine_root(), back )
	_attach( back, front )

	_push()
	TEST_EQ( 0, added_hits[0], "mid-pass added" )
	TEST_EQ( 1, back_hits[0], "mid-pass back" )

	_push()
	TEST_EQ( 1, added_hits[0], "second pass added" )
	TEST_EQ( 2, back_hits[0], "second pass back" )
	await _end()
	return runcode
