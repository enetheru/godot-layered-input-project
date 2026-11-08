@tool
extends "fixture.gd"

## A pass finishes on the callables it copied. The next pass sees the edit.


func _run_test() -> int:
	if _ensure_scene_tree() != OK or scene_tree == null:
		TEST_TRUE( false, "no SceneTree" )
		return runcode

	var host:SubViewport = _make_host()
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
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
		tree.call( &"add_responder", added )
		root.set( UNHANDLED_SLOT, replacement )
	)
	tree.call( &"add_responder", front )

	tree.call( &"dispatch_unhandled_input", host, _make_event() )
	TEST_EQ( 0, added_hits[0], "mid-pass added" )
	TEST_EQ( 1, original_hits[0], "mid-pass original" )
	TEST_EQ( 0, replacement_hits[0], "mid-pass replacement" )

	tree.call( &"dispatch_unhandled_input", host, _make_event() )
	TEST_EQ( 1, added_hits[0], "second pass added" )
	TEST_EQ( 1, original_hits[0], "second pass original" )
	TEST_EQ( 1, replacement_hits[0], "second pass replacement" )
	host.free()
	return runcode
