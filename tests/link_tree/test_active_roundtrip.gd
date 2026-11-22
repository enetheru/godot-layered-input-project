@tool
extends "fixture.gd"

## active false drops a filled record, and active true brings it back.

var _root:Object
var _child:RefCounted
var _map:CustomInputMap


func _title() -> String:
	return "Active roundtrip"


func _description() -> String:
	return "active false drops a filled record, and active true brings it back."


func _setup() -> int:
	_tree()
	_root = tree.get( &"root" )
	_child = _record()
	_map = CustomInputMap.new()
	_child.set( &"input_map", _map )
	_fill_all( _root )
	_fill_all( _child )
	tree.call( &"add_responder", _child )
	return OK


func _run_test() -> int:
	_child.set( &"active", false )
	session.TEST_FALSE( _child.call( &"contributes_map" ), "inactive map" )
	session.TEST_TRUE( _child.get( &"input_map" ) == _map, "map stays set" )
	for prop:StringName in [INPUT_WALK, SHORTCUT_WALK, KEY_WALK, UNHANDLED_WALK]:
		_expect( tree, prop, [_root], "inactive " + String( prop ) )

	_child.set( &"active", true )
	session.TEST_TRUE( _child.call( &"contributes_map" ), "active map" )
	for prop:StringName in [INPUT_WALK, SHORTCUT_WALK, KEY_WALK, UNHANDLED_WALK]:
		_expect( tree, prop, [_child, _root], "active again " + String( prop ) )
	return session.runcode
