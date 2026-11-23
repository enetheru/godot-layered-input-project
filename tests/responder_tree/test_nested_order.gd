@tool
extends "fixture.gd"

## Front-to-back order for root, UI, title, and play on every walk.

var _root:Object
var _ui:RefCounted
var _title_row:RefCounted
var _play:RefCounted


func _title() -> String:
	return "Nested order"


func _description() -> String:
	return "Front-to-back order for root, UI, title, and play on every walk."


func _setup() -> int:
	_tree()
	_root = tree.get( &"root" )
	_ui = _record()
	_title_row = _record()
	_play = _record()
	for record:Object in [_root, _ui, _title_row, _play]:
		_fill_all( record )
	tree.call( &"add_responder", _ui )
	_ui.call( &"add_responder", _title_row )
	tree.call( &"add_responder", _play )
	return OK


func _run_test() -> int:
	var want:Array = [_play, _title_row, _ui, _root]
	_expect( tree, INPUT_WALK, want, "nested input" )
	_expect( tree, SHORTCUT_WALK, want, "nested shortcut" )
	_expect( tree, KEY_WALK, want, "nested key" )
	_expect( tree, UNHANDLED_WALK, want, "nested unhandled" )
	return session.runcode
