@tool
extends "fixture.gd"

## A name the layer leaves empty keeps the engine's event object.

var _name:StringName
var _live:InputEvent


func _title() -> String:
	return "Baseline event"


func _description() -> String:
	return "A name the layer leaves empty keeps the engine's event object."


func _setup() -> int:
	_name = _baseline_name()
	if _name.is_empty():
		return OK
	var live:Array[InputEvent] = []
	live.assign( InputMap.action_get_events( _name ) )
	_live = live[0]
	_tree( _action_map( &"li_jump", KEY_J ) )
	await tree.until_rebuilt()
	return OK


func _run_test() -> int:
	session.TEST_TRUE( not _name.is_empty(), "baseline has an event" )
	if _name.is_empty():
		return session.runcode
	var engine_events:Array[InputEvent] = []
	engine_events.assign( InputMap.action_get_events( _name ) )
	var table_events:Array[InputEvent] = tree.effective_map.get_action_events( _name )
	session.TEST_EQ( KEY_J, _engine_keycode( &"li_jump" ), "layer jump" )
	session.TEST_TRUE( not engine_events.is_empty(), "engine still has the baseline name" )
	session.TEST_TRUE( engine_events[0] == _live, "engine keeps the baseline event" )
	session.TEST_TRUE( not table_events.is_empty(), "table has the baseline name" )
	session.TEST_TRUE( table_events[0] == _live, "table shares the baseline event" )
	return session.runcode


func _baseline_name() -> StringName:
	for action_name:StringName in CustomInputMap.engine_baseline().get_action_names():
		if action_name == &"li_jump":
			continue
		var events:Array[InputEvent] = []
		events.assign( InputMap.action_get_events( action_name ) )
		if not events.is_empty():
			return action_name
	return &""
