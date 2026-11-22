@tool
extends "fixture.gd"

## An inactive parent stays out, and its active child still contributes.

func _title() -> String:
	return "Inactive parent"


func _description() -> String:
	return "An inactive parent stays out, and its active child still contributes."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

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
	return OK


func _run_test() -> int:
	var table:CustomInputMap = manager.effective_map
	session.TEST_TRUE( table.has_action( &"li_play" ), "child play" )
	session.TEST_EQ( KEY_P, _keycode_of( table, &"li_play" ), "play key" )
	session.TEST_FALSE( table.has_action( &"li_menu" ), "parent menu stays out" )
	session.TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	return session.runcode
