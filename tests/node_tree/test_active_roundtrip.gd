@tool
extends "fixture.gd"

## active false drops the child from the visit, and active true brings it back.

var _order:Array = []
var _root:Responder
var _child:Responder
var _map:CustomInputMap


func _title() -> String:
	return "Active roundtrip"


func _description() -> String:
	return "active false drops the child from the visit, and active true brings it back."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_root = _unhandled( _order )
	_child = _unhandled( _order )
	_map = CustomInputMap.new()
	_child.input_map = _map
	_attach( _engine_root(), _root )
	_attach( _root, _child )
	return OK


func _run_test() -> int:
	_child.active = false
	session.TEST_FALSE( _child.contributes_map(), "inactive map" )
	session.TEST_TRUE( _child.input_map == _map, "map stays set" )
	_push()
	_expect_nodes( _order, [_root], "inactive visit" )

	_order.clear()
	_child.active = true
	session.TEST_TRUE( _child.contributes_map(), "active map" )
	_push()
	_expect_nodes( _order, [_child, _root], "active visit" )
	return session.runcode
