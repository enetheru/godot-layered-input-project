@tool
extends "fixture.gd"

## A responder with only _input still keeps the other process flags on.

var _hits:Array[int]
var _only:Responder


func _title() -> String:
	return "Input only"


func _description() -> String:
	return "A responder with only _input still keeps the other process flags on."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_hits = [0]
	_only = _input_only( _hits )
	_attach( _engine_root(), _only )
	return OK


func _run_test() -> int:
	_push()
	session.TEST_EQ( 1, _hits[0], "input hit" )
	session.TEST_TRUE( _only.is_processing_input(), "input flag" )
	session.TEST_TRUE( _only.is_processing_unhandled_input(), "unhandled flag" )
	session.TEST_TRUE( _only.is_processing_unhandled_key_input(), "key flag" )
	session.TEST_FALSE( _only.is_processing_shortcut_input(), "shortcut flag" )
	return session.runcode
