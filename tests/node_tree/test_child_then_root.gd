@tool
extends "fixture.gd"

## One key visits the child, then the root, through _unhandled_input.

var _order:Array = []
var _root:Responder
var _child:Responder


func _title() -> String:
	return "Child then root"


func _description() -> String:
	return "One key visits the child, then the root, through _unhandled_input."


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
	_push()
	_expect_nodes( _order, [_child, _root], "child then root" )
	return session.runcode
