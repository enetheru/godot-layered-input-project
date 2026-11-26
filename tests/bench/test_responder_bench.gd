@tool
extends TR_Case

## Runs the responder-tree benchmark on its own.
##
## The body is [code]bench/responder_tree.gd[/code]. Rebuild sizes are 8, 64, 256, and 1024.
## Walk sizes are 128, 1024, and 4096. Pick this case alone for a template_debug run.


const NEEDS_TREE: bool = true
const BUDGET_S: float = 180.0

const BenchScript = preload( "res://bench/responder_tree.gd" )


func _title() -> String:
	return "Responder tree bench"


func _description() -> String:
	return "Runs bench/responder_tree.gd. Rebuild at 8, 64, 256, and 1024. Walk at 128, 1024, and 4096."


func _run_test() -> int:
	var bench: EditorScript = BenchScript.new()
	bench._run()
	if session != null and session.tree != null:
		await session.tree.process_frame
	return session.TEST_OK
