@tool
extends "fixture.gd"

## An inactive parent stays out, and its active child still contributes.

func _title() -> String:
	return "Inactive parent"


func _description() -> String:
	return "An inactive parent stays out, and its active child still contributes."


func _setup() -> int:
	_tree( _action_map( &"li_attack", KEY_A ) )
	var parent:RefCounted = _record()
	parent.set( &"input_map", _action_map( &"li_menu", KEY_M ) )
	parent.set( &"active", false )
	var child:RefCounted = _record()
	child.set( &"input_map", _action_map( &"li_play", KEY_P ) )
	parent.call( &"add_responder", child )
	tree.add_responder( parent )
	await tree.until_rebuilt()
	return OK


func _run_test() -> int:
	var table:CustomInputMap = tree.effective_map
	session.TEST_TRUE( table.has_action( &"li_play" ), "child play" )
	session.TEST_EQ( KEY_P, _keycode_of( table, &"li_play" ), "play key" )
	session.TEST_FALSE( table.has_action( &"li_menu" ), "parent menu stays out" )
	session.TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "root attack" )
	return session.runcode
