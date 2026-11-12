@tool
extends "fixture.gd"

## Setting an already active child active again keeps the same table.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var child:Responder = _map_row()
	child.input_map = _action_map( &"li_menu", KEY_M )
	_attach( _engine_root(), child )
	await manager.until_rebuilt()

	var table:CustomInputMap = manager.effective_map
	child.active = true
	await manager.until_rebuilt()
	TEST_TRUE( is_same( manager.effective_map, table ), "same table" )
	await _end()
	return runcode
