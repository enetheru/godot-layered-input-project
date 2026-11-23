@tool
extends "fixture.gd"

## An unchanged layer keeps its engine event. A replaced layer event is a new one.

var _map:CustomInputMap
var _first:InputEvent


func _title() -> String:
	return "Copy stays"


func _description() -> String:
	return "An unchanged layer keeps its engine event. A replaced layer event is a new one."


func _setup() -> int:
	_map = _action_map( &"li_jump", KEY_J )
	_tree( _map )
	await tree.until_rebuilt()
	var engine_events:Array[InputEvent] = []
	engine_events.assign( InputMap.action_get_events( &"li_jump" ) )
	_first = engine_events[0]
	return OK


func _run_test() -> int:
	var source:Array[InputEvent] = _map.get_action_events( &"li_jump" )
	session.TEST_TRUE( _first != source[0], "engine event is a copy" )
	session.TEST_EQ( KEY_J, _engine_keycode( &"li_jump" ), "first jump" )

	tree.request_rebuild()
	await tree.until_rebuilt()
	var second:Array[InputEvent] = []
	second.assign( InputMap.action_get_events( &"li_jump" ) )
	session.TEST_TRUE( second[0] == _first, "second rebuild keeps the copy" )

	var row:InputAction = _map.get_action( &"li_jump" )
	var next:Array[InputEvent] = [_key( KEY_K )]
	row.events = next
	tree.request_rebuild()
	await tree.until_rebuilt()
	var replaced:Array[InputEvent] = []
	replaced.assign( InputMap.action_get_events( &"li_jump" ) )
	session.TEST_EQ( KEY_K, _engine_keycode( &"li_jump" ), "replaced jump" )
	session.TEST_TRUE( replaced[0] != _first, "replaced event is new" )
	return session.runcode
