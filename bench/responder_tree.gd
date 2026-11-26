@tool
extends EditorScript

## Cost of one rebuild and one input walk.
##
## BM_ResponderTreeRebuild times one [code]_rebuild_input_map[/code] on a tree that is
## already built. Each record contributes one action. That call composes the
## table again. An unchanged row stays, and the engine write follows the rows
## that changed.
##
## BM_ResponderTreeWalk times one [code]dispatch_input[/code] of a key through N
## records. None of them mark the viewport handled, so the pass calls every
## captured callable. Those records carry no map, so the timed pass is the
## dispatch. The tree is built before the timed loop.
##
## Construction queues a deferred rebuild. [MapRestore] writes the engine
## map back on the next process frame, after that deferred call applies.


const RegisterLib = preload( "uid://ehhn1k7v0g6w" )
const Types = preload( "uid://bktkomkeaq1qm" )
const ConsoleReporter = preload( "uid://cp6jwltd8s2ur" )
const ResponderTree = preload( "res://addons/enetheru.layered-input/systems/responder_tree.gd" )
const Responder = preload( "res://addons/enetheru.layered-input/systems/responder.gd" )

const REBUILD_SIZES:Array[int] = [8, 64, 256, 1024]
const WALK_SIZES:Array[int] = [128, 1024, 4096]


class Host:
	static var tree:SceneTree


class LayerCall:
	static var visits:int = 0


	static func on_input( _ev:InputEvent ) -> void:
		visits += 1


func _run() -> void:
	var tree:SceneTree = _editor_tree()
	if tree == null:
		printerr( "responder tree bench: no SceneTree" )
		return
	Host.tree = tree

	var saved_dry:bool = BenchLib.FLAGS_benchmark_dry_run
	var saved_min_time:String = BenchLib.FLAGS_benchmark_min_time
	var saved_reps:int = BenchLib.FLAGS_benchmark_repetitions
	var snapshot:CustomInputMap = CustomInputMap.engine_baseline()

	BenchLib.FLAGS_benchmark_dry_run = false
	BenchLib.FLAGS_benchmark_min_time = "0.25s"
	BenchLib.FLAGS_benchmark_repetitions = 1
	_register()

	var reporter:ConsoleReporter = ConsoleReporter.new()
	var n:int = BenchLib.RunSpecifiedBenchmarks( reporter )
	print( "%d benchmarks" % n )

	_sweep( tree )
	var restore:MapRestore = MapRestore.new()
	restore.snapshot = snapshot
	restore.arm( tree )
	RegisterLib.ClearRegisteredBenchmarks()
	BenchLib.FLAGS_benchmark_dry_run = saved_dry
	BenchLib.FLAGS_benchmark_min_time = saved_min_time
	BenchLib.FLAGS_benchmark_repetitions = saved_reps
	Host.tree = null


func _register() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	var rebuild:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new( BM_ResponderTreeRebuild ) )
	rebuild = rebuild.ArgName( "n" ).Unit( Types.TimeUnit.kMillisecond ).UseRealTime().MinTime( 0.25 )
	for n:int in REBUILD_SIZES:
		rebuild = rebuild.Arg( n )

	var walk:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new( BM_ResponderTreeWalk ) )
	walk = walk.ArgName( "n" ).Unit( Types.TimeUnit.kMillisecond ).UseRealTime().MinTime( 0.25 )
	for n:int in WALK_SIZES:
		walk = walk.Arg( n )


func _editor_tree() -> SceneTree:
	if OS.has_feature( "editor" ):
		var base:Control = EditorInterface.get_base_control()
		if base != null:
			return base.get_tree()
	var loop:MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		var scene_tree:SceneTree = loop
		return scene_tree
	return null


static func BM_ResponderTreeRebuild( state:State ) -> void:
	var count:int = state.get_range( 0 )
	var fx:TreeFixture = TreeFixture.build( count, Host.tree, true )
	var built:CustomInputMap = TreeFixture.map_of( fx.responder_tree ) if fx != null else null
	if fx == null or built == null:
		state.SkipWithError( "no tree" )
		if fx != null:
			fx.free_tree()
		return
	var tail:StringName = StringName( "li_%d" % ( count - 1 ) )
	if not built.has_action( tail ):
		state.SkipWithError( "rebuild did not keep %s" % tail )
		fx.free_tree()
		return
	for _i in state:
		fx.responder_tree._rebuild_input_map()
	fx.free_tree()


static func BM_ResponderTreeWalk( state:State ) -> void:
	var count:int = state.get_range( 0 )
	var fx:TreeFixture = TreeFixture.build( count, Host.tree, false )
	if fx == null or fx.host == null or fx.responder_tree == null:
		state.SkipWithError( "no tree" )
		if fx != null:
			fx.free_tree()
		return

	var event:InputEventKey = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	LayerCall.visits = 0
	fx.responder_tree.dispatch_input( fx.host, event )
	if LayerCall.visits != count:
		state.SkipWithError( "dispatch visited %d of %d" % [LayerCall.visits, count] )
		fx.free_tree()
		return

	LayerCall.visits = 0
	for _i in state:
		fx.responder_tree.dispatch_input( fx.host, event )
	fx.free_tree()


func _sweep( tree:SceneTree ) -> void:
	var leftover:Node = tree.root.get_node_or_null( "ResponderBench" )
	if is_instance_valid( leftover ):
		leftover.free()


class MapRestore:
	var snapshot:CustomInputMap
	var _tree:SceneTree


	func arm( tree:SceneTree ) -> void:
		if tree == null:
			return
		_tree = tree
		var _bound:int = _tree.process_frame.connect( _apply )


	func _apply() -> void:
		if _tree != null and _tree.process_frame.is_connected( _apply ):
			_tree.process_frame.disconnect( _apply )
		_tree = null
		if is_instance_valid( InputManager ) and InputManager.tree != null:
			var root:Responder = InputManager.tree.root
			if root != null:
				root.input_map = _InputManager.get_default_input_map()
		if not is_instance_valid( snapshot ):
			return
		for action_name:StringName in InputMap.get_actions():
			if not snapshot.has_action( action_name ):
				InputMap.erase_action( action_name )
		snapshot.apply_to_engine()


class TreeFixture:
	var host:SubViewport
	var responder_tree:ResponderTree


	static func map_of( owner:ResponderTree ) -> CustomInputMap:
		if owner == null:
			return null
		return owner.effective_map


	static func _layer_map( index:int ) -> CustomInputMap:
		var map:CustomInputMap = CustomInputMap.new()
		var ev:InputEventKey = InputEventKey.new()
		ev.keycode = KEY_A
		ev.pressed = true
		var events:Array[InputEvent] = []
		events.append( ev )
		var _row:InputAction = map.add_action( StringName( "li_%d" % index ), 0.2, events )
		return map


	static func build( count:int, tree:SceneTree, rebuild:bool = false ) -> TreeFixture:
		if tree == null:
			return null
		var fx:TreeFixture = TreeFixture.new()
		var vp:SubViewport = SubViewport.new()
		vp.name = "ResponderBench"
		vp.disable_3d = true
		vp.size = Vector2i( 2, 2 )
		vp.handle_input_locally = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child( vp )

		var created:ResponderTree = ResponderTree.new()
		var root:Responder = created.root
		if root == null:
			vp.free()
			return null
		if rebuild:
			for i:int in count:
				var record:Responder = Responder.new()
				record.input_map = _layer_map( i )
				root.add_responder( record )
			created._rebuild_input_map()
		else:
			var input_call:Callable = Callable( LayerCall, &"on_input" )
			for _i:int in count:
				var record:Responder = Responder.new()
				record._input = input_call
				root.add_responder( record )

		fx.host = vp
		fx.responder_tree = created
		return fx


	func free_tree() -> void:
		if is_instance_valid( host ):
			host.free()
		host = null
		responder_tree = null
