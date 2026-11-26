@tool
extends "fixture.gd"

## The tree holds the root, and the root has no parent.

var _root:Object


func _title() -> String:
	return "Root stays"


func _description() -> String:
	return "The tree holds the root, and the root has no parent."


func _setup() -> int:
	_tree()
	_root = tree.get( &"root" )
	return OK


func _run_test() -> int:
	session.TEST_TRUE( tree.get( &"root" ) == _root, "root stays" )
	session.TEST_TRUE( _root.get( &"parent" ) == null, "root parent" )
	return session.runcode
