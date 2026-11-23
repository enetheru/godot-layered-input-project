@tool
extends "fixture.gd"

## A pass finishes on the callables it copied. The next pass sees the edit.

func _title() -> String:
	return "Mid pass"


func _description() -> String:
	return "A pass finishes on the callables it copied. The next pass sees the edit."


func _setup() -> int:
	if session.tree == null:
		session.TEST_TRUE( false, "no SceneTree" )
		return ERR_UNCONFIGURED

	_make_host()
	_tree()
	return OK


func _run_test() -> int:
	var viewport:SubViewport = host
	var built:Object = tree
	var root:Object = built.get( &"root" )
	var front:RefCounted = _record()
	var added_hits:Array[int] = [0]
	var original_hits:Array[int] = [0]
	var replacement_hits:Array[int] = [0]
	var original := func( _ev:InputEvent ) -> void:
		original_hits[0] += 1
	var replacement := func( _ev:InputEvent ) -> void:
		replacement_hits[0] += 1
	root.set( UNHANDLED_SLOT, original )
	front.set( UNHANDLED_SLOT, func( _ev:InputEvent ) -> void:
		var added:RefCounted = _record()
		added.set( UNHANDLED_SLOT, func( _event:InputEvent ) -> void:
			added_hits[0] += 1
		)
		built.call( &"add_responder", added )
		root.set( UNHANDLED_SLOT, replacement )
	)
	built.call( &"add_responder", front )

	built.call( &"dispatch_unhandled_input", viewport, _make_event() )
	session.TEST_EQ( 0, added_hits[0], "mid-pass added" )
	session.TEST_EQ( 1, original_hits[0], "mid-pass original" )
	session.TEST_EQ( 0, replacement_hits[0], "mid-pass replacement" )

	built.call( &"dispatch_unhandled_input", viewport, _make_event() )
	session.TEST_EQ( 1, added_hits[0], "second pass added" )
	session.TEST_EQ( 1, original_hits[0], "second pass original" )
	session.TEST_EQ( 1, replacement_hits[0], "second pass replacement" )
	return session.runcode
