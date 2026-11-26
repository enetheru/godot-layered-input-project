@tool
extends TR_Case

## Runs the responder rebuild and the responder walk on their own.
##
## Rebuild sizes are 8, 64, 256, and 1024. Walk sizes are 128, 1024, and 4096.
## Pick this case alone for a template_debug run.


const NEEDS_TREE: bool = true
const BUDGET_S: float = 180.0

const RebuildScript = preload( "res://bench/responder_rebuild.gd" )
const WalkScript = preload( "res://bench/responder_walk.gd" )


func _title() -> String:
	return "Responder tree benches"


func _description() -> String:
	return "Runs bench/responder_rebuild.gd then bench/responder_walk.gd."


func _run_test() -> int:
	var rebuild: EditorScript = RebuildScript.new()
	rebuild._run()
	var walk: EditorScript = WalkScript.new()
	walk._run()
	if session != null and session.tree != null:
		await session.tree.process_frame
	return session.TEST_OK
