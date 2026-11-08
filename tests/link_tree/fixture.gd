@tool
@abstract
extends TestBase

## Records, walks, and the viewport host shared by the link-tree cases.


const LinkResponderScript = preload( "../../addons/enetheru.layered-input/link_tree/link_responder.gd" )
const LinkTreeScript = preload( "../../addons/enetheru.layered-input/link_tree/link_tree.gd" )

const INPUT_WALK:StringName = &"input_walk"
const SHORTCUT_WALK:StringName = &"shortcut_input_walk"
const KEY_WALK:StringName = &"unhandled_key_input_walk"
const UNHANDLED_WALK:StringName = &"unhandled_input_walk"

const INPUT_SLOT:StringName = &"_input"
const SHORTCUT_SLOT:StringName = &"_shortcut_input"
const KEY_SLOT:StringName = &"_unhandled_key_input"
const UNHANDLED_SLOT:StringName = &"_unhandled_input"


func _tree() -> Object:
	return LinkTreeScript.new()


func _record() -> RefCounted:
	return LinkResponderScript.new()


func _fill( record:Object, slot:StringName ) -> void:
	record.set( slot, Callable( self, &"_noop" ) )


func _fill_all( record:Object ) -> void:
	for slot:StringName in [INPUT_SLOT, SHORTCUT_SLOT, KEY_SLOT, UNHANDLED_SLOT]:
		_fill( record, slot )


func _noop( _ev:InputEvent ) -> void:
	pass


func _children( record:Object ) -> Array:
	return record.get( &"children" )


func _expect( tree:Object, prop:StringName, want:Array, desc:String ) -> void:
	var got:Array = tree.get( prop )
	_expect_array( got, want, desc )


func _expect_array( got:Array, want:Array, desc:String ) -> void:
	TEST_EQ( want.size(), got.size(), desc )
	if got.size() != want.size():
		return
	for i:int in want.size():
		TEST_TRUE( got[i] == want[i], "%s %d" % [desc, i] )


func _make_event() -> InputEvent:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	return event


func _make_host() -> SubViewport:
	var host := SubViewport.new()
	host.name = "LinkTreeHost"
	host.disable_3d = true
	host.size = Vector2i( 2, 2 )
	host.handle_input_locally = true
	host.render_target_update_mode = SubViewport.UPDATE_DISABLED
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	scene_tree.root.add_child( host )
	return host
