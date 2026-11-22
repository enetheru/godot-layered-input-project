@tool
extends "fixture.gd"

## The front callable marks the viewport handled, and the back callable stays quiet.

func _title() -> String:
	return "Handled"


func _description() -> String:
	return "The front callable marks the viewport handled, and the back callable stays quiet."


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
	var front_hits:Array[int] = [0]
	var back_hits:Array[int] = [0]
	front.set( UNHANDLED_SLOT, func( _ev:InputEvent ) -> void:
		front_hits[0] += 1
		viewport.set_input_as_handled()
	)
	root.set( UNHANDLED_SLOT, func( _ev:InputEvent ) -> void:
		back_hits[0] += 1
	)
	built.call( &"add_responder", front )
	built.call( &"dispatch_unhandled_input", viewport, _make_event() )

	session.TEST_EQ( 1, front_hits[0], "handled front" )
	session.TEST_EQ( 0, back_hits[0], "handled back" )
	return session.runcode
