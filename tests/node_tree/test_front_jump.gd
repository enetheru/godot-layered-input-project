@tool
extends "fixture.gd"

## The child in front keeps jump, and the root keeps attack.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var root_map:CustomInputMap = _action_map( &"li_jump", KEY_J )
	var _attack:InputAction = root_map.add_action( &"li_attack", 0.2, [_key( KEY_A )] )
	var child_map:CustomInputMap = _action_map( &"li_jump", KEY_K )
	var root:Responder = _engine_root()
	var child:Responder = _map_row()
	root.input_map = root_map
	child.input_map = child_map
	_attach( root, child )
	await manager.until_rebuilt()

	var table:CustomInputMap = manager.effective_map
	TEST_EQ( KEY_K, _keycode_of( table, &"li_jump" ), "front jump" )
	TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	TEST_EQ( KEY_J, _keycode_of( root_map, &"li_jump" ), "root map stays" )
	TEST_EQ( KEY_K, _keycode_of( child_map, &"li_jump" ), "child map stays" )
	await _end()
	return runcode
