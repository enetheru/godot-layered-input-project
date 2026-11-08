@tool
extends "fixture.gd"

## Removing the root keeps the root.


func _run_test() -> int:
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
	tree.call( &"remove_responder", root )
	TEST_TRUE( tree.get( &"root" ) == root, "root stays" )
	TEST_TRUE( root.get( &"parent" ) == null, "root parent" )
	return runcode
