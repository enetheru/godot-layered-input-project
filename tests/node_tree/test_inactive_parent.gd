@tool
extends "fixture.gd"

## An inactive parent stays out, and its active child still contributes.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var root:Responder = _engine_root()
	root.input_map = _action_map( &"li_attack", KEY_A )
	var parent:Responder = _map_row()
	parent.input_map = _action_map( &"li_menu", KEY_M )
	parent.active = false
	var child:Responder = _map_row()
	child.input_map = _action_map( &"li_play", KEY_P )
	_attach( parent, child )
	_attach( root, parent )
	await manager.until_rebuilt()

	var table:CustomInputMap = manager.effective_map
	TEST_TRUE( table.has_action( &"li_play" ), "child play" )
	TEST_EQ( KEY_P, _keycode_of( table, &"li_play" ), "play key" )
	TEST_FALSE( table.has_action( &"li_menu" ), "parent menu stays out" )
	TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	await _end()
	return runcode
