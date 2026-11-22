@tool
extends "fixture.gd"

## pop_responder returns the last child, then null, and the walk is the root.

var _order:Array = []
var _root:Responder
var _child:Responder


func _title() -> String:
	return "Pop"


func _description() -> String:
	return "pop_responder returns the last child, then null, and the walk is the root."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_root = _unhandled( _order )
	_child = _unhandled( _order )
	_attach( _engine_root(), _root )
	_attach( _root, _child )
	return OK


func _run_test() -> int:
	var popped:Responder = _root.pop_responder()
	session.TEST_TRUE( popped == _child, "pop returns last child" )
	session.TEST_TRUE( _root.pop_responder() == null, "second pop" )
	_push()
	_expect_nodes( _order, [_root], "walk is the root" )
	return session.runcode
