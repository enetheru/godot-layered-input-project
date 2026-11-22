@tool
extends "fixture.gd"

## A responder added during the visit waits for the next key.

var _added_hits:Array[int]
var _back_hits:Array[int]


func _title() -> String:
	return "Mid pass"


func _description() -> String:
	return "A responder added during the visit waits for the next key."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_added_hits = [0]
	_back_hits = [0]
	var back:Responder = _count_row( _back_hits )
	var front:Responder = _front_row( back, _added_hits )
	_attach( _engine_root(), back )
	_attach( back, front )
	return OK


func _run_test() -> int:
	_push()
	session.TEST_EQ( 0, _added_hits[0], "mid-pass added" )
	session.TEST_EQ( 1, _back_hits[0], "mid-pass back" )

	_push()
	session.TEST_EQ( 1, _added_hits[0], "second pass added" )
	session.TEST_EQ( 2, _back_hits[0], "second pass back" )
	return session.runcode
