@tool
extends "fixture.gd"

## Writing the current map back keeps the same table.


func _run_test() -> int:
	var vp:SubViewport = _begin()
	if vp == null:
		return runcode

	await manager.until_rebuilt()
	var table:CustomInputMap = manager.effective_map
	var root:Responder = _engine_root()
	var current:CustomInputMap = root.input_map
	root.input_map = current
	await manager.until_rebuilt()
	TEST_TRUE( is_same( manager.effective_map, table ), "same table" )
	await _end()
	return runcode
