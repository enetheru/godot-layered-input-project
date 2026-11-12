@tool
extends "fixture.gd"

## An add and a map swap before idle settle in one rebuild.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var hits:Array[int] = [0]
	var on_rebuilt := func() -> void:
		hits[0] += 1
	var _bound:Error = manager.rebuild_finished.connect( on_rebuilt )
	var child:Responder = _map_row()
	child.input_map = _action_map( &"li_menu", KEY_M )
	_attach( _engine_root(), child )
	_engine_root().input_map = _action_map( &"li_attack", KEY_B )
	await manager.until_rebuilt()

	var table:CustomInputMap = manager.effective_map
	TEST_EQ( 1, hits[0], "one rebuild" )
	TEST_EQ( KEY_B, _keycode_of( table, &"li_attack" ), "swapped attack" )
	TEST_EQ( KEY_M, _keycode_of( table, &"li_menu" ), "added menu" )
	await _end()
	return runcode
