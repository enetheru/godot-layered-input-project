@tool
extends "fixture.gd"

## One key visits play, title, UI, then root on each callback the node enables.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	var input_log:Array = []
	var shortcut_log:Array = []
	var key_log:Array = []
	var unhandled_log:Array = []
	var root:Responder = _slot_row( input_log, shortcut_log, key_log, unhandled_log )
	var ui:Responder = _slot_row( input_log, shortcut_log, key_log, unhandled_log )
	var title:Responder = _slot_row( input_log, shortcut_log, key_log, unhandled_log )
	var play:Responder = _slot_row( input_log, shortcut_log, key_log, unhandled_log )
	_attach( _engine_root(), root )
	_attach( root, ui )
	_attach( ui, title )
	_attach( root, play )

	_push()
	var want:Array = [play, title, ui, root]
	_expect_nodes( input_log, want, "nested input" )
	_expect_nodes( shortcut_log, want, "nested shortcut" )
	_expect_nodes( key_log, want, "nested key" )
	_expect_nodes( unhandled_log, want, "nested unhandled" )
	await _end()
	return runcode
