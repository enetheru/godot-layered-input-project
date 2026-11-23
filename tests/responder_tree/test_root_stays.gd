@tool
extends "fixture.gd"

## Removing the root keeps the root.

var _root:Object


func _title() -> String:
	return "Root stays"


func _description() -> String:
	return "Removing the root keeps the root."


func _setup() -> int:
	_tree()
	_root = tree.get( &"root" )
	return OK


func _run_test() -> int:
	tree.call( &"remove_responder", _root )
	session.TEST_TRUE( tree.get( &"root" ) == _root, "root stays" )
	session.TEST_TRUE( _root.get( &"parent" ) == null, "root parent" )
	return session.runcode
