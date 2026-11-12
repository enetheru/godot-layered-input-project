@tool
@abstract
extends TestBase

## Host and rows shared by the node responder cases.


var manager:_InputManager
var host:SubViewport
var _snapshot:CustomInputMap


class SlotRow extends Responder:
	var input_log:Array
	var shortcut_log:Array
	var key_log:Array
	var unhandled_log:Array


	func _input( _ev:InputEvent ) -> void:
		input_log.append( self )


	func _shortcut_input( _ev:InputEvent ) -> void:
		shortcut_log.append( self )


	func _unhandled_key_input( _ev:InputEvent ) -> void:
		key_log.append( self )


	func _unhandled_input( _ev:InputEvent ) -> void:
		unhandled_log.append( self )


class UnhandledRow extends Responder:
	var order:Array


	func _unhandled_input( _ev:InputEvent ) -> void:
		order.append( self )


class InputOnly extends Responder:
	var hits:Array[int]


	func _input( _ev:InputEvent ) -> void:
		hits[0] += 1


class CountRow extends Responder:
	var hits:Array[int]


	func _unhandled_input( _ev:InputEvent ) -> void:
		hits[0] += 1


class HandleRow extends Responder:
	var hits:Array[int]
	var viewport:SubViewport


	func _unhandled_input( _ev:InputEvent ) -> void:
		hits[0] += 1
		viewport.set_input_as_handled()


class AddedRow extends Responder:
	var hits:Array[int]


	func _unhandled_input( _ev:InputEvent ) -> void:
		hits[0] += 1


class FrontRow extends Responder:
	var parent_row:Responder
	var hits:Array[int]


	func _unhandled_input( _ev:InputEvent ) -> void:
		var added := AddedRow.new()
		added.hits = hits
		added.process_mode = Node.PROCESS_MODE_ALWAYS
		parent_row.add_responder( added )
		if not added.is_processing_input():
			added._enter_tree()


func _begin() -> SubViewport:
	if _ensure_scene_tree() != OK or scene_tree == null:
		TEST_TRUE( false, "no SceneTree" )
		return null

	_snapshot = CustomInputMap.from_engine()
	var vp := SubViewport.new()
	vp.name = "NodeCaseHost"
	vp.disable_3d = true
	vp.size = Vector2i( 2, 2 )
	vp.handle_input_locally = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.process_mode = Node.PROCESS_MODE_ALWAYS
	scene_tree.root.add_child( vp )

	var created := _InputManager.new()
	created.name = "NodeCaseInput"
	created.process_mode = Node.PROCESS_MODE_ALWAYS
	vp.add_child( created )
	if created.get( &"responder_root" ) == null:
		created._enter_tree()
	var root:Responder = created.get( &"responder_root" )
	if root == null:
		vp.free()
		TEST_TRUE( false, "no root" )
		return null
	root.set_block_signals( true )
	manager = created
	host = vp
	return vp


func _end() -> void:
	if manager != null and is_instance_valid( manager ):
		await manager.until_rebuilt()
	if is_instance_valid( host ):
		host.free()
	host = null
	manager = null
	_restore( _snapshot )


func _engine_root() -> Responder:
	var root:Responder = manager.get( &"responder_root" )
	return root


func _attach( parent:Responder, node:Responder ) -> void:
	parent.add_responder( node )
	if not node.is_processing_input():
		node._enter_tree()


func _push() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	host.push_input( event )


func _unhandled( order:Array ) -> Responder:
	var node := UnhandledRow.new()
	node.order = order
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	return node


func _slot_row( input_log:Array, shortcut_log:Array, key_log:Array, unhandled_log:Array ) -> Responder:
	var node := SlotRow.new()
	node.input_log = input_log
	node.shortcut_log = shortcut_log
	node.key_log = key_log
	node.unhandled_log = unhandled_log
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	return node


func _input_only( hits:Array[int] ) -> Responder:
	var node := InputOnly.new()
	node.hits = hits
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	return node


func _count_row( hits:Array[int] ) -> Responder:
	var node := CountRow.new()
	node.hits = hits
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	return node


func _handle_row( hits:Array[int], viewport:SubViewport ) -> Responder:
	var node := HandleRow.new()
	node.hits = hits
	node.viewport = viewport
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	return node


func _front_row( parent_row:Responder, hits:Array[int] ) -> Responder:
	var node := FrontRow.new()
	node.parent_row = parent_row
	node.hits = hits
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	return node


func _map_row() -> Responder:
	var node := UnhandledRow.new()
	node.order = []
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	return node


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


func _expect_nodes( got:Array, want:Array, desc:String ) -> void:
	TEST_EQ( want.size(), got.size(), desc )
	if got.size() != want.size():
		return
	for i:int in want.size():
		TEST_TRUE( got[i] == want[i], "%s %d" % [desc, i] )


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
