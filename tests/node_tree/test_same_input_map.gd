@tool
extends "fixture.gd"

## Writing the current map back keeps the same table.

var _table:CustomInputMap
var _current:CustomInputMap


func _title() -> String:
	return "Same input map"


func _description() -> String:
	return "Writing the current map back keeps the same table."


func _setup() -> int:
	var err:int = super()
	if err != OK:
		return err

	await manager.until_rebuilt()
	_table = manager.effective_map
	_current = _engine_root().input_map
	return OK


func _run_test() -> int:
	_engine_root().input_map = _current
	await manager.until_rebuilt()
	session.TEST_TRUE( is_same( manager.effective_map, _table ), "same table" )
	return session.runcode
