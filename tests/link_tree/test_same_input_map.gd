@tool
extends "fixture.gd"

## Writing the current map back keeps the same table.


func _run_test() -> int:
	var tree:LinkTreeScript = _tree( _action_map( &"li_attack", KEY_A ) )
	await tree.until_rebuilt()

	var table:CustomInputMap = tree.effective_map
	var current:CustomInputMap = tree.root.get( &"input_map" )
	tree.root.set( &"input_map", current )
	await tree.until_rebuilt()
	TEST_TRUE( is_same( tree.effective_map, table ), "same table" )
	return runcode
