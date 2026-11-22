@tool
@abstract
extends TR_Case

## Records, walks, and the viewport host shared by the link-tree cases.

const NEEDS_TREE: bool = true


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

var _snapshot:CustomInputMap
var _open:Array[LinkTreeScript] = []
var tree:LinkTreeScript
var host:SubViewport


func _tree( map:CustomInputMap = null ) -> void:
	if not is_instance_valid( _snapshot ):
		_snapshot = CustomInputMap.from_engine()
	tree = LinkTreeScript.new( map )
	_open.append( tree )


func _cleanup() -> int:
	if is_instance_valid( host ):
		host.free()
	host = null
	for open_tree:LinkTreeScript in _open:
		if is_instance_valid( open_tree ):
			await open_tree.until_rebuilt()
	_restore( _snapshot )
	_open.clear()
	tree = null
	return OK


func _key( code:Key ) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event


func _action_map( action:StringName, code:Key ) -> CustomInputMap:
	var map := CustomInputMap.new()
	var _row:InputAction = map.add_action( action, 0.2, [_key( code )] )
	return map


func _placeholder_map( action:StringName ) -> CustomInputMap:
	var map := CustomInputMap.new()
	var _row:InputAction = map.add_action( action )
	return map


func _keycode_of( map:CustomInputMap, action:StringName ) -> Key:
	if not is_instance_valid( map ):
		return KEY_NONE
	var events:Array[InputEvent] = map.get_action_events( action )
	if events.is_empty():
		return KEY_NONE
	var first:InputEvent = events[0]
	if first is InputEventKey:
		var key:InputEventKey = first
		return key.keycode
	return KEY_NONE


func _engine_keycode( action:StringName ) -> Key:
	var events:Array[InputEvent] = []
	events.assign( InputMap.action_get_events( action ) )
	if events.is_empty():
		return KEY_NONE
	var first:InputEvent = events[0]
	if first is InputEventKey:
		var key:InputEventKey = first
		return key.keycode
	return KEY_NONE


func _restore( snapshot:CustomInputMap ) -> void:
	if is_instance_valid( InputManager ):
		var live:Node = InputManager
		var root:Responder = live.get( &"responder_root" )
		if root != null:
			root.set( &"input_map", _InputManager.get_default_input_map() )
	if not is_instance_valid( snapshot ):
		return
	for action_name:StringName in InputMap.get_actions():
		if not snapshot.has_action( action_name ):
			InputMap.erase_action( action_name )
	snapshot.apply_to_engine()


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


func _expect( built:Object, prop:StringName, want:Array, desc:String ) -> void:
	var got:Array = built.get( prop )
	_expect_array( got, want, desc )


func _expect_array( got:Array, want:Array, desc:String ) -> void:
	session.TEST_EQ( want.size(), got.size(), desc )
	if got.size() != want.size():
		return
	for i:int in want.size():
		session.TEST_TRUE( got[i] == want[i], "%s %d" % [desc, i] )


func _make_event() -> InputEvent:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	return event


func _make_host() -> void:
	var made := SubViewport.new()
	made.name = "LinkTreeHost"
	made.disable_3d = true
	made.size = Vector2i( 2, 2 )
	made.handle_input_locally = true
	made.render_target_update_mode = SubViewport.UPDATE_DISABLED
	made.process_mode = Node.PROCESS_MODE_ALWAYS
	session.tree.root.add_child( made )
	host = made
