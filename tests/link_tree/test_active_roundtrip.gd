@tool
extends "fixture.gd"

## active false drops a filled record, and active true brings it back.


func _run_test() -> int:
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
	var child:RefCounted = _record()
	var map := CustomInputMap.new()
	child.set( &"input_map", map )
	_fill_all( root )
	_fill_all( child )
	tree.call( &"add_responder", child )

	child.set( &"active", false )
	TEST_FALSE( child.call( &"contributes_map" ), "inactive map" )
	TEST_TRUE( child.get( &"input_map" ) == map, "map stays set" )
	for prop:StringName in [INPUT_WALK, SHORTCUT_WALK, KEY_WALK, UNHANDLED_WALK]:
		_expect( tree, prop, [root], "inactive " + String( prop ) )

	child.set( &"active", true )
	TEST_TRUE( child.call( &"contributes_map" ), "active map" )
	for prop:StringName in [INPUT_WALK, SHORTCUT_WALK, KEY_WALK, UNHANDLED_WALK]:
		_expect( tree, prop, [child, root], "active again " + String( prop ) )
	return runcode
