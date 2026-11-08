@tool
extends TestBase

## One key pushed through the whole responder list.
##
## The tree has 2048 responders. The push does not wait for a merge. No
## responder marks the event handled, so the viewport visits every responder.
## Building the tree queues a rebuild. The run waits for [signal _InputManager.rebuild_finished]
## before it frees the tree.


const LAYER_COUNT:int = 2048
const HARNESS_TIME:int = 7


class Row extends Responder:
	static var visits:int = 0


	static func make(index:int) -> Row:
		var node := Row.new()
		node.name = "R%d" % index
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		var map := CustomInputMap.new()
		var ev := InputEventKey.new()
		ev.keycode = KEY_A
		ev.pressed = true
		var events:Array[InputEvent] = []
		events.append(ev)
		map.add_action(StringName("li_%d" % index), 0.2, events)
		node.set("input_map", map)
		node.set("active", true)
		return node


	func _input(event:InputEvent) -> void:
		if event is InputEventKey:
			visits += 1


func _configure() -> void:
	# Wide budget so the capture window stays open for the whole run.
	harness_time_s = HARNESS_TIME


func _run_test() -> int:
	if _ensure_scene_tree() != OK or scene_tree == null:
		TEST_TRUE(false, "no SceneTree")
		return runcode

	var snapshot:CustomInputMap = CustomInputMap.from_engine()
	var host:SubViewport = _build_tree()
	if host == null:
		_restore(snapshot)
		TEST_TRUE(false, "no tree")
		return runcode

	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	Row.visits = 0
	_mark("case:walk")
	host.push_input(event)
	var seen:int = Row.visits
	var manager:Node = host.get_child(0)
	await manager.until_rebuilt()
	host.free()
	_restore(snapshot)
	if seen != LAYER_COUNT:
		TEST_TRUE(false, "push_input visited %d of %d" % [seen, LAYER_COUNT])
	return runcode


func _build_tree() -> SubViewport:
	var host := SubViewport.new()
	host.name = "TreeWalkHost"
	host.disable_3d = true
	host.size = Vector2i(2, 2)
	host.handle_input_locally = true
	host.render_target_update_mode = SubViewport.UPDATE_DISABLED
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	scene_tree.root.add_child(host)

	var manager := _InputManager.new()
	manager.name = "TreeInput"
	manager.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(manager)
	if manager.get("responder_root") == null:
		manager._enter_tree()

	var root:Responder = manager.get("responder_root") as Responder
	if root == null:
		host.free()
		return null
	root.set_block_signals(true)
	for i:int in LAYER_COUNT:
		var row:Row = Row.make(i)
		root.add_responder(row)
		if not row.is_processing_input():
			row._enter_tree()
	return host


func _restore(snapshot:CustomInputMap) -> void:
	var leftover:Node = scene_tree.root.get_node_or_null("TreeWalkHost")
	if is_instance_valid(leftover):
		leftover.free()
	if is_instance_valid(InputManager):
		var live:Node = InputManager
		var root:Responder = live.get("responder_root") as Responder
		if root != null:
			root.set("input_map", _InputManager.get_default_input_map())
	if not is_instance_valid(snapshot):
		return
	for action_name:StringName in InputMap.get_actions():
		if not snapshot.has_action(action_name):
			InputMap.erase_action(action_name)
	snapshot.apply_to_engine()


func _mark(text:String) -> void:
	if not Engine.has_singleton(&'Profiler'):
		return
	var profiler:Object = Engine.get_singleton(&'Profiler')
	if profiler != null:
		profiler.call(&'message', text)


func _cleanup() -> Error:
	print("Cleanup")
	return OK
