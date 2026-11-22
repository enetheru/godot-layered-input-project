@tool
extends "fixture.gd"

## The front responder marks the viewport handled, and the back one stays quiet.

var _front_hits:Array[int]
var _back_hits:Array[int]


func _title() -> String:
	return "Handled"


func _description() -> String:
	return "The front responder marks the viewport handled, and the back one stays quiet."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_front_hits = [0]
	_back_hits = [0]
	var back:Responder = _count_row( _back_hits )
	var front:Responder = _handle_row( _front_hits, host )
	_attach( _engine_root(), back )
	_attach( back, front )
	return OK


func _run_test() -> int:
	_push()
	session.TEST_EQ( 1, _front_hits[0], "handled front" )
	session.TEST_EQ( 0, _back_hits[0], "handled back" )
	return session.runcode
