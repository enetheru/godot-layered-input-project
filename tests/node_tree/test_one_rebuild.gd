@tool
extends "fixture.gd"

## An add and a map swap before idle settle in one rebuild.

func _title() -> String:
	return "One rebuild"


func _description() -> String:
	return "An add and a map swap before idle settle in one rebuild."


func _run_test() -> int:
	var hits:Array[int] = [0]
	var on_rebuilt := func() -> void:
		hits[0] += 1
	var _bound:Error = manager.rebuild_finished.connect( on_rebuilt ) as Error
	var child:Responder = _map_row()
	child.input_map = _action_map( &"li_menu", KEY_M )
	_attach( _engine_root(), child )
	_engine_root().input_map = _action_map( &"li_attack", KEY_B )
	await manager.until_rebuilt()

	var table:CustomInputMap = manager.effective_map
	session.TEST_EQ( 1, hits[0], "one rebuild" )
	session.TEST_EQ( KEY_B, _keycode_of( table, &"li_attack" ), "swapped attack" )
	session.TEST_EQ( KEY_M, _keycode_of( table, &"li_menu" ), "added menu" )
	return session.runcode
