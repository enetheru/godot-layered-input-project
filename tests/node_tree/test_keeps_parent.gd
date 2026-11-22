@tool
extends "fixture.gd"

## Adding a responder that already has a parent leaves it there.

var _kept:Responder
var _other:Responder
var _child:Responder


func _title() -> String:
	return "Keeps parent"


func _description() -> String:
	return "Adding a responder that already has a parent leaves it there."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_kept = _unhandled( [] )
	_other = _unhandled( [] )
	_child = _unhandled( [] )
	var root:Responder = _engine_root()
	_attach( root, _kept )
	_attach( root, _other )
	_attach( _kept, _child )
	return OK


func _run_test() -> int:
	_other.add_responder( _child )
	session.TEST_TRUE( _child.get_parent() == _kept, "parent stays" )
	session.TEST_TRUE( _kept.get_children().has( _child ), "kept children" )
	session.TEST_FALSE( _other.get_children().has( _child ), "other children" )
	return session.runcode
