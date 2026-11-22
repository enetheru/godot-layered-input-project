@tool
extends "fixture.gd"

## set_active(true) on an already active child leaves that child in front.

var _order:Array = []
var _root:Responder
var _child:Responder


func _title() -> String:
	return "Active unchanged"


func _description() -> String:
	return "set_active(true) on an already active child leaves that child in front."


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
	_child.active = true
	_push()
	_expect_nodes( _order, [_child, _root], "still child then root" )
	session.TEST_TRUE( _root.get_child( 0 ) == _child, "child stays" )
	return session.runcode
