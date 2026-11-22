@tool
extends "fixture.gd"

## A map assigned before add appears in the table that follows the add.

func _title() -> String:
	return "Map before add"


func _description() -> String:
	return "A map assigned before add appears in the table that follows the add."


func _setup() -> int:
	_tree( _action_map( &"li_attack", KEY_A ) )
	await tree.until_rebuilt()
	return OK


func _run_test() -> int:
	var child:RefCounted = _record()
	child.set( &"input_map", _action_map( &"li_menu", KEY_M ) )
	session.TEST_FALSE( tree.effective_map.has_action( &"li_menu" ), "waits for add" )
	tree.add_responder( child )
	await tree.until_rebuilt()

	var table:CustomInputMap = tree.effective_map
	session.TEST_TRUE( table.has_action( &"li_menu" ), "menu arrives" )
	session.TEST_EQ( KEY_M, _keycode_of( table, &"li_menu" ), "menu key" )
	session.TEST_EQ( KEY_A, _keycode_of( table, &"li_attack" ), "attack stays" )
	return session.runcode
