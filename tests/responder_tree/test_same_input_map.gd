@tool
extends "fixture.gd"

## Writing the current map back keeps the same table.

var _table:CustomInputMap


func _title() -> String:
	return "Same input map"


func _description() -> String:
	return "Writing the current map back keeps the same table."


func _setup() -> int:
	_tree( _action_map( &"li_attack", KEY_A ) )
	await tree.until_rebuilt()
	_table = tree.effective_map
	return OK


func _run_test() -> int:
	var current:CustomInputMap = tree.root.get( &"input_map" )
	tree.root.set( &"input_map", current )
	await tree.until_rebuilt()
	session.TEST_TRUE( is_same( tree.effective_map, _table ), "same table" )
	return session.runcode
