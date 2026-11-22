@tool
extends TR_Case

## One link tree. Setup creates the root record and lets the queued rebuild finish.

const NEEDS_TREE: bool = true

const LinkTreeScript = preload( "../../addons/enetheru.layered-input/link_tree/link_tree.gd" )

var _snapshot:CustomInputMap
var _tree:LinkTreeScript


func _title() -> String:
	return "Link tree"


func _description() -> String:
	return "One link tree. Setup creates the root record and lets the queued rebuild finish."


func _setup() -> int:
	_snapshot = CustomInputMap.from_engine()
	_tree = LinkTreeScript.new()
	await _tree.until_rebuilt()
	return OK


func _run_test() -> int:
	return TR_CaseSession.TEST_OK


func _cleanup() -> int:
	_tree = null
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
