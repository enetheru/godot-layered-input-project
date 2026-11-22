@tool
extends "fixture.gd"

## Setting an already active child active again keeps the same table.

var _child:Responder
var _table:CustomInputMap


func _title() -> String:
	return "Active same map"


func _description() -> String:
	return "Setting an already active child active again keeps the same table."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_child = _map_row()
	_child.input_map = _action_map( &"li_menu", KEY_M )
	_attach( _engine_root(), _child )
	await manager.until_rebuilt()
	_table = manager.effective_map
	return OK


func _run_test() -> int:
	_child.active = true
	await manager.until_rebuilt()
	session.TEST_TRUE( is_same( manager.effective_map, _table ), "same table" )
	return session.runcode
