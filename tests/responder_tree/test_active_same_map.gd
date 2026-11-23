@tool
extends "fixture.gd"

## Setting an already active child active again keeps the same table.

var _child:RefCounted
var _table:CustomInputMap


func _title() -> String:
	return "Active same map"


func _description() -> String:
	return "Setting an already active child active again keeps the same table."


func _setup() -> int:
	_tree( _action_map( &"li_attack", KEY_A ) )
	_child = _record()
	_child.set( &"input_map", _action_map( &"li_menu", KEY_M ) )
	tree.add_responder( _child )
	await tree.until_rebuilt()
	_table = tree.effective_map
	return OK


func _run_test() -> int:
	_child.set( &"active", true )
	await tree.until_rebuilt()
	session.TEST_TRUE( is_same( tree.effective_map, _table ), "same table" )
	return session.runcode
