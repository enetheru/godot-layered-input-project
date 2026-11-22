@tool
extends "fixture.gd"

## A null jump in front reserves the name and leaves the engine action with no events.

var _root_map:CustomInputMap


func _title() -> String:
	return "Null jump"


func _description() -> String:
	return "A null jump in front reserves the name and leaves the engine action with no events."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_root_map = _action_map( &"li_jump", KEY_J )
	var _attack:InputAction = _root_map.add_action( &"li_attack", 0.2, [_key( KEY_A )] )
	var child_map:CustomInputMap = _placeholder_map( &"li_jump" )
	var root:Responder = _engine_root()
	var child:Responder = _map_row()
	root.input_map = _root_map
	child.input_map = child_map
	_attach( root, child )
	await manager.until_rebuilt()
	return OK


func _run_test() -> int:
	var table:CustomInputMap = manager.effective_map
	session.TEST_TRUE( table.has_action( &"li_jump" ), "table reserves jump" )
	session.TEST_TRUE( table.get_action( &"li_jump" ) == null, "table jump placeholder" )
	session.TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	session.TEST_TRUE( InputMap.has_action( &"li_jump" ), "engine reserves jump" )
	session.TEST_EQ( 0, InputMap.action_get_events( &"li_jump" ).size(), "engine jump clear" )
	session.TEST_EQ( KEY_J, _keycode_of( _root_map, &"li_jump" ), "root map stays" )
	return session.runcode
