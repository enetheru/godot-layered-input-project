@tool
extends "fixture.gd"

## The front callable marks the viewport handled, and the back callable stays quiet.


func _run_test() -> int:
	if _ensure_scene_tree() != OK or scene_tree == null:
		TEST_TRUE( false, "no SceneTree" )
		return runcode

	var host:SubViewport = _make_host()
	var tree:Object = _tree()
	var root:Object = tree.get( &"root" )
	var front:RefCounted = _record()
	var front_hits:Array[int] = [0]
	var back_hits:Array[int] = [0]
	front.set( UNHANDLED_SLOT, func( _ev:InputEvent ) -> void:
		front_hits[0] += 1
		host.set_input_as_handled()
	)
	root.set( UNHANDLED_SLOT, func( _ev:InputEvent ) -> void:
		back_hits[0] += 1
	)
	tree.call( &"add_responder", front )
	tree.call( &"dispatch_unhandled_input", host, _make_event() )

	TEST_EQ( 1, front_hits[0], "handled front" )
	TEST_EQ( 0, back_hits[0], "handled back" )
	host.free()
	return runcode
