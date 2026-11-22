@tool
extends "fixture.gd"

## The child in front keeps jump, and the root keeps attack.

var _root_map:CustomInputMap
var _child_map:CustomInputMap


func _title() -> String:
	return "Front jump"


func _description() -> String:
	return "The child in front keeps jump, and the root keeps attack."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_root_map = _action_map( &"li_jump", KEY_J )
	var _attack:InputAction = _root_map.add_action( &"li_attack", 0.2, [_key( KEY_A )] )
	_child_map = _action_map( &"li_jump", KEY_K )
	var root:Responder = _engine_root()
	var child:Responder = _map_row()
	root.input_map = _root_map
	child.input_map = _child_map
	_attach( root, child )
	await manager.until_rebuilt()
	return OK


func _run_test() -> int:
	var table:CustomInputMap = manager.effective_map
	session.TEST_EQ( KEY_K, _keycode_of( table, &"li_jump" ), "front jump" )
	session.TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	session.TEST_EQ( KEY_J, _keycode_of( _root_map, &"li_jump" ), "root map stays" )
	session.TEST_EQ( KEY_K, _keycode_of( _child_map, &"li_jump" ), "child map stays" )
	return session.runcode
