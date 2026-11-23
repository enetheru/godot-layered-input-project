@tool
extends TR_Case

## One responder tree. Setup creates the root record and lets the queued rebuild finish.

const NEEDS_TREE: bool = true

const ResponderTreeScript = preload( "../../addons/enetheru.layered-input/systems/responder_tree.gd" )

var _snapshot:CustomInputMap
var _tree:ResponderTreeScript


func _title() -> String:
	return "Responder tree"


func _description() -> String:
	return "One responder tree. Setup creates the root record and lets the queued rebuild finish."


func _setup() -> int:
	_snapshot = CustomInputMap.engine_baseline()
	_tree = ResponderTreeScript.new()
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
		var link:Object = live.get( &"tree" )
		if link != null:
			var root:Object = link.get( &"root" )
			if root != null:
				root.set( &"input_map", _InputManager.get_default_input_map() )
	if not is_instance_valid( snapshot ):
		return
	for action_name:StringName in InputMap.get_actions():
		if not snapshot.has_action( action_name ):
			InputMap.erase_action( action_name )
	snapshot.apply_to_engine()
