@tool
extends "fixture.gd"

## The root map's jump and attack are the table and the engine actions.

func _title() -> String:
	return "Root actions"


func _description() -> String:
	return "The root map's jump and attack are the table and the engine actions."


func _setup() -> int:
	var root_map:CustomInputMap = _action_map( &"li_jump", KEY_J )
	var _attack:InputAction = root_map.add_action( &"li_attack", 0.2, [_key( KEY_A )] )
	_tree( root_map )
	await tree.until_rebuilt()
	return OK


func _run_test() -> int:
	var table:CustomInputMap = tree.effective_map
	session.TEST_EQ( KEY_J, _keycode_of( table, &"li_jump" ), "table jump" )
	session.TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "table attack" )
	session.TEST_EQ( KEY_J, _engine_keycode( &"li_jump" ), "engine jump" )
	session.TEST_EQ( KEY_A, _engine_keycode( &"li_attack" ), "engine attack" )
	return session.runcode
