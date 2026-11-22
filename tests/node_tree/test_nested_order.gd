@tool
extends "fixture.gd"

## One key visits play, title, UI, then root on each callback the node enables.

var _input_log:Array
var _shortcut_log:Array
var _key_log:Array
var _unhandled_log:Array
var _root:Responder
var _ui:Responder
var _title_row:Responder
var _play:Responder


func _title() -> String:
	return "Nested order"


func _description() -> String:
	return "One key visits play, title, UI, then root on each callback the node enables."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	_input_log = []
	_shortcut_log = []
	_key_log = []
	_unhandled_log = []
	_root = _slot_row( _input_log, _shortcut_log, _key_log, _unhandled_log )
	_ui = _slot_row( _input_log, _shortcut_log, _key_log, _unhandled_log )
	_title_row = _slot_row( _input_log, _shortcut_log, _key_log, _unhandled_log )
	_play = _slot_row( _input_log, _shortcut_log, _key_log, _unhandled_log )
	_attach( _engine_root(), _root )
	_attach( _root, _ui )
	_attach( _ui, _title_row )
	_attach( _root, _play )
	return OK


func _run_test() -> int:
	_push()
	var want:Array = [_play, _title_row, _ui, _root]
	_expect_nodes( _input_log, want, "nested input" )
	_expect_nodes( _shortcut_log, want, "nested shortcut" )
	_expect_nodes( _key_log, want, "nested key" )
	_expect_nodes( _unhandled_log, want, "nested unhandled" )
	return session.runcode
