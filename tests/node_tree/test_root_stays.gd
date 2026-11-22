@tool
extends "fixture.gd"

## Removing the responder root keeps that root.

func _title() -> String:
	return "Root stays"


func _description() -> String:
	return "Removing the responder root keeps that root."


func _run_test() -> int:
	var root:Responder = _engine_root()
	manager.remove_responder( root )
	session.TEST_TRUE( manager.get( &"responder_root" ) == root, "root stays" )
	session.TEST_TRUE( root.get_parent() == manager, "root parent" )
	return session.runcode
