@tool
extends "fixture.gd"

## A responder with only _input still keeps the other process flags on.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var hits:Array[int] = [0]
	var only:Responder = _input_only( hits )
	_attach( _engine_root(), only )
	_push()
	TEST_EQ( 1, hits[0], "input hit" )
	TEST_TRUE( only.is_processing_input(), "input flag" )
	TEST_TRUE( only.is_processing_unhandled_input(), "unhandled flag" )
	TEST_TRUE( only.is_processing_unhandled_key_input(), "key flag" )
	TEST_FALSE( only.is_processing_shortcut_input(), "shortcut flag" )
	await _end()
	return runcode
