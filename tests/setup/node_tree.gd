@tool
extends TR_Case

## One input manager. Setup puts it in the scene tree so it can create its responder root.

const NEEDS_TREE: bool = true

var _snapshot:CustomInputMap
var _manager:_InputManager


func _title() -> String:
	return "Node tree"


func _description() -> String:
	return "One input manager. Setup puts it in the scene tree so it can create its responder root."


func _setup() -> int:
	if session.tree == null:
		return ERR_UNCONFIGURED

	_snapshot = CustomInputMap.from_engine()
	_manager = _InputManager.new()
	_manager.name = &"SetupInput"
	session.tree.root.add_child( _manager )
	if _manager.get( &"responder_root" ) == null:
		_manager._enter_tree()
	if _manager.get( &"responder_root" ) == null:
		_manager.free()
		_manager = null
		_restore( _snapshot )
		return ERR_CANT_CREATE

	await _manager.until_rebuilt()
	return OK


func _run_test() -> int:
	return TR_CaseSession.TEST_OK


func _cleanup() -> int:
	if is_instance_valid( _manager ):
		_manager.free()
	_manager = null
	_restore( _snapshot )
	return OK


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
