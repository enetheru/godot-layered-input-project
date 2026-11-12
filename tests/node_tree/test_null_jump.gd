@tool
extends "fixture.gd"

## A null jump in front reserves the name and leaves the engine action with no events.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var root_map:CustomInputMap = _action_map( &"li_jump", KEY_J )
	var _attack:InputAction = root_map.add_action( &"li_attack", 0.2, [_key( KEY_A )] )
	var child_map:CustomInputMap = _placeholder_map( &"li_jump" )
	var root:Responder = _engine_root()
	var child:Responder = _map_row()
	root.input_map = root_map
	child.input_map = child_map
	_attach( root, child )
	await manager.until_rebuilt()

	var table:CustomInputMap = manager.effective_map
	TEST_TRUE( table.has_action( &"li_jump" ), "table reserves jump" )
	TEST_TRUE( table.get_action( &"li_jump" ) == null, "table jump placeholder" )
	TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	TEST_TRUE( InputMap.has_action( &"li_jump" ), "engine reserves jump" )
	TEST_EQ( 0, InputMap.action_get_events( &"li_jump" ).size(), "engine jump clear" )
	TEST_EQ( KEY_J, _keycode_of( root_map, &"li_jump" ), "root map stays" )
	await _end()
	return runcode
