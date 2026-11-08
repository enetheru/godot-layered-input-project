@tool
extends EditorScript

## Cost of the responder tree that is loaded now.
##
## BM_ResponderTreeRebuild times one `_rebuild_input_map` on a tree that is
## already built. That call collects from the root and merges every
## contributing map, so the tree needs no further edit to force the work.
##
## BM_ResponderTreeWalk times one key pushed at a SubViewport of active
## responders. None of them mark the event handled, so the viewport visits
## the whole list. InputManager does not walk for dispatch. The engine does.


const RegisterLib = preload("uid://ehhn1k7v0g6w")
const Types = preload("uid://bktkomkeaq1qm")
const ConsoleReporter = preload("uid://cp6jwltd8s2ur")

const REBUILD_SIZES:Array[int] = [8, 64, 256, 1024]
const WALK_SIZES:Array[int] = [128, 1024, 4096]


class Host:
	static var tree:SceneTree


func _run() -> void:
	var tree:SceneTree = _editor_tree()
	if tree == null:
		printerr("responder tree bench: no SceneTree")
		return
	Host.tree = tree

	var saved_dry:bool = BenchLib.FLAGS_benchmark_dry_run
	var saved_min_time:String = BenchLib.FLAGS_benchmark_min_time
	var saved_reps:int = BenchLib.FLAGS_benchmark_repetitions
	var snapshot:CustomInputMap = CustomInputMap.from_engine()

	BenchLib.FLAGS_benchmark_dry_run = false
	BenchLib.FLAGS_benchmark_min_time = "0.25s"
	BenchLib.FLAGS_benchmark_repetitions = 1
	_register()

	var reporter:ConsoleReporter = ConsoleReporter.new()
	var n:int = BenchLib.RunSpecifiedBenchmarks(reporter)
	print("%d benchmarks" % n)

	_sweep(tree)
	_repair_autoload_root()
	_restore_engine(snapshot)
	RegisterLib.ClearRegisteredBenchmarks()
	BenchLib.FLAGS_benchmark_dry_run = saved_dry
	BenchLib.FLAGS_benchmark_min_time = saved_min_time
	BenchLib.FLAGS_benchmark_repetitions = saved_reps
	Host.tree = null


func _register() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	var rebuild:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new(BM_ResponderTreeRebuild))
	rebuild.ArgName("n").Unit(Types.TimeUnit.kMillisecond).UseRealTime().MinTime(0.25)
	for n:int in REBUILD_SIZES:
		rebuild.Arg(n)

	var walk:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new(BM_ResponderTreeWalk))
	walk.ArgName("n").Unit(Types.TimeUnit.kMillisecond).UseRealTime().MinTime(0.25)
	for n:int in WALK_SIZES:
		walk.Arg(n)


func _editor_tree() -> SceneTree:
	var base:Control = EditorInterface.get_base_control()
	if base == null:
		return null
	return base.get_tree()


static func BM_ResponderTreeRebuild(state:State) -> void:
	var count:int = state.get_range(0)
	var fx:TreeFixture = TreeFixture.build(count, Host.tree, true)
	var built:CustomInputMap = TreeFixture.map_of(fx.manager) if fx != null else null
	if fx == null or built == null:
		state.SkipWithError("no tree")
		if fx != null:
			fx.free_tree()
		return
	var tail := StringName("li_%d" % (count - 1))
	if not built.has_action(tail):
		state.SkipWithError("rebuild did not keep %s" % tail)
		fx.free_tree()
		return
	for _i in state:
		fx.manager._rebuild_input_map()
	fx.free_tree()


static func BM_ResponderTreeWalk(state:State) -> void:
	var count:int = state.get_range(0)
	var fx:TreeFixture = TreeFixture.build(count, Host.tree, false)
	if fx == null or fx.host == null:
		state.SkipWithError("no tree")
		return

	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	LayerResponder.visits = 0
	fx.host.push_input(event)
	if LayerResponder.visits != count:
		state.SkipWithError("push_input visited %d of %d" % [LayerResponder.visits, count])
		fx.free_tree()
		return

	LayerResponder.visits = 0
	for _i in state:
		fx.host.push_input(event)
	fx.free_tree()


func _sweep(tree:SceneTree) -> void:
	var leftover:Node = tree.root.get_node_or_null("ResponderTreeBench")
	if is_instance_valid(leftover):
		leftover.free()


func _repair_autoload_root() -> void:
	if not is_instance_valid(InputManager):
		return
	var live:Node = InputManager
	var root:Responder = live.get("responder_root") as Responder
	if root == null:
		return
	root.set("input_map", _InputManager.get_default_input_map())


func _restore_engine(snapshot:CustomInputMap) -> void:
	if not is_instance_valid(snapshot):
		return
	for action_name:StringName in InputMap.get_actions():
		if not snapshot.has_action(action_name):
			InputMap.erase_action(action_name)
	snapshot.apply_to_engine()


class TreeFixture:
	var host:SubViewport
	var manager:_InputManager


	static func root_of(owner:_InputManager) -> Responder:
		if owner == null:
			return null
		return owner.get("responder_root") as Responder


	static func map_of(owner:_InputManager) -> CustomInputMap:
		if owner == null:
			return null
		return owner.get("effective_map") as CustomInputMap


	static func build(count:int, tree:SceneTree, rebuild:bool = true) -> TreeFixture:
		if tree == null:
			return null
		var fx := TreeFixture.new()
		var vp := SubViewport.new()
		vp.name = "ResponderTreeBench"
		vp.disable_3d = true
		vp.size = Vector2i(2, 2)
		vp.handle_input_locally = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(vp)

		var created := _InputManager.new()
		created.name = "BenchInputManager"
		created.process_mode = Node.PROCESS_MODE_ALWAYS
		vp.add_child(created)
		if TreeFixture.root_of(created) == null:
			created._enter_tree()

		var root:Responder = TreeFixture.root_of(created)
		if root == null:
			vp.free()
			return null
		root.set_block_signals(true)
		for i:int in count:
			var layer:LayerResponder = LayerResponder.make(i)
			root.add_responder(layer)
			if not layer.is_processing_input():
				layer._enter_tree()
		# The walk times push_input. Merge copies the whole action dictionary
		# once per layer, so a large walk must not pay that rebuild in setup.
		if rebuild:
			created._rebuild_input_map()

		fx.host = vp
		fx.manager = created
		return fx


	func free_tree() -> void:
		var root:Responder = TreeFixture.root_of(manager)
		if root != null:
			root.set_block_signals(true)
		if is_instance_valid(host):
			host.free()
		host = null
		manager = null


class LayerResponder extends Responder:
	static var visits:int = 0


	static func make(index:int) -> LayerResponder:
		var node := LayerResponder.new()
		node.name = "L%d" % index
		node.process_mode = Node.PROCESS_MODE_ALWAYS
		var map := CustomInputMap.new()
		var ev := InputEventKey.new()
		ev.keycode = KEY_A
		ev.pressed = true
		var events:Array[InputEvent] = []
		events.append(ev)
		map.add_action(StringName("li_%d" % index), 0.2, events)
		node.input_map = map
		node.active = true
		return node


	func _input(event:InputEvent) -> void:
		if event is InputEventKey:
			visits += 1
