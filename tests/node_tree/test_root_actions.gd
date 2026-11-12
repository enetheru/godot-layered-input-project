@tool
extends "fixture.gd"

## The root map's jump and attack are the table and the engine actions.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var root_map:CustomInputMap = _action_map( &"li_jump", KEY_J )
	var _attack:InputAction = root_map.add_action( &"li_attack", 0.2, [_key( KEY_A )] )
	_engine_root().input_map = root_map
	await manager.until_rebuilt()

	var table:CustomInputMap = manager.effective_map
	TEST_EQ( KEY_J, _keycode_of( table, &"li_jump" ), "table jump" )
	TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "table attack" )
	TEST_EQ( KEY_J, _engine_keycode( &"li_jump" ), "engine jump" )
	TEST_EQ( KEY_A, _engine_keycode( &"li_attack" ), "engine attack" )
	await _end()
	return runcode
